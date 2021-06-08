;;; Display bot uptime

(local [{:__parent modules}] [...])

(global start-time (or start-time (os.time)))

(local conversions [[:year   (* 60 60 24 7 52)]
                    [:week   (* 60 60 24 7)]
                    [:day    (* 60 60 24)]
                    [:hour   (* 60 60)]
                    [:minute (* 60)]
                    [:second 1]])

(fn main [{: target : message}]
  (var diff (os.difftime (os.time) start-time))
  (local uptime-parts (icollect [_ [unit seconds-per-unit] (ipairs conversions)]
                        (let [conversion (// diff seconds-per-unit)]
                          (when (not= conversion 0)
                            (local plural (if (= conversion 1) "" "s"))
                            (set diff (- diff (* conversion seconds-per-unit)))
                            (string.format "%d %s%s" conversion unit plural)))))

  (modules.irc.privmsg target "up " (table.concat uptime-parts ", ")))

{: main}
