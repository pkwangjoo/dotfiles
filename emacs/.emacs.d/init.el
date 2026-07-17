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

;; Customize writes machine state (package-selected-packages,
;; custom-safe-themes, etc.) that we don't version-control: this init.el
;; is the single source of truth, and use-package above auto-installs
;; everything on a fresh clone.  Send that output to a throwaway temp
;; file so it never lands in the repo.
(setq custom-file (make-temp-file "emacs-custom-"))

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
  ;; flx ranking only engages below this candidate count; keep it low so
  ;; flx fine-ranks just the narrowed result set instead of scoring every
  ;; file in the project on each keystroke (~500ms lag in a 4k-file repo).
  (setq ivy-flx-limit 200))

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
  :demand t   ; :bind implies deferred loading; load at startup anyway so
              ; counsel-projectile's `:after' gate opens and binds C-c p f
  :bind ("C-c p e" . projectile-run-eshell)   ; eshell at project root
  :config
  (projectile-mode 1))

(use-package counsel-projectile
  :after (counsel projectile)
  :config
  (counsel-projectile-mode 1)
  ;; Match the query against each candidate's basename rather than its
  ;; full project-relative path, so `C-c p f' finds files by name.
  ;; Falls back to path matching only when nothing matches by name.
  (setq counsel-projectile-find-file-matcher
        'counsel-projectile-find-file-matcher-basename)
  :bind (("C-c p f"   . counsel-projectile-find-file)
         ("C-c p s r" . counsel-projectile-rg)))

;; --- Eshell: run interactive CLIs in a term buffer ----------
;; Eshell is not a terminal emulator: CLIs that draw arrow-key menus
;; (inquirer-style prompts) can't redraw their UI, and arrow keys are
;; taken by eshell history instead of reaching the process.  Declaring
;; `npm run' a visual subcommand makes eshell run those commands in a
;; `term' buffer, where the menu renders and navigates normally.
(with-eval-after-load 'em-term
  (add-to-list 'eshell-visual-subcommands '("npm" "run")))

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

;; ============================================================
;; Core editor defaults & UI
;; ============================================================

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
;; Tab bar: project-named workspace tabs
;; ============================================================
;; One frame-level tab per workspace.  The tab is named after the
;; projectile project root folder of the selected window's buffer,
;; falling back to the buffer name when that buffer is not inside a
;; project.  The face tweaks must run after the theme loads so they
;; win over zenburn's own tab-bar faces.

(defun my/tab-bar-project-name ()
  "Tab name: projectile project root folder, else buffer name.
Mirrors `tab-bar-tab-name-current' so the name tracks the selected
window's buffer and stays correct while the minibuffer is active."
  (let ((buffer (window-buffer (or (minibuffer-selected-window)
                                   (and (window-minibuffer-p)
                                        (get-mru-window))))))
    (with-current-buffer buffer
      (if-let ((root (and (fboundp 'projectile-project-root)
                          (projectile-project-root))))
          (file-name-nondirectory (directory-file-name root))
        (buffer-name buffer)))))

(setq tab-bar-tab-name-function #'my/tab-bar-project-name)
(setq tab-bar-show t)              ; always show the bar, even with one tab
(setq tab-bar-new-tab-choice "*scratch*") ; new tabs open scratch, not a fork
(tab-bar-mode 1)

;; "Raised button" look (tuned for zenburn): the active tab is a padded,
;; faintly-bordered cap on a recessed strip; inactive tabs are flat and
;; dim.  The inactive box matches its own background so every tab keeps
;; the same size and the bar never jumps on selection change.
(set-face-attribute 'tab-bar nil
                    :background "#3F3F3F" :foreground "#989890" :box nil)
(set-face-attribute 'tab-bar-tab nil
                    :background "#4F4F4F" :foreground "#DCDCCC" :weight 'bold
                    :box '(:line-width (8 . 3) :color "#6F6F6F"))
(set-face-attribute 'tab-bar-tab-inactive nil
                    :background "#3F3F3F" :foreground "#989890" :weight 'normal
                    :box '(:line-width (8 . 3) :color "#3F3F3F"))

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
  :bind (:map eglot-mode-map
              ("M-T"   . eglot-find-typeDefinition)   ; M-Shift-t: go to type definition
              ("C-c ." . eglot-code-actions))          ; Cmd-. equivalent: quick fix / add import
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
  (setf (alist-get 'tsx-ts-mode        apheleia-mode-alist) 'prettier)
  ;; raco fmt reads a file argument and prints the result to stdout.
  (setf (alist-get 'raco-fmt apheleia-formatters) '("raco" "fmt" file))
  (setf (alist-get 'scheme-mode apheleia-mode-alist) 'raco-fmt))

;; --- Magit (Git interface) ---------------------------------
(use-package magit
  :bind (("C-x g"   . magit-status)
         ("C-c g b" . magit-blame))
  :custom
  ;; Don't run `save-some-buffers' on `magit-status' refresh.  The user
  ;; always saves intentional edits by hand, so their work is already on
  ;; disk by the time `C-x g' runs; this kills the "Save file?" nag and
  ;; guarantees magit can never write a stale buffer over Claude's disk
  ;; edits.
  (magit-save-repository-buffers nil))

;; --- magit-delta (readable, syntax-highlighted diffs) -------
;; Pipe magit's diffs through the `delta' pager (brew install git-delta).
;; Zenburn's own magit-diff faces are bright solid blocks with no
;; foreground contrast; delta replaces them with syntax-highlighted
;; code on subtle green/red backgrounds.
(use-package magit-delta
  :hook (magit-mode . magit-delta-mode)
  :config
  ;; Delta derives added/removed line backgrounds from the syntax
  ;; theme's near-black background, which is nearly invisible against
  ;; zenburn's #3F3F3F.  Pass explicit backgrounds tuned to zenburn;
  ;; the *-emph styles mark the changed words within a line.
  (setq magit-delta-delta-args
        `("--max-line-distance" "0.6"
          "--true-color" ,(if xterm-color--support-truecolor "always" "never")
          "--color-only"
          "--plus-style"       "syntax #2F4F2F"
          "--plus-emph-style"  "syntax #3F6F3F"
          "--minus-style"      "syntax #4F2F2F"
          "--minus-emph-style" "syntax #703A3A")))

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

;; --- Discard unsaved edits, taking the on-disk version -----
(defun my/discard-unsaved-changes ()
  "Revert every modified file-visiting buffer to its on-disk contents.
Throws away in-Emacs edits, taking whatever is on disk (e.g. Claude's
changes).  Asks once, listing the affected buffers, before acting.
Buffers whose file no longer exists on disk are skipped and reported."
  (interactive)
  (let ((modified (seq-filter (lambda (buf)
                                (and (buffer-file-name buf)
                                     (buffer-modified-p buf)))
                              (buffer-list))))
    (cond
     ((null modified)
      (message "No unsaved changes to discard."))
     ((yes-or-no-p
       (format "Discard unsaved changes in: %s? "
               (mapconcat #'buffer-name modified ", ")))
      (let (missing)
        (dolist (buf modified)
          (if (file-exists-p (buffer-file-name buf))
              (with-current-buffer buf
                (revert-buffer t t t))
            (push (buffer-name buf) missing)))
        (message "Discarded changes in %d buffer(s)%s"
                 (- (length modified) (length missing))
                 (if missing
                     (format "; skipped (file gone): %s"
                             (mapconcat #'identity missing ", "))
                   ""))))
     (t (message "Cancelled.")))))

(global-set-key (kbd "C-c g d") #'my/discard-unsaved-changes)

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
