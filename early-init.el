;;; early-init.el --- Runs before the first frame is created -*- lexical-binding: t; -*-

;; Turn off UI elements in the frame parameters, so they are never created
;; instead of flashing at startup.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; spacemacs-dark colors, so the frame isn't white until the theme loads.
(push '(background-color . "#292b2e") default-frame-alist)
(push '(foreground-color . "#b2b2b2") default-frame-alist)

;; Font, set here so the frame doesn't resize after startup.
;; Format: "Name-size in points". Change the font on this line.
(push '(font . "JetBrains Mono-12") default-frame-alist)

;; Don't resize the frame when the font or UI elements change.
(setq frame-inhibit-implied-resize t)

;;; early-init.el ends here
