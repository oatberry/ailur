(local [modules] [...])

(fn upgrade [cloud]
  (pick-values 1
    (-> cloud
        (string.gsub "CLOUD" "BUTT")
        (string.gsub "c[lL][oO][uU][dD]" "butt")
        (string.gsub "C[lL][oO][uU][dD]" "Butt"))))

;; (fn init []
;;   (local irc modules.irc)

;;   (irc.register-trigger
;;    "[Cc][Ll][Oo][Uu][Dd]"
;;    (fn [{: sender : target : message}]
;;      (irc.privmsg target (upgrade message)))))

{: upgrade
 ;; : init
 }
