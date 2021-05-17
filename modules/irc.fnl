(local [modules] [...]) ; bring the "global" modules table into scope
(local socket (require :socket))
(local ssl (require :ssl))
(local lume (require :lume))
(local {: types} (require :tableshape))

(var irc-config nil) ; irc configuration, verified with tableshape
(var connection nil) ; ssl-wrapped socket handle
(var state nil)      ; "running" or "restarting" or "stopping"

(fn signal-restart [] (set state :restarting))
(fn signal-die [] (set state :stopping))

(fn send [...]
  "Send a message to the server, and output to console"
  (local message (table.concat [...] ""))
  (io.stderr:write ">> " message "\n")
  (assert (connection:send (.. message "\r\n"))))

(fn sendf [...] (send (string.format ...)))

;;; IRC message functions

(fn mode [target mode]
  (sendf "MODE %s %s" target mode))

(fn pong [dest]
  (sendf "PONG %s" dest))

(fn nick [new-nick]
  (sendf "NICK %s" new-nick))

(fn join [chan]
  (sendf "JOIN %s" chan))

(fn privmsg [target ...]
  (sendf "PRIVMSG %s :%s" target (table.concat [...] "")))

(fn privmsgf [target ...]
  (privmsg target (string.format ...)))

;;; Config verification

(local ssl-param-shape
       (types.shape {:mode types.string
                     :protocol types.string
                     :verify types.string
                     :options (types.array_of types.string)}))

(local irc-config-shape
       (types.shape {:host types.string
                     :port (+ types.number (/ types.string tonumber))
                     :nick types.string
                     :username types.string
                     :real-name types.string
                     :channels (types.array_of types.string)
                     :ssl-params ssl-param-shape}))

(fn load-config []
  "Load irc config from modules.config, and verify with tableshape"
  (local config (assert (?. modules :config :irc)
                        "config.irc not found"))
  (assert (irc-config-shape config))
  (set irc-config config))

;;; IRC init functions

(fn connect []
  "Set up tcp connection with ssl"
  (local bare-sock (socket.connect irc-config.host irc-config.port))
  (local secure-sock (assert (ssl.wrap bare-sock irc-config.ssl-params)
                             "Failed to initialize connection."))
  (secure-sock:dohandshake)
  (set connection secure-sock))

(fn register []
  "First messages to the server, nickname and username"
  (nick irc-config.nick)
  (sendf "USER %s 0 * :%s" irc-config.username irc-config.real-name))

(fn join-all []
  (lume.each irc-config.channels join))

;;; Message handling

(fn find-prefix [target message]
  "Determine whether a message is directed at the bot, and which prefix
needs to be stripped from the message"
  (local char-pattern "^,")
  (local highlight-pattern (.. "^" irc-config.nick "[^%w]"))
  (if (target:match "^[^#]") "^"
      (message:match char-pattern) char-pattern
      (message:match highlight-pattern) highlight-pattern))

(fn react-to-privmsg [source target message prefix]
  "Respond to a PRIVMSG appropriately"
  (local (name command) (message:match (.. prefix "%s*(%S*)%s*(.*)")))
  (local plugin (. modules.plugins name))
  (when plugin
    (local plugin-args {:sender source :authed (= "oats" source.nick)
                        :message command :target target})
    (local (success result) (pcall plugin.main plugin-args))
    (when (not success)
      (privmsg target result))))

(fn handle-message [tags source command]
  (match command
    [:001] (do (mode irc-config.nick "+B")
               (join-all))
    [:PING dest] (pong dest)
    [:PRIVMSG target message] (-?>> (find-prefix target message)
                                    (react-to-privmsg source target message))))

(fn loop []
  "Main react loop for received server messages"
  (math.randomseed (os.time))
  (match (connection:receive)
    line (do (io.stdout:write (.. line "\n"))
             (handle-message (modules.irc-message.parse line))
             (when (= state :running)
               (loop)))
    (nil err) (do (io.stderr:write "Error writing to socket: " err)
                  (io.stderr:write "Connection closed unexpectedly, reconnecting in 5 seconds...")
                  (modules.utils.sleep 5)
                  (signal-restart))))

(fn modules.main []
  "Main entry point, called from ../ailur"
  (set state :running)
  ;; (modules.database.init)
  (load-config)
  (connect)
  (register)
  (loop)
  (connection:close)
  ;; (modules.database.cleanup)
  (= state :restarting) ; `true` indicates to ../ailur to restart
  )

;; Module export
{: nick
 : join
 : privmsg
 : privmsgf
 : mode
 : signal-restart
 : signal-die}
