;;; omarchy-follow-test.el --- Tests for omarchy-follow  -*- lexical-binding: t -*-

;; Run with `make test'.  A temporary directory stands in for Omarchy's
;; state directory; nothing of the real theme is changed.

;;; Code:

(require 'ert)
(require 'omarchy-follow)
(require-theme 'modus-themes)

(defconst omarchy-follow-test--dark
  "accent = \"#6ebf5d\"\nselection = \"#95ff80\"\nbackground = \"#0a0f09\"\nforeground = \"#95ff80\"\ncolor1 = \"#ff5555\"\ncolor2 = \"#95ff80\"\ncolor5 = \"#7bcf6b\"\n"
  "Retro Fallout's colours, in part.")

(defconst omarchy-follow-test--light
  "accent = \"#1e66f5\"\nbackground = \"#eff1f5\"\nforeground = \"#4c4f69\"\ncolor1 = \"#d20f39\"\n"
  "Catppuccin Latte's colours, in part: no `mode' key, light by luminance.")

(defun omarchy-follow-test--state (colors name)
  "A state directory with COLORS as theme/colors.toml and NAME in theme.name."
  (let ((dir (make-temp-file "omarchy-state-" t)))
    (make-directory (expand-file-name "theme" dir))
    (with-temp-file (expand-file-name "theme/colors.toml" dir) (insert colors))
    (with-temp-file (expand-file-name "theme.name" dir) (insert name "\n"))
    dir))

(ert-deftest omarchy-follow-test-colors-and-mode ()
  (dolist (tool '(t nil))
    ;; with `omarchy-theme-color' when installed, and without it
    (let ((exec-path (if tool exec-path nil)))
      (let ((omarchy-follow-state-dir (omarchy-follow-test--state omarchy-follow-test--dark "retro-fallout")))
        (should (equal (cdr (assoc "mode" (omarchy-follow-colors))) "dark"))
        (should (equal (cdr (assoc "background" (omarchy-follow-colors))) "#0a0f09")))
      (let ((omarchy-follow-state-dir (omarchy-follow-test--state omarchy-follow-test--light "catppuccin-latte")))
        (should (equal (list tool (cdr (assoc "mode" (omarchy-follow-colors)))) (list tool "light"))))
      (let ((omarchy-follow-state-dir (omarchy-follow-test--state
                                       (concat "mode = \"light\"\n" omarchy-follow-test--dark) "x")))
        (should (equal (list tool (cdr (assoc "mode" (omarchy-follow-colors)))) (list tool "light"))))))
  (let ((omarchy-follow-state-dir "/nonexistent"))
    (should (null (omarchy-follow-colors)))))

(ert-deftest omarchy-follow-test-blend ()
  (should (equal (omarchy-follow--blend "#000000" "#ffffff" 0.5) "#808080"))
  (should (equal (omarchy-follow--blend "#0a0f09" "#95ff80" 0) "#0a0f09"))
  (should (equal (omarchy-follow--blend "#0a0f09" "#95ff80" 1) "#95ff80")))

(ert-deftest omarchy-follow-test-apply-and-follow ()
  "A dark theme loads Vivendi with its colours; a change to a light one is followed."
  (let ((omarchy-follow-state-dir (omarchy-follow-test--state omarchy-follow-test--dark "retro-fallout")))
    (unwind-protect
        (progn
          (omarchy-follow-mode 1)
          (should (custom-theme-enabled-p 'modus-vivendi))
          (should (equal (modus-themes-get-color-value 'bg-main t 'modus-vivendi) "#0a0f09"))
          (should (equal (modus-themes-get-color-value 'fg-main t 'modus-vivendi) "#95ff80"))
          (should (equal (modus-themes-get-color-value 'keyword t 'modus-vivendi) "#7bcf6b"))
          ;; `omarchy theme set' to a light theme
          (with-temp-file (expand-file-name "theme/colors.toml" omarchy-follow-state-dir)
            (insert omarchy-follow-test--light))
          (with-temp-file (expand-file-name "theme.name" omarchy-follow-state-dir)
            (insert "catppuccin-latte\n"))
          ;; File events come through the input queue: `read-event' handles
          ;; them (and timers), as the command loop does in a session.
          (let ((end (+ (float-time) 5)))
            (while (and (not (custom-theme-enabled-p 'modus-operandi)) (< (float-time) end))
              (read-event nil nil 0.1)))
          (should (custom-theme-enabled-p 'modus-operandi))
          (should-not (custom-theme-enabled-p 'modus-vivendi))
          (should (equal (modus-themes-get-color-value 'bg-main t 'modus-operandi) "#eff1f5")))
      (omarchy-follow-mode -1)
      (mapc #'disable-theme custom-enabled-themes))))

(provide 'omarchy-follow-test)
;;; omarchy-follow-test.el ends here
