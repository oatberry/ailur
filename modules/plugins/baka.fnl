(local [{:__parent modules}] [...])

(var bakas 0)
(fn upbaka []
  (set bakas (+ bakas 1)))

(fn main [{: target}]
  (modules.irc.privmsgf target
                        "I see %d baka%s"
                        bakas
                        (if (= bakas 1) "" "s")))

(fn init []
  (modules.irc.register-trigger "^%s*baka$" upbaka))

{: main
 : init}
