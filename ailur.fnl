#!/usr/bin/env fennel

(local fennel (require :fennel))
(local lfs (require :lfs))
(local lume (require :lume))

(fn warn [...]
  (io.stderr:write "WARN: " (table.concat [...] "") "\n"))

(fn subdirectory? [path]
  (= (lfs.attributes path :mode) :directory))

(fn load-module [modules module-name]
  (local module-path (string.format "%s/%s.fnl" modules.__directory module-name))
  (local module (fennel.dofile module-path nil modules))
  (tset package.loaded module-name module)
  (tset modules module-name module))

(fn load-directory-modules [dir-path ?parent-modules]
  (var modules (setmetatable {} {:__index {:load load-module
                                           :__directory dir-path
                                           :__parent ?parent-modules}}))
  (each [entry (lfs.dir dir-path)]
    (local path (.. dir-path "/" entry))
    (if (and (not= entry ".") (not= entry "..") (subdirectory? path))
        (tset modules entry (load-directory-modules path modules))
        (match (entry:match "(.+)%.fnl$")
          module-name (modules:load module-name))))
  modules)

(fn init-modules [modules]
  (each [_ mod (pairs modules)]
    (match mod
      (where {: init} (= (type init) :function)) (init)
      {: __directory} (init-modules mod))))

(fn run []
  (local modules (load-directory-modules (.. (lfs.currentdir) "/modules")))

  ;; Some modules may depend on other modules to init things, but module load
  ;; order is not defined. So we run each (module.init) after all are loaded.
  (init-modules modules)

  (local main (assert (and (= (type modules.main) :function) modules.main)
                      "No main function found"))
  (if (main)
      (run)
      (warn "Shutting down.")))

(run)
