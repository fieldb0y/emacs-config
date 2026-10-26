;;; init-ui.el --- Interface and appearance -*- lexical-binding: t; -*-

;;; Commentary:
;; How Emacs looks: line numbers, cursor, scrolling, theme, mode line, icons.

;;; Code:

;;;; Interface
;; Menu bar, tool bar, scroll bars and font are set in early-init.el.
(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)

(column-number-mode 1)
(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)

;; 2px bar cursor, as in VS Code.
(setq-default cursor-type '(bar . 2))

;; Smooth pixel scrolling with the mouse wheel and touchpad.
(pixel-scroll-precision-mode 1)

;;;; Appearance (packages)
;; Theme: spacemacs-dark or spacemacs-light.
(use-package spacemacs-theme
  :config (load-theme 'spacemacs-dark t))

;; Icons. Install their font once with M-x nerd-icons-install-fonts.
(use-package nerd-icons)

;; Icons in completion menus and in dired.
(use-package nerd-icons-completion
  :after marginalia
  :config (nerd-icons-completion-mode 1)
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

;; Nicer mode line.
(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; More themes for M-x load-theme: doom-one, doom-nord, doom-gruvbox...
(use-package doom-themes)

(provide 'init-ui)
;;; init-ui.el ends here
