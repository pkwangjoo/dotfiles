;;; init-bootstrap.el --- Package system & shell environment -*- lexical-binding: t; -*-

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

;; Inherit env variables from shell (needed for GUI Emacs on macOS).
;; Loaded here, before any module that shells out -- the tree-sitter
;; grammar compile in init-prog needs cc + git on PATH, and geiser needs
;; the `racket' binary.
(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

(provide 'init-bootstrap)
;;; init-bootstrap.el ends here
