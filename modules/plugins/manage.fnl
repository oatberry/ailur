(local [{:__parent modules}] [...])
(local lume (require :lume))

(local commands {})

(fn commands.die [{: authed}] (when authed (modules.irc.signal-die)))
(fn commands.restart [{: authed}] (when authed (modules.irc.signal-restart)))
(fn commands.ping [{: sender}] (string.format "%s, 🐼" sender.nick))

(fn commands.whoami [{: sender : authed}]
  (string.format "%s!%s@%s%s" sender.nick sender.username sender.host
                 (if authed ", authorized" "")))

(fn commands.reload-module [{: authed} [module-name]]
  (when authed
    (local (ok err) (pcall #(modules:load module-name)))
    (or err "Ta-da!")))

(fn commands.reload-plugin [{: authed} [plugin-name]]
  (when authed
    (local (ok err) (pcall #(modules.plugins:load plugin-name)))
    (or err "Ta-da!")))

(fn commands.list-plugins []
  (local plugins (icollect [k _ (pairs modules.plugins)] k))
  (table.concat plugins ", "))

(fn commands.version []
  (with-open [out (io.popen (.. "printf \"0.r%s.%s\" "
                                "\"$(git rev-list --count HEAD)\" "
                                "\"$(git log -1 --pretty=format:%h)\""))]
    (out:read)))

(local help (string.format
             "usage: manage <%s>"
             (table.concat (icollect [k _ (pairs commands)] k) "|")))

(fn main [{: sender : target : authed : message &as args}]
  (local [action & rest] (lume.split message))
  (local command (. commands action))
  (modules.irc.privmsg target (if command
                                  (command args rest)
                                  help)))

{: help
 : main}
