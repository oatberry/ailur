(local [{:__parent modules &as plugins}] [...])

(local help "usage: help <plugin>")

(fn main [{: target : message}]
  (local help-msg (?. plugins message :help))
  (modules.irc.privmsgf
   target
   (or help-msg "No help available for that topic.")))

{: help
 : main}
