(local [{:__parent modules}] [...])
(local lume (require :lume))

(local help "usage: manage <die|restart|ping|whoami|reload <\x02plugin\x0f|\x02module\x0f>>")

(fn reload-module [module-name]
  (local (ok err) (pcall modules.load modules module-name))
  (or err "Ta-da!"))

(fn reload-plugin [plugin-name]
  (local (ok err) (pcall modules.plugins.load modules.plugins plugin-name))
  (or err "Ta-da!"))

(fn main [{: sender : target : authed : message}]
  (local irc modules.irc)

  (match (lume.split message)
    [:die] (when authed (irc.signal-die))
    [:restart] (when authed (irc.signal-restart))
    [:ping] (irc.privmsgf target "%s, 🐼" sender.nick)

    [:whoami]
    (irc.privmsgf target "%s!%s@%s%s"
                  sender.nick sender.username sender.host
                  (if authed ", authorized" ""))

    [:reload :module what]
    (when authed (irc.privmsg target (reload-module what)))

    [:reload :plugin what]
    (when authed (irc.privmsg target (reload-plugin what)))

    (irc.privmsg target help)))

{: help
 : main}
