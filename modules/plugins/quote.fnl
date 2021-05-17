(local [{:__parent modules}] [...])
(local database modules.database)
(local lume (require :lume))
(local sql (require :lsqlite3))

(var prepared {})

(fn db-init []
  (set prepared
       (database.make-tables-and-prepare-statements
        ;; table schemas
        {:quotes_whitelist
         "CREATE TABLE IF NOT EXISTS quotes_whitelist (
             nick TEXT NOT NULL )"
         :quotes
         "CREATE TABLE IF NOT EXISTS quotes (
             id INTEGER PRIMARY KEY NOT NULL,
             nick TEXT NOT NULL,
             message TEXT NOT NULL )"}
        ;; prepared statements
        {:whitelist-insert
         "INSERT OR IGNORE INTO quotes_whitelist (nick) VALUES (:nick)"
         :whitelist-delete
         "DELETE FROM quotes_whitelist WHERE nick = :nick"
         :whitelist-status
         "SELECT COUNT(*) FROM quotes_whitelist WHERE nick = :nick"
         :quote-insert
         "INSERT OR IGNORE INTO quotes (nick, message) VALUES (:nick, :message)"
         :quote-select-nick
         "SELECT id, nick, message FROM quotes WHERE nick LIKE :nick ORDER BY id DESC"
         :quote-select-id
         "SELECT id, nick, message FROM quotes WHERE id = :id LIMIT 1"
         :quote-select-rand
         "SELECT id, nick, message FROM quotes WHERE nick LIKE :nick ORDER BY RANDOM()"
         :quote-search
         "SELECT id, nick, message FROM quotes WHERE message LIKE :search ORDER BY id ASC"
         :quote-del
         "DELETE FROM quotes WHERE id = :id"})))

(fn db-cleanup []
  (each [_ statement (pairs prepared)]
    (statement:finalize)))

(local commands {})

(fn commands.status [{: sender : target} params]
  (local nick (match params [nick] nick sender.nick))
  (local status (match (database.run-prep prepared.whitelist-status {: nick})
                  [[count]] (> count 0)))
  (: "%s is opted-%s for quotegrabs."
     :format nick (if status "in" "out")))

(fn main [args]
  (local command (lume.split args.message))
  ;; (match (. commands )
  ;;   [:whitelist & rest] (modules.irc.privmsg target (whitelist subcmd rest))
  ;;   [])
  )

{: db-init
 : db-cleanup
 : main}
