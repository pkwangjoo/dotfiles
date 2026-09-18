;;; init-latex.el --- LaTeX editing: AUCTeX, texlab, pdf-tools -*- lexical-binding: t; -*-

;; Depends on the shared packages in init-prog (eglot, apheleia).
;; Build tooling (pdflatex, latexmk, latexindent) comes from MacTeX,
;; already on PATH; texlab (LSP server) is installed via `brew install
;; texlab'.  apheleia already defaults LaTeX-mode to latexindent, so no
;; formatter wiring is needed here.

;; PDF viewer with SyncTeX support, used in place of Preview.app so
;; forward/inverse search jumps between the .tex source and the PDF
;; inside Emacs.  `pdf-tools-install' compiles the epdfinfo server on
;; first run (needs poppler, already on this machine).
(use-package pdf-tools
  :config
  (pdf-tools-install :no-query))

(use-package tex
  :ensure auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  ;; LaTeX-mode itself unconditionally sets TeX-command-default to "LaTeX"
  ;; as part of its own mode body, before mode hooks run -- so overriding
  ;; it via :custom (a one-time global setq at load) gets stomped on every
  ;; buffer.  Set it here instead, where it runs after that.
  :hook ((LaTeX-mode . eglot-ensure)
         (LaTeX-mode . turn-on-reftex)                          ; label/ref navigation (C-c )
         (LaTeX-mode . (lambda () (setq TeX-command-default "LaTeXMk")))) ; C-c C-c runs latexmk
  ;; TeX-command-force is a plain `defvar', not a `defcustom' -- AUCTeX
  ;; only ever let-binds it internally (see TeX-command-menu), so setting
  ;; it via :custom's `customize-set-variable' is a silent no-op. A plain
  ;; setq is what actually takes effect.
  :init
  (setq TeX-command-force "LaTeXMk")     ; C-c C-c runs it without prompting
  :custom
  (TeX-auto-save t)                      ; cache style info between sessions
  (TeX-parse-self t)                     ; parse the doc for macros/labels
  (TeX-master t)                         ; don't ask; assume single-file docs
  (TeX-source-correlate-start-server t)  ; needed for inverse search
  (TeX-view-program-selection '((output-pdf "PDF Tools")))
  (TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view)))
  :config
  (TeX-source-correlate-mode 1)          ; SyncTeX forward search (C-c C-v)
  ;; Refresh the PDF Tools buffer in place after each successful build,
  ;; instead of leaving it showing the stale, pre-edit render.
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

;; texlab has no default entry in `eglot-server-programs' on this Emacs
;; build; add one so `eglot-ensure' above knows what to launch.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((LaTeX-mode latex-mode) . ("texlab"))))

(provide 'init-latex)
;;; init-latex.el ends here
