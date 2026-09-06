;;; early-init.el --- Pre-frame UI setup -*- lexical-binding: t; -*-

;; Runs before the first frame is created, so suppressing chrome here
;; avoids a visible flash of the menu/tool/scroll bars at startup.
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)

;;; early-init.el ends here
