;;; Commands to test miscellaneous things

(local [{:__parent modules}] [...])
(local lume (require :lume))

(local commands {})

(fn commands.echo [{: sender} command]
  (: "%s, %s" :format sender.nick (table.concat command " ")))

(fn commands.try-crash []
  (error "TEST CRASH, PLEASE IGNORE"))

(local help (: "usage: test <%s>" :format
               (table.concat (icollect [k _ (pairs commands)] k) "|")))

(fn main [{: target : message &as args}]
  (local [action & rest] (lume.split message))
  (local command (. commands action))
  (modules.irc.privmsg target (if command
                                  (command args rest)
                                  help)))

{: main
 : help}
