;;; init-markdown.el --- Markdown document-style reading view -*- lexical-binding: t; -*-

;; Proportional font used for prose (headings, paragraphs, lists).
;; Tweak :family / :height to taste. Sans default; "Georgia" is a
;; readable serif alternative for long-form reading.
(set-face-attribute 'variable-pitch nil :family "Helvetica Neue" :height 160)

(use-package markdown-mode
  :preface
  (defun my/markdown-reading-setup ()
    "In-buffer document reading view for markdown."
    (display-line-numbers-mode -1)             ; no line numbers while reading
    (visual-line-mode 1)                       ; soft wrap on word boundaries
    (setq-local line-spacing 0.2)              ; looser leading
    (markdown-display-inline-images))          ; render local inline images
  :mode (("\\.md\\'"       . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :custom
  (markdown-hide-markup t)                    ; hide ** _ # and link syntax
  (markdown-hide-urls t)                       ; show link text, hide the URL
  (markdown-header-scaling t)                  ; h1 > h2 > h3 ...
  (markdown-fontify-code-blocks-natively t)    ; syntax-highlight fenced code
  :hook (markdown-mode . my/markdown-reading-setup))

(use-package mixed-pitch
  :hook (markdown-mode . mixed-pitch-mode)
  :config
  ;; Keep code, tables, and language tags monospace.
  (dolist (face '(markdown-code-face
                  markdown-inline-code-face
                  markdown-pre-face
                  markdown-table-face
                  markdown-language-keyword-face))
    (add-to-list 'mixed-pitch-fixed-pitch-faces face)))

(use-package visual-fill-column
  :hook (markdown-mode . visual-fill-column-mode)
  :custom
  (visual-fill-column-width 90)
  (visual-fill-column-center-text t))

(provide 'init-markdown)
;;; init-markdown.el ends here
