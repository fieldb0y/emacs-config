;;; my-ace-window.el --- M-o: window commands on top of ace-window -*- lexical-binding: t; -*-

;;; Commentary:
;; M-o: window commands (ace-window): windows get numbers, then press:
;;   1-9, w a s d       go to that window / the one above, left, below, right
;;   W A S D            split and go to the new half on that side
;;   k + window         close it (window: number or w a s d); k k closes the current one
;;   K + window         close all other windows; K K keeps the current one
;;   m + window         swap with it, the cursor follows your buffer; m alone with two windows
;;   arrows, S-arrows   move a border of the current window by 1 / 3; M-o stays active
;;   C-b                back from k, K or m (they take only a window, k k / K K and C-b)
;;   ?                  hide or show the key list; C-g exits
;;   Meta + command     do it, then M-o comes back to the mode it was pressed in:
;;                      M-o M-k w D closes the window above, then splits to the right;
;;                      M-o M-w d goes up, then right; M-o k M-w M-a closes two windows
;; A wrong key shows why next to the action for two seconds instead of ending M-o.
;; Neighbor windows show their w/a/s/d key next to the number, as 2(d); numbers and keys
;; take the color of the action shown in the echo area under the key list.
;; Command letters work in the Russian layout too.
;;
;; init-windows.el loads this file on the first M-o.

;;; Code:

(require 'ace-window)
(require 'which-key)                    ; its faces color the key list

;;;; Keys and actions
(defconst my/aw-directions
  '((?w above "above") (?a left "to the left") (?s below "below") (?d right "to the right"))
  "Direction keys for `ace-window': key, direction, name for messages.")

(defconst my/aw-arrows
  '((up ?w 1) (left ?a 1) (down ?s 1) (right ?d 1)
    (S-up ?w 3) (S-left ?a 3) (S-down ?s 3) (S-right ?d 3))
  "Arrow keys for `ace-window': key, direction (w a s d), lines or columns.")

(defconst my/aw-russian-keys
  '((?ц . ?w) (?ф . ?a) (?ы . ?s) (?в . ?d) (?Ц . ?W) (?Ф . ?A) (?Ы . ?S) (?В . ?D)
    (?л . ?k) (?Л . ?K) (?ь . ?m))
  "Russian-layout letters of `ace-window' commands and their Latin keys.")

(defconst my/aw-actions
  '((aw-switch-to-window "Switch to window" font-lock-keyword-face)
    (my/aw-delete-window "Close window" error)
    (my/aw-delete-other-windows "Close other windows" warning)
    (my/aw-swap-window "Swap windows" font-lock-function-name-face))
  "Name and face of each `ace-window' action, for the echo area.")

;;;; Window commands
(defvar my/aw-active nil
  "Non-nil while `my/ace-window' runs.")

;; Taken when a round of M-o starts and used by the numbers, w/a/s/d and hints.
(defvar my/aw-windows nil
  "Windows of the running `my/ace-window', in number order.")

(defvar my/aw-neighbors nil
  "Direction keys (w a s d) and the windows they reach in `my/ace-window'.")

(defun my/aw-neighbor (direction)
  "Return the window next to the selected one in DIRECTION, or nil."
  (let ((window (window-in-direction direction nil t)))
    (unless (and window (or (window-minibuffer-p window) (aw-ignored-p window)))
      window)))

(defun my/aw-window-state (window)
  "Return WINDOW's buffer, scroll position, point and dedication."
  (list (window-buffer window) (window-start window)
        (window-point window) (window-dedicated-p window)))

(defun my/aw-put-window-state (window state)
  "Show STATE from `my/aw-window-state' in WINDOW.
Strong dedication (the Claude window) moves with the buffer;
a side window stays a side window."
  (pcase-let ((`(,buffer ,start ,point ,dedicated) state))
    (set-window-dedicated-p window nil)
    (set-window-buffer window buffer)
    (set-window-start window start t)
    (set-window-point window point)
    ;; The window may be smaller or bigger: keep point in view, and if the buffer
    ;; ends on screen, fill the window with what's above it (so a terminal stays at
    ;; its bottom). Scroll now, not at the next redisplay, after M-o numbered it.
    (with-selected-window window
      (cond ((not (pos-visible-in-window-p point))
             (recenter -1))
            ((pos-visible-in-window-p (point-max))
             (save-excursion
               (goto-char (point-max))
               (recenter -1)))))
    (set-window-dedicated-p window (cond ((eq dedicated t) t)
                                         ((window-parameter window 'window-side) 'side)))))

(defun my/aw-delete-window (window)
  "Close WINDOW, but not the only one (`aw-delete-window' closes the frame)."
  (if (frame-root-window-p window)
      (user-error "This is the only window")
    (delete-window window)))

(defun my/aw-delete-other-windows (window)
  "Keep only WINDOW, closing side windows (Claude, compilation) too."
  (when (window-parameter window 'window-side)
    ;; A side window can't be the only one: move its buffer to a regular window.
    (let ((main (seq-find (lambda (w) (not (window-parameter w 'window-side)))
                          (window-list (window-frame window) 'nomini))))
      (my/aw-put-window-state main (my/aw-window-state window))
      (set-window-dedicated-p main nil)  ; keep C-x b working there
      (setq window main)))
  (let ((ignore-window-parameters t))   ; close Claude too, unlike C-x 1
    (delete-other-windows window))
  (aw-switch-to-window window))

(defun my/aw-swap-window (window)
  "Swap buffers with WINDOW; the cursor follows the current buffer.
Unlike `aw-swap-window', works with the Claude window."
  (let* ((this (selected-window))
         (this-state (my/aw-window-state this)))
    (when (eq window this)
      (user-error "No other window to swap with"))
    (my/aw-put-window-state this (my/aw-window-state window))
    (my/aw-put-window-state window this-state)
    (aw-switch-to-window window)))

(defun my/aw-move-border (key n)
  "Move a border of the selected window N lines or columns toward KEY (w a s d).
The window grows that way, or shrinks if no window is there."
 (let* ((side (if (alist-get key my/aw-neighbors)
                   key
                 (alist-get key '((?w . ?s) (?s . ?w) (?a . ?d) (?d . ?a)))))
         (neighbor (alist-get side my/aw-neighbors))
         (horizontal (memq key '(?a ?d))))
    (if (not neighbor)
        (my/aw-notice (if horizontal "No window to the left or right" "No window above or below"))
      ;; Emacs moves bottom and right edges; a top or left edge is the neighbor's.
      ;; The dimming follows when the action is shown again.
      (adjust-window-trailing-edge (if (memq side '(?s ?d)) (selected-window) neighbor)
                                   (if (memq key '(?s ?d)) n (- n))
                                   horizontal))))

(defvar my/aw-scrolled nil
  "Windows `my/aw-fit-windows' scrolled: (WINDOW BUFFER START-BEFORE)...")

(defun my/aw-fit-windows ()
  "Keep point visible in windows the key list made shorter.
They scroll as little as possible, leaving point on the last line, and scroll
back once the list is gone."
  (dolist (window (window-list nil 'nomini))
    (let ((old (assq window my/aw-scrolled)))
      (when old
        (if (eq (nth 1 old) (window-buffer window))
            (set-window-start window (nth 2 old) t)
          (setq my/aw-scrolled (delq old my/aw-scrolled)
                old nil)))
      (cond ((pos-visible-in-window-p (window-point window) window)
             (setq my/aw-scrolled (delq old my/aw-scrolled)))
            (t
             (unless old
               (push (list window (window-buffer window) (window-start window)) my/aw-scrolled))
             (with-selected-window window
               (recenter -1)))))))

(defun my/aw-redim ()
  "Stretch the `ace-window' dimming over what the windows show now.
ace-window measures it by the last redisplay, which is stale after a border
move, a swap or a change in the key list's height."
  (cl-mapc (lambda (overlay window)
             (when (eq (overlay-buffer overlay) (window-buffer window))
               (move-overlay overlay (window-start window) (window-end window t))))
           aw-overlays-back my/aw-windows))

;;;; Numbers and the key list
(defun my/aw-action ()
  "Return the name and face of the pending `ace-window' action."
  (pcase-let ((`(,name ,face)
               (or (alist-get (or aw-action 'aw-switch-to-window) my/aw-actions)
                   ;; Other stock actions: their own description.
                   (list (string-remove-prefix " Ace - " (or ace-window-mode "")) 'success))))
    (list name (list 'bold face))))

(defun my/aw-label (fn wnd pos path)
  "Color WND's `ace-window' number like the action and add its w/a/s/d key.
FN, POS and PATH are those of `aw--overlay-str'."
  (let* ((label (funcall fn wnd pos path))
         (face (nth 1 (my/aw-action)))
         (key (car (rassq wnd my/aw-neighbors)))
         (extra (if key
                    (concat (propertize "(" 'face 'shadow)
                            (propertize (string key) 'face face)
                            (propertize ")" 'face 'shadow))
                  ""))
         (padding (substring label 1))
         ;; Use up padding spaces, if any, so the line shifts less.
         (spaces (- (length padding) (length (string-trim-left padding " +")))))
    (concat (propertize (substring label 0 1) 'face face)
            extra
            (substring padding (min spaces (length extra))))))

(defvar my/aw-message nil
  "The action message `my/aw-echo-action' showed last.")

(defvar my/aw-hints t
  "Non-nil means `my/ace-window' lists its keys; ? toggles it.")

(defun my/aw-hint-columns ()
  "Return the keys `ace-window' accepts now: columns (TITLE (KEY TEXT DIM)...)."
  (let* ((several (cdr my/aw-windows))
         (name (lambda (window)
                 (truncate-string-to-width (buffer-name (window-buffer window)) 24 nil nil "…")))
         (arrows (lambda (shift)
                   (mapcar (pcase-lambda (`(,key ,dir))
                             (list (if (char-displayable-p ?↑)
                                       (concat shift (alist-get dir '((?w . "↑") (?a . "←")
                                                                      (?s . "↓") (?d . "→"))))
                                     (key-description (vector key)))
                                   (string-remove-prefix "S-" (symbol-name key))))
                           (seq-filter (lambda (arrow) (eq (nth 2 arrow) (if shift 3 1)))
                                       my/aw-arrows))))
         (windows
          (when several
            (list (cons "Neighbor"
                        (mapcar (lambda (dir)
                                  (let ((window (alist-get (car dir) my/aw-neighbors)))
                                    (list (string (car dir))
                                          (if window (funcall name window) "—")
                                          t)))          ; never the current window
                                my/aw-directions))
                  (cons "Window"
                        (cl-mapcar (lambda (key window)
                                     (list (string key) (funcall name window)
                                           (not (eq window (selected-window)))))
                                   aw-keys my/aw-windows))))))
    (append
     windows
     (pcase aw-action
       ((or 'nil 'aw-switch-to-window)
        (append
         (when several
           `(("Action" ("k" "close window…") ("K" "close other windows…")
              ("m" ,(if (cddr my/aw-windows) "swap windows…" "swap windows")))))
         (list (cons "Split" (mapcar (lambda (dir) (list (string (upcase (car dir))) (nth 2 dir)))
                                     my/aw-directions)))
         (when several
           (list (cons "Border" (funcall arrows ""))
                 (cons "Border ×3" (funcall arrows "S-"))))
         '(("Menu" ("M-key" "stay after it") ("C-g" "exit") ("?" "hide keys")))))
       ('my/aw-delete-window '(("Current" ("k" "this window"))))
       ('my/aw-delete-other-windows '(("Current" ("K" "this window")))))
     (unless (memq aw-action '(nil aw-switch-to-window))
       '(("Menu" ("M-key" "stay after it") ("C-b" "back") ("C-g" "exit") ("?" "hide keys")))))))

(defun my/aw-hints-text (columns width)
  "Lay out COLUMNS from `my/aw-hint-columns' side by side, wrapping at WIDTH."
  (let* ((gap 4)
         (cells
          (mapcar
           (pcase-lambda (`(,title . ,rows))
             (let* ((key-width (apply #'max (mapcar (lambda (row) (string-width (car row))) rows)))
                    (lines (cons (propertize title 'face '(bold which-key-note-face))
                                 (mapcar (pcase-lambda (`(,key ,text ,dim))
                                           (concat (propertize (string-pad key key-width)
                                                               'face 'which-key-key-face)
                                                   (propertize which-key-separator
                                                               'face 'which-key-separator-face)
                                                   (propertize text 'face
                                                               (if dim 'shadow
                                                                 'which-key-command-description-face))))
                                         rows))))
               (cons (apply #'max (mapcar #'string-width lines)) lines)))
           columns))
         blocks block (used 0))
    ;; Columns that don't fit WIDTH go to the next block.
    (dolist (cell cells)
      (when (and block (> (+ used (car cell)) width))
        (push (nreverse block) blocks)
        (setq block nil used 0))
      (push cell block)
      (setq used (+ used (car cell) gap)))
    (push (nreverse block) blocks)
    (mapconcat
     (lambda (block)
       (mapconcat
        (lambda (row)
          (string-trim-right
           (concat " " (mapconcat (pcase-lambda (`(,cell-width . ,lines))
                                    (string-pad (or (nth row lines) "") cell-width))
                                  block (make-string gap ?\s)))))
        (number-sequence 0 (1- (apply #'max (mapcar (lambda (cell) (length (cdr cell))) block))))
        "\n"))
     (nreverse blocks) "\n\n")))

;;;; Echo area
(defvar my/aw-notice nil
  "A short error shown next to the `ace-window' action.")

(defvar my/aw-notice-timer nil
  "Timer that clears the variable `my/aw-notice'.")

(defun my/aw-notice (format-string &rest args)
  "Show FORMAT-STRING with ARGS next to the `ace-window' action for two seconds.
Unlike an error, it doesn't end `my/ace-window'."
  (setq my/aw-notice (apply #'format format-string args))
  (when my/aw-notice-timer
    (cancel-timer my/aw-notice-timer))
  (setq my/aw-notice-timer
        (run-with-timer 2 nil (lambda ()
                                (setq my/aw-notice nil)
                                (when ace-window-mode
                                  (my/aw-echo-action))))))

(defun my/aw-say (text)
  "Show TEXT in the echo area, or clear it when TEXT is nil; return TEXT.
The echo area takes its new height at once, but nothing is drawn until the next
redisplay: the windows can be scrolled and dimmed to fit first, so the frame
changes in one go instead of jumping twice."
  (let* ((mini (minibuffer-window))
         (width (window-max-chars-per-line mini))
         (lines (if text
                    (apply #'+ (mapcar (lambda (line) (max 1 (ceiling (string-width line) width)))
                                       (split-string text "\n")))
                  1))
         (limit (if (floatp max-mini-window-height)
                    (floor (* max-mini-window-height (frame-height)))
                  max-mini-window-height)))
    ;; With redisplay held back, `message' would resize it only when drawing.
    ;; (`window-resize' keeps the other windows big enough by itself.)
    (window-resize mini (- (max 1 (min lines limit)) (window-total-height mini)))
    (let ((message-log-max nil)         ; keep it out of *Messages*
          (inhibit-message nil)         ; see `my/ace-window'
          (inhibit-redisplay t))
      (if text (message "%s" text) (message nil)))))

(defun my/aw-echo-action ()
  "Show the pending `ace-window' action in the echo area, the key list above it.
The list is drawn here in which-key's colors: which-key's own popup can't keep
each group of keys in a column, and it would cover the bottom window."
  (pcase-let ((`(,name ,face) (my/aw-action)))
    (setq my/aw-message
          (my/aw-say (concat (when my/aw-hints
                               (concat (my/aw-hints-text (my/aw-hint-columns)
                                                         (1- (frame-width)))
                                       "\n\n"))
                             (propertize "M-o ›" 'face 'shadow) " "
                             (propertize name 'face face)
                             (when my/aw-notice
                               (concat (propertize "  · " 'face 'shadow) my/aw-notice))))))
  ;; The key list or the last command may have resized or refilled the windows.
  (my/aw-fit-windows)
  (my/aw-redim))

(defun my/aw-show-state (text)
  "Show the `ace-window' action and keys; clear them when TEXT is nil.
TEXT is the `ace-window' mode line text."
  ;; A new mode or the end of M-o makes the last error stale.
  (when my/aw-notice-timer
    (cancel-timer my/aw-notice-timer))
  (setq my/aw-notice nil)
  (cond (text (my/aw-echo-action))
        ;; `my/ace-window' keeps the list up between its rounds.
        ((not my/aw-active) (my/aw-clear))))

(defun my/aw-clear ()
  "Clear the `ace-window' action and keys from the echo area."
  ;; Reading the last key emptied the echo area but left the list on screen
  ;; (see `my/ace-window'): clear it, unless another message is up.
  (when (member (current-message) (list nil my/aw-message))
    (my/aw-say nil)))

;;;; Terminal freeze
;; While M-o runs, terminals (Claude) don't repaint, resize or scroll to their
;; bottom line in a window they were swapped into: that would wipe or misplace the
;; numbers and dimming, and resizing a running TUI is slow. They catch up once M-o
;; is done.
(defvar my/aw-postponed nil
  "Terminal updates postponed until `my/ace-window' is done.")

(defun my/aw-postpone (fn &rest args)
  "Call FN with ARGS, or postpone the call while `my/ace-window' is active."
  (if my/aw-active
      (push (cons (current-buffer) (cons fn args)) my/aw-postponed)
    (apply fn args)))

(defun my/aw-catch-up ()
  "Run the terminal updates postponed by `my/aw-postpone'."
  (let ((calls (delete-dups (nreverse my/aw-postponed))))
    (setq my/aw-postponed nil)
    (pcase-dolist (`(,buffer ,fn . ,args) calls)
      ;; Skip resizes of windows closed meanwhile.
      (unless (seq-some (lambda (arg) (and (windowp arg) (not (window-live-p arg)))) args)
        ;; Some of them check which buffer is current.
        (with-current-buffer (if (buffer-live-p buffer) buffer (current-buffer))
          (apply fn args))))))

;; ghostel internals: if an update renames them, terminals just stop freezing.
(with-eval-after-load 'ghostel
  (advice-add 'ghostel--redraw-now :around #'my/aw-postpone)
  (advice-add 'ghostel--adjust-size :around #'my/aw-postpone)
  (advice-add 'ghostel--window-buffer-change :around #'my/aw-postpone))

;;;; Key handling
;; A command pressed with Meta ends only this round of M-o: the next round starts
;; in the mode the key was pressed in, with fresh numbers and neighbors.
(defvar my/aw-next nil
  "Mode of the next round of `my/ace-window', or nil to end it.
The symbol `then' means the mode in `my/aw-then'.")

(defvar my/aw-then nil
  "Mode `my/ace-window' comes back to after the current mode's action, or nil.
Pressing k, K or m with Meta sets it to the main mode.")

(defun my/aw-done (result stay)
  "End this round of `my/ace-window' with RESULT for `aw-select'.
STAY non-nil (the key was pressed with Meta) starts the next round in this mode."
  (when stay
    (setq my/aw-next aw-action))
  (throw 'done result))

(defun my/aw-handle (event)
  "Do what EVENT means in the current `ace-window' mode, or show why it can't.
The main mode takes every key; k, K, m and other actions take only a window
\(number or w a s d), their own key for the current window, back, ? and quit.
With Meta a command brings `my/ace-window' back afterwards; other keys
ignore Meta."
  (let* ((stay (memq 'meta (event-modifiers event)))
         (char (cond ((not stay) event)
                     ((integerp event) (logand event (lognot ?\M-\0)))
                     ((symbolp event)     ; M-<up> works as <up>
                      (event-convert-list (append (remq 'meta (event-modifiers event))
                                                  (list (event-basic-type event)))))
                     (t event)))
         (char (alist-get char my/aw-russian-keys char))
         (name (key-description (vector event)))
         (dir (and (characterp char) (assq (downcase char) my/aw-directions)))
         (arrow (assq char my/aw-arrows))
         (main (memq aw-action '(nil aw-switch-to-window))))
    (cond
     ((memq char '(?\C-g ?\e escape))
      (setq my/aw-next nil)
      (throw 'done 'exit))
     ((eq char ??)                       ; show or hide the key list
      (setq my/aw-hints (not my/aw-hints)))
     ((eq char ?\C-b)                    ; back to the main mode
      (if main
          (my/aw-notice "Nothing to go back to")
        (setq aw-action #'aw-switch-to-window
              my/aw-then nil)
        (aw-set-mode-line " Ace - Window")))
     ;; w a s d: the neighbor window, as if its number was pressed.
     ((and dir (eq char (car dir)))
      (if-let* ((window (alist-get char my/aw-neighbors)))
          (my/aw-done (cons char window) stay)
        (my/aw-notice "No window %s" (nth 2 dir))))
     ;; Numbers reach here with Meta, or when there is no such window.
     ((memq char aw-keys)
      (if-let* ((window (and stay (nth (seq-position aw-keys char) my/aw-windows))))
          (my/aw-done (cons char window) stay)
        (my/aw-notice "No window %c" char)))
     ((not main)
      (if (and (memq char '(?k ?K)) (eq aw-action (nth 1 (assq char aw-dispatch-alist))))
          (my/aw-done (cons char (selected-window)) stay) ; k k, K K: the current window
        (my/aw-notice "%s does nothing here, C-b goes back" name)))
     (dir                                ; W A S D
      (select-window (split-window nil nil (nth 1 dir)))
      (my/aw-done 'exit stay))
     (arrow
      (my/aw-move-border (nth 1 arrow) (nth 2 arrow)))
     ((and (memq char '(?k ?K ?m)) (not (cdr my/aw-windows)))
      (my/aw-notice "Only one window"))
     ((assq char aw-dispatch-alist)      ; k, K, m and the stock actions
      ;; With Meta, come back to the main mode once the action is done.
      (setq my/aw-then (and stay #'aw-switch-to-window))
      (if (and (eq char ?m) (= (length my/aw-windows) 2))
          (progn (setq aw-action #'my/aw-swap-window) ; two windows: swap at once
                 (throw 'done (cons char (car (remq (selected-window) my/aw-windows)))))
        (aw-dispatch-default char)))
     (t
      (my/aw-notice "%s does nothing here" name)))))

(defun my/aw-dispatch (event)
  "Handle EVENT pressed in `ace-window' instead of a window number."
  (my/aw-handle event)
  ;; M-o goes on, but typing cleared the echo area: show the action again.
  (my/aw-echo-action))

(defun my/aw-round (action)
  "Run one round of `my/ace-window': wait for a command in ACTION's mode, do it."
  (let ((my/aw-windows (aw-window-list)))
    (unless (cdr my/aw-windows)
      ;; k, K, m and the like need two windows.
      (setq action #'aw-switch-to-window
            my/aw-then nil))
    (let ((my/aw-neighbors (seq-keep (lambda (dir)
                                       (when-let* ((window (my/aw-neighbor (nth 1 dir))))
                                         (cons (car dir) window)))
                                     my/aw-directions)))
      (if (cdr my/aw-windows)
          (progn
            (setq avy-current-path "")
            (aw-select (format " Ace - %s"
                               (or (nth 2 (seq-find (lambda (entry) (eq (nth 1 entry) action))
                                                    aw-dispatch-alist))
                                   "Window"))
                       action))
        ;; With one window ace-window reads a single key with `read-char', which
        ;; fails on arrows: read keys here until one finishes the round.
        (setq aw-action action)
        (aw-set-mode-line " Ace - Window")
        (let ((result (unwind-protect
                          (catch 'done
                            (while t
                              (my/aw-dispatch (read-key))
                              ;; An action that waits for a window takes this one.
                              (unless (memq aw-action '(nil aw-switch-to-window))
                                (throw 'done (selected-window)))))
                        (aw-set-mode-line nil))))
          (when (consp result)
            (setq result (cdr result)))
          (when (windowp result)
            (funcall aw-action result)))))))

(defun my/ace-window ()
  "Run `ace-window' with the extra keys described above."
  (interactive)
  (let ((my/aw-next #'aw-switch-to-window)
        (my/aw-then nil)
        (my/aw-scrolled nil))
    (unwind-protect
        ;; `read-key' ends with (message nil), which redraws the frame with an empty
        ;; echo area after every key, so the key list flickered. Hold messages back
        ;; while M-o runs; `my/aw-echo-action' shows its own anyway. The echo area
        ;; fits the list exactly, so hiding it with ? gives the lines back.
        (let ((inhibit-message t)
              (resize-mini-windows t)
              (my/aw-active t))
          (while my/aw-next
            (let ((action my/aw-next))
              (setq my/aw-next 'then)   ; unless a key decides otherwise
              (my/aw-round action))
            (when (eq my/aw-next 'then)
              (setq my/aw-next my/aw-then
                    my/aw-then nil))))
      ;; Scroll back what the key list scrolled, and let the echo area shrink back
      ;; first, so terminals resize only once.
      (my/aw-clear)
      (my/aw-fit-windows)
      (redisplay t)
      (my/aw-catch-up))))

;;;; Setup
;; Windows are numbered 1-9. Numbers show even with two windows, so M-o always
;; waits for a command.
(setopt aw-keys '(?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9)
        aw-dispatch-always t)
(setq aw-dispatch-function #'my/aw-dispatch)
;; k, K and m wait for a window. They replace the stock x, o and m.
(setq aw-dispatch-alist
      (append '((?k my/aw-delete-window "Delete Window")
                (?K my/aw-delete-other-windows "Delete Other Windows")
                (?m my/aw-swap-window "Swap Windows"))
              (seq-remove (lambda (action) (memq (car action) '(?x ?o ?k ?K ?m)))
                          aw-dispatch-alist)))
(advice-add 'aw-set-mode-line :after #'my/aw-show-state)
(advice-add 'aw--overlay-str :around #'my/aw-label)

(provide 'my-ace-window)
;;; my-ace-window.el ends here
