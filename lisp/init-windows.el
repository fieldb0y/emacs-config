;;; init-windows.el --- Windows -*- lexical-binding: t; -*-

;;; Commentary:
;; Where compilation and grep windows open, M-o window commands
;; (my-ace-window.el) and winner-mode.

;;; Code:

;; Compilation and grep open in a full-width window at the bottom, reused by later runs;
;; other windows stay as they are. The cursor moves there, q closes it.
(add-to-list 'display-buffer-alist
             '((derived-mode . compilation-mode)
               (display-buffer-reuse-window display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.25)  ; a quarter of the frame
               (post-command-select-window . t)))

;; RET on an error opens the file in the window you came from, not in a random one.
(add-hook 'compilation-mode-hook
          (lambda () (setq-local display-buffer-base-action '(nil . ((some-window . mru))))))

;; M-o: window commands, see my-ace-window.el. Installs ace-window;
;; the file loads on the first M-o.
(use-package my-ace-window
  :ensure ace-window
  :bind ("M-o" . my/ace-window))

;; winner-mode: C-c <left> undoes a window layout change, C-c <right> redoes it.
(winner-mode 1)

(provide 'init-windows)
;;; init-windows.el ends here
