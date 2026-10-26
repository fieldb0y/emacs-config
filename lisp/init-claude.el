;;; init-claude.el --- Claude Code -*- lexical-binding: t; -*-

;;; Commentary:
;; Claude Code in a side window: claude-code-ide over the ghostel terminal.

;;; Code:

;; Terminal for Claude Code. After a ghostel update its native module is gone
;; and ghostel offers to download it again. vterm is a fallback.
;; (use-package vterm
;;   :ensure t)

(use-package ghostel
  :ensure t
  :custom
  ;; Keys ghostel leaves to Emacs. M-o is added for window commands.
  (ghostel-keymap-exceptions '("C-c" "C-x" "C-u" "C-h" "M-x" "M-:" "C-\\" "M-o"))
  ;; No line numbers in the terminal.
  :hook (ghostel-mode . (lambda () (display-line-numbers-mode -1))))

;; claude-code-ide: Claude Code in a side window. Through MCP Claude sees the open file,
;; the selection and flymake errors, and searches the project with xref.
;; Needs the claude CLI in PATH. C-c c opens the menu.
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c c" . claude-code-ide-menu)
  :custom
  (claude-code-ide-terminal-backend 'ghostel)
  (claude-code-ide-show-backend-recommendation nil) ; no vterm/ghostel tip on start
;;  (claude-code-ide-enable-execute-code nil)         ; forbid Claude to run Elisp here
  :config (claude-code-ide-emacs-tools-setup))

;; Ctrl+G in Claude Code edits the prompt in $VISUAL: make it this Emacs, so the prompt
;; opens in a buffer and C-x # sends it back. Set inside Emacs only, not in the shell.
(require 'server)
(unless (server-running-p) (server-start))
(setenv "VISUAL" "emacsclient")
(setenv "EDITOR" "emacsclient")
;; Open that buffer in another window, not in the Claude side window.
(setq server-window #'pop-to-buffer)

(provide 'init-claude)
;;; init-claude.el ends here
