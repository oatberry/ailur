(local [modules] [...])

(fn load-nickpass []
  (with-open [f (io.popen "pass irc/dtella/nickserv")]
    (f:read :l)))

{:db-path (.. modules.__directory "/../" "bot.db")

 :irc {:host "irc.dtella.net"
       :port 6697
       :nick "ailur"
       :nick-pass load-nickpass
       :username "oats"
       :real-name "beep boop 🐼"
       :channels ["#bots" "#dtella"]
       :ssl-params {:mode "client"
                    :protocol "tlsv1_2"
                    :verify "none"
                    :options ["all"]}}

 :weather {:geocode-key "AIzaSyDn5k2-cDzQmWa8n9zUaWQA4Fev43TrRj8"
           :darksky-key "a2ac5fa1393f11330c2301a9f7b9849c"}}
