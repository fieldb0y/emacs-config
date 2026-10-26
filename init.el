;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Startup: custom.el, packages and PATH, then the modules in lisp/.

;;; Code:

;;;; Customize
;; Keep what Emacs writes itself (M-x customize, installed packages) in custom.el.
;; Set first, so installing the packages below doesn't append to init.el.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)

;;;; Packages
;; MELPA: the main third-party archive (only GNU ELPA is enabled by default).
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; Install missing packages automatically on startup.
(require 'use-package)
(setq use-package-always-ensure t)

;;;; Environment
;; GUI Emacs doesn't read ~/.bashrc: add the dirs with language servers
;; (rust-analyzer, jdtls) to PATH here.
(dolist (dir (list (expand-file-name "~/.local/bin")
                   (expand-file-name "~/.cargo/bin")))
  (when (and (file-directory-p dir) (not (member dir exec-path)))
    (push dir exec-path)
    (setenv "PATH" (concat dir path-separator (getenv "PATH")))))

;;;; Modules
;; The rest of the config, one file per topic in lisp/. Loaded in a loop, so
;; flymake's check of init.el doesn't load them.
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(dolist (module '(init-ui          ; line numbers, cursor, theme, mode line, icons
                  init-completion  ; vertico, consult, which-key, company
                  init-editing     ; Russian layout, cua keys, brackets, backups
                  init-git         ; magit, diff-hl
                  init-prog        ; tree-sitter, eglot, flymake, languages
                  init-claude      ; Claude Code: ghostel, claude-code-ide
                  init-windows))   ; compilation window, M-o (my-ace-window.el), winner
  (require module))

;;; init.el ends here
