(local sleep (match (require :posix)
               {:unistd {: sleep}} sleep
               _ #(os.execute (.. "sleep " (tonumber $))))) ; lol lua

{: sleep}
