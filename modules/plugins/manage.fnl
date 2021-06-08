;;; Bot management commands

(local [{:__parent modules}] [...])
(local lume (require :lume))

(fn reload [{: authed} module-table module-name]
  (when authed
    (local (ok err) (pcall module-table.load module-table module-name))
    (if err
        (do (io.stderr:write err "\n")
            (: "error loading '%s', see stderr output" :format module-name))
        (: "successfully reloaded '%s'" :format module-name))))

(local commands {})

(fn commands.die [{: authed}]
  (when authed
    (modules.irc.quit "later, meatbags")
    (modules.irc.signal-die)))

(fn commands.restart [{: authed}]
  (when authed
    (modules.irc.quit "back in a sec, pinkskins")
    (modules.irc.signal-restart)))

(fn commands.update [{: authed}]
  (when authed
    (local (_ _ status) (os.execute "git pull"))
    (if (= status 0)
        "Ta-da!"
        (: "`git pull` exited with status %d" :format status))))

(fn commands.join [{: authed} [place]]
  (when (and place authed)
    (modules.irc.join place)))

(fn commands.ping [{: sender}]
  (string.format "%s, 🐼" sender.nick))

(fn commands.about []
  "I'm a silly lil lispy lua bot! https://github.com/oatberry/ailur")

(fn commands.debug [{: authed} [setting]]
  (match setting
    :on (modules.irc.set-debug true)
    :off (modules.irc.set-debug false)
    _ "'on' or 'off' pls"))

(fn commands.whoami [{: sender : authed}]
  (string.format "%s!%s@%s%s" sender.nick sender.username sender.host
                 (if authed ", authorized" "")))

(fn commands.reload-module [args [module-name]]
  (reload args modules module-name))

(fn commands.reload-plugin [args [plugin-name]]
  (reload args modules.plugins plugin-name))

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
