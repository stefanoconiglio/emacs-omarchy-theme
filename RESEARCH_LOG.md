# Research log

Dated entries: what was asked, tried, found and decided, mistakes included. Times from `date`.
Entries before 19:57 on 2026-10-01 were written in a local repository (`~/repos/emacs-config`)
and moved here; personal details were removed, findings kept.

## 2026-10-01 11:51 CEST — Emacs and the PDF follow the Omarchy theme

**Request (user).** After switching Omarchy to a dark theme: make Emacs, and the PDF shown in
pdf-tools, change theme too.

**Found.** Omarchy's current theme is in `~/.local/state/omarchy/current/` (`theme/colors.toml`,
`theme.name`); `omarchy-theme-color --file … mode` gives light/dark. The user's
`~/.config/omarchy/hooks/theme-set` calls `omarchy-theme-set-emacs`, which does not exist on this
system (output discarded): Emacs never followed the theme.

**What was done.** `omarchy-follow.el` (DESIGN.md): Modus Vivendi/Operandi with palette
overrides from the Omarchy palette; `pdf-view-themed-minor-mode` in dark themes; a `file-notify`
watch on the state directory. texsync's `try.el` turns it on when it is on the load path. The
Omarchy configuration was not changed.

**Results.** `make test` 3 / 3. Headless apply on the real state: the theme had become
Catppuccin Latte (light) → `modus-operandi`, bg #eff1f5, fg #4c4f69, keyword #1e66f5.

**Mistake.** File-notify events reach batch Emacs only through `read-event` (they are input
events); the first version of the test waited with `accept-process-output` and saw none.

**Open.** Not yet seen on screen. In a dark theme pictures in PDFs are tinted too.

## 2026-10-01 12:10 CEST — Kept out of texsync

**Decision (user).** texsync goes public on GitHub on its own; the Omarchy theme code is not part
of it. It moved to a separate local repository, `~/repos/emacs-config`, meant for the user's
Emacs settings; whether to publish that was left open.

## 2026-10-01 14:23 CEST — texsync and omarchy-follow in the user's init.el

**Request (user).** `C-c C-c View` in plain Emacs opened Zathura: `emacs` is the terminal
wrapper (`emacs-tui-default/`), and the init file had no texsync. The user asked to add it.

**Done.** Backup `~/.emacs.d/init.el.bak-20261001-142242`. In the live init file (the target of
the `~/.emacs.d/init.el` link): a TEXSYNC block after the `build/` settings puts texsync and this
package on the load path, turns `texsync-mode` on in LaTeX buffers of graphical frames only,
and `omarchy-follow-mode` in a graphical session; the pdf-tools midnight hook (white on black)
now runs only when omarchy-follow is off.

**Checked (headless).** All 68 forms parse. Full init in batch (as terminal Emacs): texsync
loaded, off; viewer still Zathura. With `display-graphic-p` forced true: omarchy-follow on
(modus-vivendi), texsync on, viewer `texsync`. "Error enabling Flyspell mode" appears in batch
with the old init file too (pre-existing, batch only).

## 2026-10-01 14:29 CEST — The PDF kept the dark colours after a switch to a light theme

**Report (user, screenshot).** After `omarchy theme set` from Retro Fallout to Catppuccin
Latte, Emacs turned light but the PDF stayed green on black.

**Cause (from pdf-tools' code).** `pdf-view-refresh-themed-buffer` (called when themed mode
is turned on, off, or refreshed) ends with `(pdf-view-redisplay t)`; in roll mode that is
`(pdf-roll-redisplay t)`, which replaces a non-window by `(selected-window)` — the source
window — finds no page overlays there and does nothing. The pages already drawn stay as they
were until scrolled away.

**Fix.** `omarchy-follow--refresh-pdfs` calls `pdf-view-redisplay` on every window showing
the PDF after the change. Compiles; `make test` 3 / 3 (does not cover it: no PDF windows in
batch). Not yet confirmed on screen. A report to pdf-tools would fix it for everyone (open).

## 2026-10-01 19:57 CEST — Moved into omarchy-customizations

**Decision (user).** The package belongs in `omarchy-customizations` (public), with a README and
an AGENTS.md complete enough to resume work from them.

**Done.** `emacs-omarchy-theme/` holds the package, its tests, Makefile, README.md, DESIGN.md,
this log and AGENTS.md. The directory name says what it does; the package keeps its name
(`omarchy-follow`), which the init file uses. The live init file's TEXSYNC block now loads it from
here, and `home/.emacs.d/init.el` mirrors that block. `~/repos/emacs-config` (local only, three
commits, superseded) is left in place for the user to delete. `make test` 3 / 3 in the new place.

## 2026-10-01 20:06 CEST — Old local repository deleted

**Decision (user).** Delete `~/repos/emacs-config` once everything is here. Checked first: the
code differs only in its header comment, the test and Makefile are identical, the documents
were carried over (personal details removed), nothing loads from the old path. Not carried over:
its three local commits. Deleted.
