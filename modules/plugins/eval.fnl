(local [{:__parent modules}] [...])
(local fennel (require :fennel))

(local help "eval <fennel-expr>")

(fn deep-copy [orig]
  (if (= (type orig) :function)
      (let [copy {}]
        (each [k v (pairs orig)]
          (tset copy (deep-copy k) (deep-copy v)))
        (setmetatable copy (deep-copy (getmetatable orig))))
      orig))

(fn main [{: authed : target : sender : message}]
  (local safe-env {:modules (if authed modules nil)
                   :math (deep-copy math)
                   :os {:clock os.clock :date os.date
                        :difftime os.difftime :time os.time}
                   :string (deep-copy string)
                   :table (deep-copy table)
                   : tonumber
                   : tostring
                   : type})
  (local results [(fennel.eval message {:env safe-env})])
  (local result-strs (icollect [_ v (ipairs results)]
                       (fennel.view v {:one-line? true :escape-newlines? true
                                       :allowedGlobals false})))
  (modules.irc.privmsg target (table.concat result-strs "   ")))

{: help
 : main}
