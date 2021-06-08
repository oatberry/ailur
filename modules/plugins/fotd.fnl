(local [{:__parent modules}] [...])
(local https (require :ssl.https))
(local json (require :json))

(local help "usage: fotd [zip]")

(local culvers-api "https://www.culvers.com/api/locate/address/json?address=%s")
(local default-zip "47906")

(fn get-culvers [zip]
  (local body (-> culvers-api
                  (string.format zip)
                  https.request
                  assert))
  (local j (json.decode body))
  (local restaurant (?. j :Collection :Locations 1))
  (values restaurant
          (when (= restaurant nil) "No restaurants found")))

(fn main [{: target : message}]
  (local location (if (= message "") default-zip message))
  (match (get-culvers location)
    {:Name name :FlavorDay fotd}
    (modules.irc.privmsgf target "%s FOTD: \x02%s" name fotd)
    (nil err)
    (modules.irc.privmsg target err)))

{: main
 : help}
