;;; init-editing.el --- Editing and file behavior -*- lexical-binding: t; -*-

;;; Commentary:
;; Russian layout, cua keys, brackets, auto-revert, backups.

;;; Code:

;;;; Editing
;; Key bindings (C-x, M-x...) also work in the Russian layout.
(use-package reverse-im
  :custom (reverse-im-input-methods '("russian-computer"))
  :config (reverse-im-mode 1))

;; Color brackets by nesting depth.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;;; Behavior
(setq-default indent-tabs-mode nil  ; indent with spaces
              tab-width 4)          ; show tabs as 4 spaces
;; Don't copy deleted selections to register 0: after a deletion and C-z the
;; delete-selection-replacement overlay could spread over the whole buffer.
;; Must precede (cua-mode 1).
(setopt cua-delete-copy-to-register-0 nil)
(cua-mode 1)                     ; C-c/C-x/C-v/C-z: copy/cut/paste/undo
(setq use-short-answers t)       ; y/n instead of yes/no
(electric-pair-mode 1)           ; auto-close brackets and quotes
(show-paren-mode 1)              ; highlight the matching bracket
(delete-selection-mode 1)        ; typing replaces the selection
(save-place-mode 1)              ; remember the cursor position in files
(recentf-mode 1)                 ; recent files list
(global-auto-revert-mode 1)      ; reload files changed on disk

;;;; Backups and auto-saves
;; Keep file~ and #file# in one folder instead of next to the files.
(let ((dir (expand-file-name "backups/" user-emacs-directory)))
  (make-directory dir t)
  (setq backup-directory-alist `(("." . ,dir))
        auto-save-file-name-transforms `((".*" ,dir t))))

(provide 'init-editing)
;;; init-editing.el ends here
