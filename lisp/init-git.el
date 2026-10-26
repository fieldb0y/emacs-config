;;; init-git.el --- Git -*- lexical-binding: t; -*-

;;; Commentary:
;; magit and the marks of changed lines.

;;; Code:

;; magit: git UI. C-x g opens the repository status.
(use-package magit
  :bind ("C-x g" . magit-status))

;; Open the real file behind a symlink to the config repo, without asking.
(setq vc-follow-symlinks t)

;; diff-hl: changed lines in the left fringe (green added, blue changed, red deleted).
;; Updates before saving and after magit actions.
(use-package diff-hl
  :hook ((after-init . global-diff-hl-mode)
         (magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :config (diff-hl-flydiff-mode 1))

(provide 'init-git)
;;; init-git.el ends here
