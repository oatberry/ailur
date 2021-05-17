;;; Server message parsing

(fn parse-source [source-str]
  "Parse message source"
  (local (nick username host) (string.match source-str "(%S+)!(%S+)@(%S+)"))
  (if (and nick username host)
      {: nick : username : host}
      source-str))

(fn parse-params [rest]
  "Parse command parameters"
  (local (tail-start _ last) (string.find rest " :(.*)$"))
  (local init (string.sub rest 1 tail-start))
  (local params (icollect [param (string.gmatch init "%S+")] param))
  (table.insert params last)
  params)

(fn parse [server-msg]
  "Parse a message from an IRC server"
  (local (_ tags-end tags) (string.find server-msg "^@(%S*) +"))
  (local (_ source-end source) (string.find server-msg "^ *:(%S-) +" tags-end))
  (local (command-name rest) (string.match server-msg "^ *(%S+) +(.*)" source-end))
  (local source (and source (parse-source source)))
  (local params (and rest (parse-params rest)))
  (values tags source [command-name (table.unpack params)]))

{: parse}
