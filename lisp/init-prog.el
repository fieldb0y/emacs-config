;;; init-prog.el --- Programming -*- lexical-binding: t; -*-

;;; Commentary:
;; Tree-sitter, language servers (eglot), errors (flymake) and languages.

;;; Code:

;; Tree-sitter: use *-ts-mode and install missing grammars automatically
;; (needs git and gcc) into ~/.emacs.d/tree-sitter/.
(setopt treesit-enabled-modes t
        treesit-auto-install-grammar 'always)

;; C/C++: 4-space indent, K&R style.
(setopt c-ts-mode-indent-offset 4
        c-ts-mode-indent-style 'k&r)

;; Flymake: on-the-fly errors, mostly from eglot. Marks in the right fringe,
;; clear of diff-hl.
(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom (flymake-fringe-indicator-position 'right-fringe)
  :bind (:map flymake-mode-map
         ("M-n"   . flymake-goto-next-error)
         ("M-p"   . flymake-goto-prev-error)
         ("C-c e" . flymake-show-buffer-diagnostics)
         ("C-c E" . flymake-show-project-diagnostics)))

;; Emacs Lisp: flymake compiles the files in lisp/ too, as it does init.el,
;; and finds the installed packages there.
(add-to-list 'trusted-content
             (abbreviate-file-name (file-truename (expand-file-name "lisp/" user-emacs-directory))))
(setopt elisp-flymake-byte-compile-load-path (cons "./" load-path))

;; Eglot: language server client (definitions, references, rename, fixes).
(use-package eglot
  :ensure nil
  :custom (eglot-autoshutdown t)        ; stop the server with the project's last buffer
  :bind (:map eglot-mode-map
         ("C-c r" . eglot-rename)
         ("C-c a" . eglot-code-actions)
         ("C-c f" . eglot-format)
         ("C-c d" . eldoc-doc-buffer)))

;; Start eglot automatically when the language server is installed.
;; Without one, M-x eglot shows what's missing.
(defconst my/eglot-servers
  '(((c-mode c-ts-mode c++-mode c++-ts-mode) "clangd")
    ((rust-mode rust-ts-mode)                "rust-analyzer")
    ((java-mode java-ts-mode)                "jdtls")
    ((python-mode python-ts-mode)            "pylsp" "basedpyright-langserver" "pyright-langserver"))
  "Major modes and the executables of their language servers.")

(defun my/eglot-ensure-if-installed ()
  "Start eglot in this buffer if a language server for its mode is installed."
  (when-let* ((entry (seq-find (lambda (e) (apply #'derived-mode-p (car e)))
                               my/eglot-servers)))
    (when (seq-some #'executable-find (cdr entry))
      (eglot-ensure))))
(add-hook 'prog-mode-hook #'my/eglot-ensure-if-installed)

;; NASM assembly (.asm, .nasm): highlighting and indentation, no language server.
(use-package nasm-mode
  :mode "\\.\\(asm\\|nasm\\)\\'")

;; Markdown: .md files.
(use-package markdown-mode
  :mode ("\\.md\\'" . markdown-mode))

(provide 'init-prog)
;;; init-prog.el ends here
