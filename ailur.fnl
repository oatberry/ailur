#!/usr/bin/env fennel

(local fennel (require :fennel))
(local lfs (require :lfs))
(local lume (require :lume))

(fn warn [...]
  (io.stderr:write (string.format "WARN: %s\n" (table.concat [...] ""))))

(fn subdirectory? [path]
  (= (lfs.attributes path :mode) :directory))

(fn load-module [modules module-name]
  (local module-path (string.format "%s/%s.fnl" modules.__directory module-name))
  (local module (fennel.dofile module-path nil modules))
  (tset package.loaded module-name module)
  (tset modules module-name module))

(fn load-directory-modules [dir-path ?parent-modules]
  (var modules {:load load-module
                :__directory dir-path
                :__parent ?parent-modules})
  (each [entry (lfs.dir dir-path)]
    (local path (.. dir-path "/" entry))
    (if (and (not= entry ".") (not= entry "..") (subdirectory? path))
        (tset modules entry (load-directory-modules path modules))
        (match (entry:match "(.+)%.fnl$")
          module-name (modules:load module-name))))
  modules)

(fn run []
  (local modules (load-directory-modules (.. (lfs.currentdir) "/modules")))
  (print (fennel.view modules))
  (local main (assert (and (= (type modules.main) :function) modules.main)
                      "No main function found"))
  (if (main)
      (run)
      (warn "Shutting down.")))

(run)
