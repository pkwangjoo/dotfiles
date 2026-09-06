;;; init-editor.el --- Core editor defaults, UI & editing commands -*- lexical-binding: t; -*-

;; ============================================================
;; Theme
;; ============================================================

;; Zenburn theme (low-contrast dark theme).  Loaded early so later
;; modules' `set-face-attribute' tweaks (tab-bar, magit) win over
;; zenburn's own faces.
(use-package zenburn-theme
  :config
  (load-theme 'zenburn t))

;; ============================================================
;; Core editor defaults & UI
;; ============================================================

;; Mac: Command and Option keys as Meta
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'meta)

;; Basic defaults
(setq ring-bell-function 'ignore)
(setq byte-compile-warnings nil)
(setq make-backup-files nil)
(setq create-lockfiles nil)

;; Auto-save to a dedicated directory
(setq auto-save-default t)
(let ((auto-save-dir (expand-file-name "auto-save/" user-emacs-directory)))
  (unless (file-directory-p auto-save-dir)
    (make-directory auto-save-dir t))
  (setq auto-save-file-name-transforms
        `((".*" ,auto-save-dir t))))

;; --- Keep buffers in sync with on-disk edits ---------------
;; Claude and other external tools edit files on disk; auto-revert pulls those
;; changes into open buffers automatically.  It deliberately skips buffers with
;; unsaved modifications, so an in-progress edit is never overwritten.
(setq auto-revert-verbose nil)   ; silence the "Reverting buffer…" echo
(global-auto-revert-mode 1)

;; Line numbers (vim-style: current line absolute, others relative)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Matching parens
(show-paren-mode 1)

;; Auto-insert the closing ) ] } (and quote string-delimiters per mode syntax)
(electric-pair-mode 1)

;; --- Word deletion that leaves the kill ring alone ----------
;; M-d / M-DEL normally *kill* the word, shadowing an earlier copy on
;; the kill ring, so copy -> delete -> yank pastes the deleted word.
;; These variants use `delete-region', so the copy stays on top.
(defun my/delete-word (arg)
  "Delete a word forward without saving it to the kill ring.
With prefix ARG, delete that many words (backward if negative)."
  (interactive "p")
  (delete-region (point) (progn (forward-word arg) (point))))

(defun my/backward-delete-word (arg)
  "Delete a word backward without saving it to the kill ring.
With prefix ARG, delete that many words."
  (interactive "p")
  (my/delete-word (- arg)))

(global-set-key (kbd "M-d")   #'my/delete-word)
(global-set-key (kbd "M-DEL") #'my/backward-delete-word)

;; ============================================================
;; Keep the cursor centered when paging with C-v / M-v
;; ============================================================
;; After a page scroll, recenter the line point lands on.  This keeps
;; the cursor on the vertical middle line while leaving about half the
;; previous screen visible for continuity.
(defun my/recenter-after-scroll (&rest _)
  "Recenter point in the window.  Used as :after advice on scroll commands."
  (recenter))

(advice-add 'scroll-up-command   :after #'my/recenter-after-scroll)
(advice-add 'scroll-down-command :after #'my/recenter-after-scroll)

;; Indentation (modern editor behavior)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(electric-indent-mode 1)
(setq-default tab-always-indent nil)

;; Scratch buffer: RET continues at same indentation
(defun newline-continue-indent ()
  (interactive)
  (let ((indent (current-indentation)))
    (newline)
    (insert (make-string indent ?\s))))

(add-hook 'lisp-interaction-mode-hook
          (lambda ()
            (local-set-key (kbd "RET") #'newline-continue-indent)
            (local-set-key (kbd "TAB") #'tab-to-tab-stop)))

;; UTF-8 everywhere
(set-default-coding-systems 'utf-8)

;; Short yes/no prompts
(defalias 'yes-or-no-p 'y-or-n-p)

;; ============================================================
;; Semantic region selection (expand-region)
;; ============================================================
;; The non-modal answer to vim's `vi"` / `vi(` text objects: place point
;; inside the delimiters and press C-= repeatedly.  Each press grows the
;; region by one syntactic unit -- inside a string the first expansion
;; grabs the quoted contents, the next includes the quotes themselves;
;; the same walk works outward through pairs, sexps, and defuns.
(use-package expand-region
  :bind ("C-=" . er/expand-region))

(provide 'init-editor)
;;; init-editor.el ends here
