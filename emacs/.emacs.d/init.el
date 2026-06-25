;;; init.el --- Minimal Emacs configuration -*- lexical-binding: t; -*-

;; Package management
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Install use-package if not present
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Ivy + Counsel + Swiper
(use-package ivy
  :diminish
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  (setq ivy-wrap t)
  ;; Flex fuzzy matching for the project file finder so a contiguous
  ;; query like "sardineservice" matches "sardine.service" (separators
  ;; in the filename no longer break the match).  Everything else keeps
  ;; the default literal/substring matcher.
  (setq ivy-re-builders-alist
        '((counsel-projectile-find-file . ivy--regex-fuzzy)
          (t                            . ivy--regex-plus)))
  ;; flx ranking only engages below this candidate count; raise it well
  ;; past typical project file counts so the fuzzy matches sort sensibly.
  (setq ivy-flx-limit 10000))

;; flx scores fuzzy candidates so the tightest matches float to the top.
(use-package flx)

(use-package counsel
  :diminish
  :after ivy
  :config
  (counsel-mode 1))

(use-package swiper
  :after ivy
  :bind ("C-s" . swiper))

;; Project-scoped fuzzy file finder (like VS Code Ctrl+P)
(use-package projectile
  :diminish
  :config
  (projectile-mode 1))

(use-package counsel-projectile
  :after (counsel projectile)
  :config
  (counsel-projectile-mode 1)
  :bind (("C-c p f"   . counsel-projectile-find-file)
         ("C-c p s r" . counsel-projectile-rg)))

;; Inherit env variables from shell (needed for GUI Emacs on macOS)
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Zenburn theme (low-contrast dark theme)
(use-package zenburn-theme
  :config
  (load-theme 'zenburn t))

;; ============================================================
;; Markdown: document-style reading view
;; ============================================================

;; Proportional font used for prose (headings, paragraphs, lists).
;; Tweak :family / :height to taste. Sans default; "Georgia" is a
;; readable serif alternative for long-form reading.
(set-face-attribute 'variable-pitch nil :family "Helvetica Neue" :height 160)

(use-package markdown-mode
  :mode (("\\.md\\'"       . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :custom
  (markdown-hide-markup t)                    ; hide ** _ # and link syntax
  (markdown-hide-urls t)                       ; show link text, hide the URL
  (markdown-header-scaling t)                  ; h1 > h2 > h3 ...
  (markdown-fontify-code-blocks-natively t)    ; syntax-highlight fenced code
  :hook (markdown-mode . my/markdown-reading-setup)
  :config
  (defun my/markdown-reading-setup ()
    "In-buffer document reading view for markdown."
    (display-line-numbers-mode -1)             ; no line numbers while reading
    (visual-line-mode 1)                       ; soft wrap on word boundaries
    (setq-local line-spacing 0.2)              ; looser leading
    (markdown-display-inline-images)))         ; render local inline images

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

;; Cleaner UI
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)

;; Mac: Command key as Meta
(setq mac-command-modifier 'meta)
(setq mac-option-modifier 'super)

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

;; Line numbers and column
(global-display-line-numbers-mode 1)
(column-number-mode 1)

;; Matching parens
(show-paren-mode 1)

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
;; Development: TypeScript / LSP / Lint / Format / Git
;; ============================================================

;; --- Tree-sitter grammars for TypeScript -------------------
;; One-time compile of the TS/TSX grammars (needs cc + git on PATH).
(require 'treesit)                 ; treesit-ready-p is not autoloaded
(setq treesit-language-source-alist
      '((typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (tsx        "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")))

(dolist (grammar '(typescript tsx))
  (unless (treesit-ready-p grammar t)
    (treesit-install-language-grammar grammar)))

;; Use the tree-sitter modes for .ts / .tsx files.
(add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

;; --- Eglot (built-in LSP client) ---------------------------
;; Eglot already knows to launch typescript-language-server for these modes.
(use-package eglot
  :ensure nil                      ; built-in; do not fetch from MELPA
  :hook ((typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode        . eglot-ensure)))

;; --- Corfu (in-buffer completion popup) --------------------
(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)                   ; pop up automatically as you type
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  :config
  ;; No in-buffer completion popup in org-mode buffers.
  (add-hook 'org-mode-hook (lambda () (corfu-mode -1))))

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
(use-package apheleia
  :init
  (apheleia-global-mode 1)
  :config
  ;; Map the tree-sitter modes to apheleia's prettier formatter.
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'tsx-ts-mode        apheleia-mode-alist) 'prettier))

;; --- Magit (Git interface) ---------------------------------
(use-package magit
  :bind (("C-x g"   . magit-status)
         ("C-c g b" . magit-blame)))

;; --- Jest (run tests from the buffer) ----------------------
;; Defaults already give us `npx jest` and the `C-c C-t` keymap,
;; so this just installs the package and turns it on in TS buffers.
(use-package jest-test-mode
  :hook ((typescript-ts-mode . jest-test-mode)
         (tsx-ts-mode        . jest-test-mode)))

;; ============================================================
;; Reload configuration from disk
;; ============================================================

(defun my/init-file-buffer ()
  "Return a live buffer visiting the init file, or nil.
Matches by file identity (inode), so it finds the buffer even when
init.el is opened through its hard-linked path under dotfiles/."
  (seq-find (lambda (buf)
              (let ((file (buffer-file-name buf)))
                (and file (file-equal-p file user-init-file))))
            (buffer-list)))

(defun my/reload-init ()
  "Reload `init.el' from disk and apply it.
Intended for the workflow where an external tool edits and saves
init.el: this loads the on-disk file, then refreshes the visiting
buffer (if any) so it matches disk.  It never saves that buffer,
which would clobber the external edits with stale contents."
  (interactive)
  (load-file user-init-file)
  (let ((buf (my/init-file-buffer)))
    (cond
     ((null buf)
      (message "init.el reloaded"))
     ((buffer-modified-p buf)
      (message "init.el reloaded (open buffer has unsaved edits; left as-is)"))
     (t
      (with-current-buffer buf
        (revert-buffer t t t))
      (message "init.el reloaded and buffer refreshed")))))

(global-set-key (kbd "C-c r") #'my/reload-init)

(defun my/open-init ()
  "Open the Emacs init file for editing."
  (interactive)
  (find-file user-init-file))

(global-set-key (kbd "C-c I") #'my/open-init)

;; --- Copy current file as a Claude @-path ------------------
(defun my/copy-claude-file-path ()
  "Copy the current file's path as a Claude Code @-reference.
The path is relative to the Projectile project root, prefixed with
\"@\" and with no leading slash (e.g. @lisp/foo.el)."
  (interactive)
  (let* ((file (buffer-file-name))
         (root (and file (projectile-project-root))))
    (cond
     ((not file) (message "Buffer is not visiting a file"))
     ((not root) (message "Not in a Projectile project: %s" file))
     (t (let ((ref (concat "@" (file-relative-name file root))))
          (kill-new ref)
          (message "Copied: %s" ref))))))

(global-set-key (kbd "C-c @") #'my/copy-claude-file-path)

;; ============================================================
;; Pinned files: persistent, additive quick-access list
;; ============================================================

(defvar my/pinned-files-file
  (expand-file-name "pinned-files.eld" user-emacs-directory)
  "File where the pinned-files list is persisted.")

(defvar my/pinned-files nil
  "List of absolute file paths that have been pinned.")

(defun my/pinned-files-load ()
  "Populate `my/pinned-files' from `my/pinned-files-file', if it exists."
  (when (file-exists-p my/pinned-files-file)
    (condition-case err
        (with-temp-buffer
          (insert-file-contents my/pinned-files-file)
          (setq my/pinned-files (read (current-buffer))))
      (error
       (message "Could not read pinned files: %s" (error-message-string err))
       (setq my/pinned-files nil)))))

(defun my/pinned-files-save ()
  "Write `my/pinned-files' to `my/pinned-files-file'."
  (with-temp-file my/pinned-files-file
    (insert ";; my/pinned-files -- auto-generated; do not edit by hand.\n")
    (prin1 my/pinned-files (current-buffer))
    (insert "\n")))

(defun my/pin-file ()
  "Pin the file visited by the current buffer (additive)."
  (interactive)
  (let ((file (buffer-file-name)))
    (cond
     ((not file)
      (message "Buffer is not visiting a file"))
     ((member (setq file (expand-file-name file)) my/pinned-files)
      (message "Already pinned: %s" (abbreviate-file-name file)))
     (t
      (setq my/pinned-files (append my/pinned-files (list file)))
      (my/pinned-files-save)
      (message "Pinned: %s" (abbreviate-file-name file))))))

(defun my/open-pinned-file ()
  "Pick a pinned file from the minibuffer and open it."
  (interactive)
  (if (null my/pinned-files)
      (message "No pinned files")
    (let ((choice (completing-read
                   "Open pinned file: "
                   (mapcar #'abbreviate-file-name my/pinned-files)
                   nil t)))
      (find-file (expand-file-name choice)))))

(defun my/unpin-file ()
  "Pick a pinned file from the minibuffer and remove it from the list."
  (interactive)
  (if (null my/pinned-files)
      (message "No pinned files")
    (let* ((choice (completing-read
                    "Unpin file: "
                    (mapcar #'abbreviate-file-name my/pinned-files)
                    nil t))
           (file (expand-file-name choice)))
      (setq my/pinned-files (delete file my/pinned-files))
      (my/pinned-files-save)
      (message "Unpinned: %s" choice))))

(my/pinned-files-load)

(global-set-key (kbd "C-c f f") #'my/open-pinned-file)
(global-set-key (kbd "C-c f p") #'my/pin-file)
(global-set-key (kbd "C-c f u") #'my/unpin-file)

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("a5c590aeb7dc5c2b8d36601a4c94a1145e46bd2291571af02807dd7a8552630c"
     default))
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
