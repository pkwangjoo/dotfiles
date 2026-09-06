;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; Config is split into modules under lisp/.  Each module ends with
;; `(provide 'init-<name>)'; this file just loads them in order.
;;
;; Load order matters in two places:
;;   - init-bootstrap must be first: it sets up use-package (which every
;;     other module needs) and puts the shell PATH on `exec-path'.
;;   - init-editor loads the theme before init-completion / init-prog
;;     apply their own `set-face-attribute' tweaks on top of it.
;;   - init-prog compiles tree-sitter grammars at startup, which needs
;;     cc + git from the PATH that init-bootstrap set up.

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'init-bootstrap)    ; package.el, use-package, custom-file, shell PATH
(require 'init-editor)       ; editor defaults, UI, theme, editing commands
(require 'init-completion)   ; ivy/counsel, projectile, eshell, tab-bar workspaces
(require 'init-markdown)     ; markdown document reading view
(require 'init-prog)         ; tree-sitter, eglot, corfu, apheleia, magit
(require 'init-typescript)   ; TS/TSX: LSP, ESLint, Prettier, Jest, folding
(require 'init-lisp)         ; Clojure (CIDER) + Scheme/Racket (Geiser) + paredit
(require 'init-ocaml)        ; OCaml: tuareg, dune, ocamlformat
(require 'init-commands)     ; reload-init, claude paths, discard-unsaved, pinned files

;;; init.el ends here
