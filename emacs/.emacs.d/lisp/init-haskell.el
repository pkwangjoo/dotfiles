;;; init-haskell.el --- Haskell editing -*- lexical-binding: t; -*-

;; Depends on the shared packages in init-prog (eglot, apheleia).
;; The toolchain (ghcup shims in ~/.local/bin, fourmolu in
;; ~/.local/share/cabal/bin) is already on `exec-path' via
;; init-bootstrap's exec-path-from-shell import.

(use-package haskell-mode
  :mode (("\\.hs\\'"    . haskell-mode)
         ("\\.lhs\\'"   . haskell-mode)
         ("\\.cabal\\'" . haskell-cabal-mode))
  :hook (haskell-mode . eglot-ensure)
  :custom
  (haskell-process-type 'cabal-repl))   ; C-c C-l loads into a cabal repl

;; Format-on-save with fourmolu.  apheleia ships the `fourmolu' formatter
;; and already defaults haskell-mode to it; set it explicitly to match
;; how the other language modules document their formatter.
(with-eval-after-load 'apheleia
  (setf (alist-get 'haskell-mode apheleia-mode-alist) 'fourmolu))

(provide 'init-haskell)
;;; init-haskell.el ends here
