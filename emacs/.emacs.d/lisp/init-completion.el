;;; init-completion.el --- Minibuffer completion, project nav & workspaces -*- lexical-binding: t; -*-

;; ============================================================
;; Ivy + Counsel + Swiper
;; ============================================================

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

;; ============================================================
;; Projectile: project-scoped fuzzy file finder (like VS Code Ctrl+P)
;; ============================================================

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
         ;; counsel-projectile-rg calls projectile-ignored-files-rel, which
         ;; newer projectile releases removed as part of a rewrite of the
         ;; ignore-pattern engine; counsel-projectile itself hasn't been
         ;; updated since 2021, so the wrapper is permanently broken.  Go
         ;; straight to counsel-rg (still maintained, part of core
         ;; counsel) rooted at the projectile project root instead.
         ("C-c p s r" . (lambda ()
                          (interactive)
                          (counsel-rg nil (projectile-project-root))))))

;; ============================================================
;; Eshell: run interactive CLIs in a term buffer
;; ============================================================
;; Eshell is not a terminal emulator: CLIs that draw arrow-key menus
;; (inquirer-style prompts) can't redraw their UI, and arrow keys are
;; taken by eshell history instead of reaching the process.  Declaring
;; `npm run' a visual subcommand makes eshell run those commands in a
;; `term' buffer, where the menu renders and navigates normally.
(with-eval-after-load 'em-term
  (add-to-list 'eshell-visual-subcommands '("npm" "run")))

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

(provide 'init-completion)
;;; init-completion.el ends here
