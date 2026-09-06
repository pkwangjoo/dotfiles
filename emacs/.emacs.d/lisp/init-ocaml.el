;;; init-ocaml.el --- OCaml editing -*- lexical-binding: t; -*-

;; Depends on the shared packages in init-prog (eglot, apheleia).

(use-package tuareg
  :mode (("\\.ml\\'"  . tuareg-mode)
         ("\\.mli\\'" . tuareg-mode))
  :hook (tuareg-mode . eglot-ensure))

(use-package dune
  :ensure t)

;; Format-on-save with ocamlformat (apheleia ships this formatter).
(with-eval-after-load 'apheleia
  (setf (alist-get 'tuareg-mode apheleia-mode-alist) 'ocamlformat))

(provide 'init-ocaml)
;;; init-ocaml.el ends here
