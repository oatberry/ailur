(local [modules] [...]) ; bring the "global" modules table into scope
(local socket (require :socket))
(local ssl (require :ssl))
(local lume (require :lume))
(local {: types} (require :tableshape))

(var irc-config nil) ; irc configuration, verified with tableshape
(var connection nil) ; ssl-wrapped socket handle
(var nick-pass-supplied? false)

(var debug? true) ; whether to output to stderr
(fn set-debug [on?] (set debug? (= on? true)))

(var state nil) ; "running" or "restarting" or "stopping"
(fn signal-restart [] (set state :restarting))
(fn signal-die [] (set state :stopping))

(fn send [...]
  "Send a message to the server, and output to console"
  (local message (table.concat [...] ""))
  (when debug? (io.stderr:write ">> " message "\n"))
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

(fn quit [msg]
  (sendf "QUIT :%s" msg))

(fn privmsg [target ...]
  (local message (table.concat [...] ""))
  (each [_ line (ipairs (lume.split message "\n"))]
    (sendf "PRIVMSG %s :%s" target line)))

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
                     :nick-pass (+ types.string types.function types.nil)
                     :username types.string
                     :real-name types.string
                     :channels (types.array_of types.string)
                     :ssl-params ssl-param-shape}))

(fn load-config []
  "Load irc config from modules.config, and verify with tableshape"
  (local config (assert (?. modules :config :irc)
                        "config.irc not found"))
  (assert (irc-config-shape config))
  (set irc-config config)
  (set nick-pass-supplied? (not= irc-config.nick-pass nil)))

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

(fn nickserv-identify []
  (when irc-config.nick-pass
    (local pass (if (= (type irc-config.nick-pass) :function)
                    (irc-config.nick-pass)
                    irc-config.nick-pass))
    ;; Help prevent leaks
    (set irc-config.nick-pass nil)
    ;; Save `debug?` value and temporarily disable it
    (local debug-prev debug?)
    (set-debug false)
    (privmsgf :NickServ "IDENTIFY %s %s" irc-config.username pass)
    (set-debug debug-prev)))

(fn join-all []
  (lume.each irc-config.channels join))

;;; Triggers
(var triggers [])
(fn register-trigger [pattern callback]
  (table.insert triggers [pattern callback]))

(fn run-fn-safely [f args]
  (local (ok err) (pcall f args))
  (when (not ok)
    (io.stderr:write err "\n")
    (privmsg args.target "there was a runtime error, see stderr output for details")))

(fn run-triggers [{: message &as args}]
  (each [_ [pattern trigger] (ipairs triggers)]
    (when (message:match pattern)
      (run-fn-safely trigger args))))

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
  (local plugin (?. modules :plugins name :main))
  (when plugin
    (local plugin-args {:sender source :authed (= "dtl-5hv1j7.me" source.host)
                        :message command :target target})
    (run-fn-safely plugin plugin-args)))

(fn handle-message [tags source command]
  (match command
    [:001] (do (mode irc-config.nick "+B")
               (if nick-pass-supplied?
                   (nickserv-identify)
                   (join-all)))
    [:PING dest] (pong dest)

    [:NOTICE _ "Password accepted - you are now recognized."]
    (when (= source.nick "NickServ") (join-all))

    [:PRIVMSG target message]
    (do (run-triggers {: target : message :sender source})
        (-?>> (find-prefix target message)
              (react-to-privmsg source target message)))))

(fn loop []
  "Main react loop for received server messages"
  (math.randomseed (os.time))
  (match (connection:receive)
    line (do (when debug? (io.stdout:write (.. line "\n")))
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
  (= state :restarting))

;; Module export
{: nick
 : join
 : quit
 : privmsg
 : privmsgf
 : mode
 : register-trigger
 : set-debug
 : signal-restart
 : signal-die}
