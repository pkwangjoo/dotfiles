;;; init-prog.el --- Cross-language dev infrastructure -*- lexical-binding: t; -*-

;; Shared tooling every language plugs into: tree-sitter, the LSP client,
;; in-buffer completion, format-on-save, and Git.  Language-specific
;; wiring (which modes get eglot, which formatter each mode uses) lives
;; in the per-language modules and extends the packages set up here.

;; ============================================================
;; Tree-sitter grammars
;; ============================================================
;; One-time compile of grammars (needs cc + git on PATH).
;; markdown-inline is used by clojure-ts-mode for docstring rendering.
;; Its own recipe pins a tag whose parser needs tree-sitter ABI 15,
;; which this Emacs cannot load (max 14), so the auto-install fails and
;; retries on every Clojure buffer.  Pin an ABI-14 tag here instead;
;; the grammar being ready makes clojure-ts-mode skip its recipe.  The
;; clojure and regex grammars install fine via that auto-install.
(require 'treesit)                 ; treesit-ready-p is not autoloaded
(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
                         "v0.4.1" "tree-sitter-markdown-inline/src")))

(dolist (grammar '(typescript tsx markdown-inline))
  (unless (treesit-ready-p grammar t)
    (treesit-install-language-grammar grammar)))

;; ============================================================
;; Eglot (built-in LSP client)
;; ============================================================
;; Base config only.  Each language module adds its own major mode to
;; `eglot-ensure' via a mode hook; eglot already knows which server to
;; launch (typescript-language-server, clojure-lsp, ocaml-lsp, ...).
(use-package eglot
  :ensure nil                      ; built-in; do not fetch from MELPA
  :bind (:map eglot-mode-map
              ("M-T"   . eglot-find-typeDefinition)   ; M-Shift-t: go to type definition
              ("C-c ." . eglot-code-actions)))         ; Cmd-. equivalent: quick fix / add import

;; ============================================================
;; Corfu (in-buffer completion popup)
;; ============================================================
(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)                   ; pop up automatically as you type
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  :config
  ;; No in-buffer completion popup in org-mode buffers.
  (add-hook 'org-mode-hook (lambda () (corfu-mode -1)))
  ;; No completion popup in the scratch buffer (lisp-interaction-mode).
  (add-hook 'lisp-interaction-mode-hook (lambda () (corfu-mode -1))))

;; ============================================================
;; Apheleia (async format-on-save)
;; ============================================================
;; Global mode on; per-mode formatter mappings live in the language
;; modules (with-eval-after-load 'apheleia ...).
(use-package apheleia
  :init
  (apheleia-global-mode 1))

;; ============================================================
;; Magit (Git interface)
;; ============================================================
(use-package magit
  :bind (("C-x g"   . magit-status)
         ("C-c g b" . magit-blame))
  :custom
  ;; Don't run `save-some-buffers' on `magit-status' refresh.  The user
  ;; always saves intentional edits by hand, so their work is already on
  ;; disk by the time `C-x g' runs; this kills the "Save file?" nag and
  ;; guarantees magit can never write a stale buffer over Claude's disk
  ;; edits.
  (magit-save-repository-buffers nil)
  ;; Word-level highlighting inside changed lines.
  (magit-diff-refine-hunk 'all)
  :config
  ;; Zenburn's magit-diff faces are solid bright blocks with no
  ;; foreground contrast; replace them with darker green/red tints and
  ;; light text.  The -highlight variants style the section at point.
  (set-face-attribute 'magit-diff-added nil
                      :background "#2F4F2F" :foreground "#BFEBBF")
  (set-face-attribute 'magit-diff-added-highlight nil
                      :background "#3F6F3F" :foreground "#CFFFCF")
  (set-face-attribute 'magit-diff-removed nil
                      :background "#4F2F2F" :foreground "#ECB3B3")
  (set-face-attribute 'magit-diff-removed-highlight nil
                      :background "#703A3A" :foreground "#FFC3C3"))

(provide 'init-prog)
;;; init-prog.el ends here
