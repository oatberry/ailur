;;; Get the github source url for a plugin.
(local [{:__parent modules &as plugins}] [...])

(local github-url "https://github.com/oatberry/ailur")
(local plugin-url (.. github-url "/blob/main/modules/plugins/%s.fnl"))

(local help "usage: source [plugin]")

(fn main [{: target : message}]
  (let [plugin-name (message:match "^(%S+)")
        plugin (. plugins plugin-name)]
    (if plugin-name
        (if plugin
            (modules.irc.privmsgf target (.. "source: " plugin-url) plugin-name)
            (modules.irc.privmsg target "No such plugin."))
        (modules.irc.privmsgf target "My source can be found at: %s" github-url))))

{: help
 : main}
