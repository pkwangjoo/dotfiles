;;; init-lisp.el --- Clojure & Scheme/Racket -*- lexical-binding: t; -*-

;; The two Lisp dialects in use.  They share the structural-editing
;; worldview (paredit) and each is small on its own.  Depends on the
;; shared packages in init-prog (eglot, apheleia, treesit grammars).

;; ============================================================
;; Clojure (clojure-ts-mode + CIDER)
;; ============================================================
;; clojure-ts-mode provides tree-sitter highlighting; it installs its
;; own grammars on first activation.  CIDER is the Clojure nREPL client
;; (the Clojure counterpart of Geiser below).  payment-api-cli-bb's
;; `bb nrepl` task starts the server and writes .nrepl-port; connect
;; with M-x cider-connect-clj.

(use-package clojure-ts-mode
  :hook (clojure-ts-mode . eglot-ensure))

;; CIDER pulls in classic clojure-mode, whose autoloads also claim
;; .clj files; remap the classic modes so the tree-sitter modes always
;; win regardless of package activation order.
(add-to-list 'major-mode-remap-alist '(clojure-mode . clojure-ts-mode))
(add-to-list 'major-mode-remap-alist '(clojurescript-mode . clojure-ts-clojurescript-mode))
(add-to-list 'major-mode-remap-alist '(clojurec-mode . clojure-ts-clojurec-mode))

;; Babashka scripts: neither package's autoloads claim .bb files.
(add-to-list 'auto-mode-alist '("\\.bb\\'" . clojure-ts-mode))

(use-package cider)

;; Paredit keeps parens balanced and adds structural editing (slurp,
;; barf, splice).  It owns delimiter insertion, so the global
;; electric-pair-mode is switched off locally wherever paredit runs.
;; Note: paredit's map shadows the global M-d / M-DEL word-delete
;; bindings with its paren-safe kill-word commands; intentional.
(use-package paredit
  :preface
  (defun my/paredit-setup ()
    "Enable paredit and hand pairing duties over from electric-pair."
    (electric-pair-local-mode -1)
    (enable-paredit-mode))
  :hook ((clojure-ts-mode . my/paredit-setup)
         (cider-repl-mode . my/paredit-setup)))

;; ============================================================
;; Scheme / Racket (Geiser)
;; ============================================================
;; Geiser is a generic Scheme REPL/IDE; geiser-racket is its Racket
;; backend.  It drives the `racket' binary (installed via Homebrew
;; cask); exec-path-from-shell makes that binary visible to GUI Emacs.
;; geiser-mode is a minor mode layered on scheme-mode: opening a .rkt
;; file activates it, and `C-c C-z' starts or visits the REPL.

(use-package geiser
  :custom
  (geiser-default-implementation 'racket)
  (geiser-active-implementations '(racket)))

(use-package geiser-racket
  :after geiser)

;; raco fmt reads a file argument and prints the result to stdout.
(with-eval-after-load 'apheleia
  ;; (setf (alist-get 'raco-fmt apheleia-formatters) '("raco" "fmt" file))
  (setf (alist-get 'scheme-mode apheleia-mode-alist) 'raco-fmt))

(provide 'init-lisp)
;;; init-lisp.el ends here
