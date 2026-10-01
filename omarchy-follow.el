;;; omarchy-follow.el --- Emacs and pdf-tools follow the Omarchy theme  -*- lexical-binding: t -*-

;; Author: Stefano Coniglio
;; Version: 0.1
;; Package-Requires: ((emacs "30.1"))
;; URL: https://github.com/stefanoconiglio/omarchy-customizations/tree/master/emacs-omarchy-theme
;; Keywords: faces

;;; Commentary:

;; `omarchy-follow-mode' gives graphical Emacs the colours of the current
;; Omarchy theme and changes them when `omarchy theme set' does:
;;
;; - the built-in Modus theme, Vivendi for a dark Omarchy theme and
;;   Operandi for a light one, with its palette overridden by the Omarchy
;;   palette (background, foreground, accent, selection, color0..15);
;; - PDFs in pdf-tools take the theme's colours in a dark theme
;;   (`pdf-view-themed-minor-mode') and their own colours in a light one.
;;
;; The theme is read from Omarchy's state directory; light or dark comes from
;; `omarchy-theme-color', which Omarchy's own per-app scripts use.  A file
;; watch on `theme.name' notices a theme change.  DESIGN.md has the
;; details; AGENTS.md says how to work on it.

;;; Code:

(require 'cl-lib)
(require 'filenotify)

(defgroup omarchy-follow nil
  "Emacs and pdf-tools follow the Omarchy theme."
  :group 'faces
  :prefix "omarchy-follow-")

(defcustom omarchy-follow-state-dir "~/.local/state/omarchy/current"
  "Omarchy's directory of the current theme: `theme/colors.toml', `theme.name'."
  :type 'directory)

(defcustom omarchy-follow-pdf t
  "Non-nil: PDFs take the theme's colours in a dark theme."
  :type 'boolean)

(defvar modus-vivendi-palette-overrides)
(defvar modus-operandi-palette-overrides)
(defvar pdf-view-themed-minor-mode)
(defvar pdf-view-roll-minor-mode)
(declare-function pdf-view-redisplay "pdf-view")
(declare-function pdf-view-refresh-themed-buffer "pdf-view")
(declare-function pdf-view-themed-minor-mode "pdf-view")

(defvar omarchy-follow--watch nil)
(defvar omarchy-follow--timer nil)
(defvar omarchy-follow--applied nil
  "The colours last applied, as returned by `omarchy-follow-colors'.")

;;;; Reading the theme

(defun omarchy-follow--colors-file ()
  (expand-file-name "theme/colors.toml" omarchy-follow-state-dir))

(defun omarchy-follow--parse-toml (file)
  "Alist (KEY . VALUE) of the `key = \"value\"' lines of FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let (pairs)
      (while (re-search-forward
              "^[ \t]*\\([A-Za-z0-9_-]+\\)[ \t]*=[ \t]*\"\\([^\"]*\\)\"" nil t)
        (push (cons (match-string 1) (match-string 2)) pairs))
      (nreverse pairs))))

(defun omarchy-follow--luminance (hex)
  "Relative luminance of colour HEX, 0 (black) to 1 (white)."
  (pcase-let ((`(,r ,g ,b) (omarchy-follow--rgb hex)))
    (+ (* 0.2126 r) (* 0.7152 g) (* 0.0722 b))))

(defun omarchy-follow--mode (file pairs)
  "\"light\" or \"dark\" for the theme of FILE with PAIRS.
As Omarchy decides it: `omarchy-theme-color' when it is installed;
otherwise a `mode' key, a legacy light.mode file beside FILE, or the
background's luminance."
  (or (when (executable-find "omarchy-theme-color")
        (let ((out (string-trim
                    (with-output-to-string
                      (call-process "omarchy-theme-color" nil standard-output nil
                                    "--file" file "mode")))))
          (and (member out '("light" "dark")) out)))
      (cdr (assoc "mode" pairs))
      (and (file-exists-p (expand-file-name "light.mode" (file-name-directory file)))
           "light")
      (let ((bg (cdr (assoc "background" pairs))))
        (if (and bg (> (omarchy-follow--luminance bg) 0.5)) "light" "dark"))))

(defun omarchy-follow-colors ()
  "The current Omarchy theme as an alist; `mode' is \"light\" or \"dark\".
nil when Omarchy's state directory has no theme."
  (let ((file (omarchy-follow--colors-file)))
    (when (file-readable-p file)
      (let ((pairs (omarchy-follow--parse-toml file)))
        (cons (cons "mode" (omarchy-follow--mode file pairs))
              (assoc-delete-all "mode" pairs))))))

;;;; Colours

(defun omarchy-follow--rgb (hex)
  "HEX (#rrggbb) as a list of three numbers from 0 to 1."
  (mapcar (lambda (i) (/ (string-to-number (substring hex i (+ i 2)) 16) 255.0))
          '(1 3 5)))

(defun omarchy-follow--blend (a b f)
  "Colour A moved a fraction F towards colour B, as #rrggbb."
  (apply #'format "#%02x%02x%02x"
         (cl-mapcar (lambda (x y) (round (* 255 (+ x (* f (- y x))))))
                    (omarchy-follow--rgb a) (omarchy-follow--rgb b))))

(defun omarchy-follow-overrides (colors)
  "Modus palette overrides that give a Modus theme the Omarchy COLORS."
  (let* ((c (lambda (k &optional default)
              (or (cdr (assoc k colors)) default)))
         (bg (funcall c "background" "#000000"))
         (fg (funcall c "foreground" "#ffffff"))
         (accent (funcall c "accent" fg))
         (selection (funcall c "selection" accent))
         (dim (omarchy-follow--blend fg bg 0.4))
         (n (lambda (i fallback) (funcall c (format "color%d" i) fallback))))
    `((bg-main ,bg)
      (fg-main ,fg)
      (bg-dim ,(omarchy-follow--blend bg fg 0.06))
      (fg-dim ,dim)
      (bg-active ,(omarchy-follow--blend bg fg 0.18))
      (bg-inactive ,(omarchy-follow--blend bg fg 0.09))
      (border ,(omarchy-follow--blend bg fg 0.3))
      (bg-hl-line ,(omarchy-follow--blend bg fg 0.08))
      (bg-region ,(omarchy-follow--blend bg selection 0.35))
      (fg-region ,fg)
      (bg-mode-line-active ,(omarchy-follow--blend bg accent 0.35))
      (fg-mode-line-active ,fg)
      (bg-mode-line-inactive ,(omarchy-follow--blend bg fg 0.08))
      (fg-mode-line-inactive ,dim)
      (bg-paren-match ,(omarchy-follow--blend bg accent 0.5))
      (cursor ,(funcall c "cursor" fg))
      (err ,(funcall n 1 "#ff5555"))
      (warning ,(funcall n 3 accent))
      (string ,(funcall n 2 fg))
      (docstring ,(funcall n 2 fg))
      (constant ,(funcall n 4 accent))
      (keyword ,(funcall n 5 accent))
      (type ,(funcall n 6 accent))
      (builtin ,(funcall n 13 accent))
      (variable ,(funcall n 14 fg))
      (fnname ,accent)
      (comment ,dim)
      (fg-heading-1 ,accent))))

;;;; Applying

(defun omarchy-follow--base-theme (mode)
  (if (equal mode "light") 'modus-operandi 'modus-vivendi))

(defun omarchy-follow--refresh-pdfs (dark)
  "Give pdf-tools buffers the theme's colours when DARK, their own otherwise."
  (when (fboundp 'pdf-view-themed-minor-mode)
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (derived-mode-p 'pdf-view-mode)
          (if (and dark omarchy-follow-pdf)
              (if (bound-and-true-p pdf-view-themed-minor-mode)
                  (pdf-view-refresh-themed-buffer t) ; new colours
                (pdf-view-themed-minor-mode 1))
            (when (bound-and-true-p pdf-view-themed-minor-mode)
              (pdf-view-themed-minor-mode -1)))
          ;; Both refresh the PDF by redisplaying "all windows" (t), which in
          ;; continuous mode (pdf-roll) means only the selected window, not
          ;; the PDF's: the pages already drawn kept the old colours.
          (when (bound-and-true-p pdf-view-roll-minor-mode)
            (dolist (w (get-buffer-window-list buf nil t))
              (pdf-view-redisplay w))))))))

(defun omarchy-follow--pdf-hook ()
  "In a new PDF buffer, the colours of the theme applied."
  (when (and omarchy-follow-pdf
             (equal (cdr (assoc "mode" omarchy-follow--applied)) "dark")
             (fboundp 'pdf-view-themed-minor-mode))
    (pdf-view-themed-minor-mode 1)))

(defun omarchy-follow-apply ()
  "Give Emacs, and PDFs in pdf-tools, the colours of the Omarchy theme."
  (interactive)
  (when-let* ((colors (omarchy-follow-colors)))
    (let* ((mode (cdr (assoc "mode" colors)))
           (theme (omarchy-follow--base-theme mode))
           (overrides (omarchy-follow-overrides colors)))
      (setq modus-vivendi-palette-overrides overrides
            modus-operandi-palette-overrides overrides)
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t)
      (setq omarchy-follow--applied colors)
      (omarchy-follow--refresh-pdfs (equal mode "dark"))
      (message "Omarchy theme: %s (%s)"
               (or (ignore-errors
                     (string-trim (with-temp-buffer
                                    (insert-file-contents
                                     (expand-file-name "theme.name" omarchy-follow-state-dir))
                                    (buffer-string))))
                   "?")
               mode))))

(defun omarchy-follow--changed (event)
  "A file in Omarchy's state directory changed: re-apply soon (debounced)."
  (when (string-match-p "theme" (file-name-nondirectory (nth 2 event)))
    (when (timerp omarchy-follow--timer) (cancel-timer omarchy-follow--timer))
    ;; `omarchy theme set' swaps the theme directory and then writes
    ;; theme.name; wait until it is done.
    (setq omarchy-follow--timer (run-with-timer 0.5 nil #'omarchy-follow-apply))))

;;;###autoload
(define-minor-mode omarchy-follow-mode
  "Emacs and pdf-tools follow the Omarchy theme, now and when it changes."
  :global t
  (when omarchy-follow--watch
    (file-notify-rm-watch omarchy-follow--watch)
    (setq omarchy-follow--watch nil))
  (remove-hook 'pdf-view-mode-hook #'omarchy-follow--pdf-hook)
  (when omarchy-follow-mode
    (omarchy-follow-apply)
    (add-hook 'pdf-view-mode-hook #'omarchy-follow--pdf-hook)
    (let ((dir (expand-file-name omarchy-follow-state-dir)))
      (when (file-directory-p dir)
        (setq omarchy-follow--watch
              (file-notify-add-watch dir '(change) #'omarchy-follow--changed))))))

(provide 'omarchy-follow)
;;; omarchy-follow.el ends here
