;;; Get weather from Dark Sky, using Google geocoding

(local [{:__parent modules}] [...])
(local url (require :socket.url))
(local https (require :ssl.https))
(local json (require :json))

(local help "usage: weather [location]")

(local icons {:clear-day "☀ "
              :clear-night "🌙"
              :rain "🌧 "
              :snow "❄ "
              :sleet "💧"
              :wind "💨"
              :fog "🌫"
              :cloudy "☁ "
              :partly-cloudy-day "⛅"
              :partly-cloudy-night "☁ "})

(local geocode-url "https://maps.google.com/maps/api/geocode/json?address=%s&key=%s")
(local weather-url "https://api.darksky.net/forecast/%s/%s,%s?units=si")

(fn geocode [key location]
  (local (body code) (https.request (geocode-url:format
                                     (url.escape location)
                                     key)))
  (assert body
          (.. "error fetching location coords: " code))
  (local data (json.decode body))
  (assert (= :OK data.status)
          (.. "error fetching location coords: " data.status))
  (values (?. data :results 1 :geometry :location)
          (?. data :results 1 :formatted_address)))

(fn darksky [key {: lat : lng}]
  (local (body code) (https.request (weather-url:format key lat lng)))
  (assert body
          (.. "error fetching weather: " code))
  (local data (json.decode body))
  (assert (and data data.currently)
          "error decoding json"))

(fn weather [location]
  (local geocode-key (?. modules :config :weather :geocode-key))
  (local darksky-key (?. modules :config :weather :darksky-key))
  (assert (and geocode-key darksky-key)
          "please set 'config.weather.geocode-key' and 'config.weather.darksky-key'")

  (local (coords address) (geocode geocode-key location))
  (local currently (darksky darksky-key coords))
  (local celsius currently.temperature)
  (local fahrenheit (-> celsius (* 9) (/ 5) (+ 32)))
  (local icon (. icons currently.icon))
  (local result (: "\x0315\x1d%s:\x0f %s %s %.1f°C (%.1f°F)" :format
                   address icon currently.summary celsius fahrenheit))
  (modules.cloud.upgrade result))

(fn main [{: target : message}]
  (local result (if (= message "")
                    help
                    (weather message)))
  (modules.irc.privmsg target result))

{: help
 : main
 : weather}
