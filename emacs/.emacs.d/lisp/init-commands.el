;;; init-commands.el --- Personal workflow commands -*- lexical-binding: t; -*-

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

(provide 'init-commands)
;;; init-commands.el ends here
