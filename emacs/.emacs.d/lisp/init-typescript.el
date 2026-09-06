;;; init-typescript.el --- TypeScript / TSX editing -*- lexical-binding: t; -*-

;; Everything about editing TS/TSX: tree-sitter major modes, LSP, ESLint,
;; Prettier, Jest, and code folding.  Depends on the shared packages set
;; up in init-prog (eglot, apheleia, treesit grammars).

;; Use the tree-sitter modes for .ts / .tsx files.
(add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

;; --- Eglot ------------------------------------------------
;; Eglot already knows to launch typescript-language-server for these modes.
(add-hook 'typescript-ts-mode-hook #'eglot-ensure)
(add-hook 'tsx-ts-mode-hook        #'eglot-ensure)

;; --- ESLint via Flymake (project-local eslint) -------------
(use-package flymake-eslint
  :preface
  (defun my/use-local-eslint ()
    "Point flymake-eslint at the project's node_modules/.bin/eslint when present."
    (when-let* ((root   (locate-dominating-file default-directory "node_modules"))
                (eslint (expand-file-name "node_modules/.bin/eslint" root)))
      (when (file-executable-p eslint)
        (setq-local flymake-eslint-executable-name eslint))))
  (defun my/enable-eslint-with-eglot ()
    "Run ESLint as a second Flymake backend beside Eglot."
    (when (derived-mode-p 'typescript-ts-mode 'tsx-ts-mode)
      (my/use-local-eslint)
      (flymake-eslint-enable)))
  :hook (eglot-managed-mode . my/enable-eslint-with-eglot))

;; --- Prettier via apheleia (async format-on-save) ----------
(with-eval-after-load 'apheleia
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'tsx-ts-mode        apheleia-mode-alist) 'prettier))

;; --- Jest (run tests from the buffer) ----------------------
;; Defaults already give us `npx jest` and the `C-c C-t` keymap,
;; so this just installs the package and turns it on in TS buffers.
(use-package jest-test-mode
  :hook ((typescript-ts-mode . jest-test-mode)
         (tsx-ts-mode        . jest-test-mode))
  :custom
  ;; jest-test-mode runs tests through `compile', which by default runs
  ;; `save-some-buffers' over every modified buffer in the session --
  ;; hence the save prompts for unrelated directories.  Same policy as
  ;; `magit-save-repository-buffers' above: edits are saved by hand, so
  ;; never prompt and never write buffers from here.  (This variable is
  ;; global, so it also silences any other `compile' invocation.)
  (compilation-save-buffers-predicate #'ignore))

;; --- treesit-fold (tree-sitter code folding) ---------------
;; Collapse { ... } blocks (also functions, comments, JSX) to trace control
;; flow.  Tree-sitter native, so it folds on the real TS/TSX syntax tree
;; rather than matching braces.  Keys live in treesit-fold-mode-map, so they
;; exist only in buffers where folding is on (i.e. .ts / .tsx).
(use-package treesit-fold
  :hook ((typescript-ts-mode . treesit-fold-mode)
         (tsx-ts-mode        . treesit-fold-mode))
  :bind (:map treesit-fold-mode-map
              ("C-<tab>" . treesit-fold-toggle)
              ("C-c z z" . treesit-fold-toggle)
              ("C-c z a" . treesit-fold-close-all)
              ("C-c z r" . treesit-fold-open-all)
              ("C-c z o" . treesit-fold-open)
              ("C-c z c" . treesit-fold-close)))

(provide 'init-typescript)
;;; init-typescript.el ends here
