;;; init-completion.el --- Completion menus and key hints -*- lexical-binding: t; -*-

;;; Commentary:
;; Completion menus for commands, files and buffers (vertico, consult),
;; key hints (which-key) and the completion popup in code (company).

;;; Code:

;;;; Completion menus (commands, files, buffers)
;; vertico: vertical candidate list.
(use-package vertico
  :init (vertico-mode 1))

;; orderless: match words in any order.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; marginalia: notes next to candidates.
(use-package marginalia
  :init (marginalia-mode 1))

;; Remember minibuffer history between sessions.
(savehist-mode 1)

;; consult: search and switching with preview. RET to go, C-g to cancel.
(use-package consult
  :bind (("C-x b"   . consult-buffer)       ; buffers and recent files
         ("C-x C-r" . consult-recent-file)  ; recent files
         ("M-y"     . consult-yank-pop)     ; kill ring
         ("M-g g"   . consult-goto-line)    ; go to line
         ("M-g i"   . consult-imenu)        ; functions and classes in this file
         ("M-s l"   . consult-line)         ; search lines in this file
         ("M-s g"   . consult-grep)         ; search the project
         ("M-s r"   . consult-ripgrep)))    ; same, faster (needs ripgrep)

;;;; Key hints and the completion popup
;; which-key: show the keys available after a prefix.
(use-package which-key
  :init (which-key-mode 1))

;; company: completion popup. TAB accepts the candidate, RET just inserts a newline.
;; <tab> and <return> are for GUI, TAB and RET for terminals.
(use-package company
  :hook (after-init . global-company-mode)
  :custom
  (company-minimum-prefix-length 2)
  (company-idle-delay 0.2)
  :bind (:map company-active-map
         ("TAB" . company-complete-selection)
         ("<tab>" . company-complete-selection)
         ("RET" . nil)
         ("<return>" . nil)))

(provide 'init-completion)
;;; init-completion.el ends here
