;;; Get the help messages
(local [{:__parent modules &as plugins}] [...])

(local help "usage: help <plugin>\nsee also: manage list-plugins")

(fn main [{: target : message}]
  (modules.irc.privmsgf
   target
   (if (= message "")
       help
       (or (?. plugins message :help)
           "No help available for that topic."))))

{: help
 : main}
