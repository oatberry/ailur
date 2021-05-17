(local [{:__parent modules}] [...])

(global start-time (or start-time (os.time)))

(local conversions [[:year   (* 60 60 24 7 52)]
                    [:week   (* 60 60 24 7)]
                    [:day    (* 60 60 24)]
                    [:hour   (* 60 60)]
                    [:minute (* 60)]
                    [:second 1]])

(fn main [{: target : message}]
  (var uptime {})
  (var diff (os.difftime (os.time) start-time))

  (each [_ [unit seconds-per-unit] (ipairs conversions)]
    (local conversion (// diff seconds-per-unit))
    (local unit-suffix (if (= conversion 1) "" "s"))
    (when (not= conversion 0)
      (table.insert uptime (string.format "%d %s%s" conversion unit unit-suffix))
      (set diff (- diff (* conversion seconds-per-unit)))))

  (modules.irc.privmsg target "up " (table.concat uptime ", ")))

{: main}
