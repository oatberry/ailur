(local [modules] [...])
(local sql (require :lsqlite3))

(var db nil) ; database handle

(fn init []
  (local db-path (or (-> modules (. :config) (. :db-path)) "bot.db"))
  (local (db-handle code errmsg) (sql.open db-path))
  (assert db-handle (: "error opening database: %s: %s" :format code errmsg))
  (set db db-handle)

  (db:exec "PRAGMA foreign_keys = 1")

  (each [_ module (pairs modules)]
    (match module {: db-init} (db-init)))
  (each [_ plugin (pairs modules.plugins)]
    (match plugin {: db-init} (db-init))))

(fn cleanup []
  (each [_ module (pairs modules)]
    (match module {: db-cleanup} (db-cleanup)))
  (each [_ plugin (pairs modules.plugins)]
    (match plugin {: db-cleanup} (db-cleanup)))
  (db:close))

(fn make-tables-and-prepare-statements [tables statements]
  (each [table-name statement (pairs tables)]
    (when (not= (db:exec statement) sql.OK)
      (error (: "failed to create table '%s': %s" :format table-name (db:errmsg)))))

  (local prepared {})
  (each [prep-name statement (pairs statements)]
    (match (db:prepare statement)
      prepped (tset prepared prep-name prepped)
      (nil err) (error (: "error preparing statement '%s': %s" :format
                          prep-name (db:errmsg)))))
  prepared)

(fn run-prep [prep-stmt binds ?iter]
  (prep-stmt:reset)
  (prep-stmt:bind_names binds)
  (icollect [row (: prep-stmt (or ?iter :rows))] row))

{:get-handle #db
 : init
 : cleanup
 : make-tables-and-prepare-statements
 : run-prep}
