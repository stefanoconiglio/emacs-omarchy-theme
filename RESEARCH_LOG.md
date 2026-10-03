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

## 2026-10-01 20:18 CEST — Emacs (Client) never turned the mode on

**Report (user, screenshots).** Under a light and a dark Omarchy theme, Emacs looked the same
(default white Emacs colours) and the PDF stayed white on black. The user opens files with
"Emacs (Client)" from Nautilus and asked whether that is the wrong Emacs, and what the Emacs
entries in the app chooser are.

**Found.**
- "Emacs (Client)" (`emacsclient.desktop`) opens a frame of the Emacs daemon, `emacs.service`
  (systemd user unit, enabled since 2026-02-27, started at every login: today 17:35). A daemon
  reads init.el with no graphical frame, so `(display-graphic-p)` is nil there and the TEXSYNC
  block's `(when (and (display-graphic-p) (require 'omarchy-follow nil t)) …)` never ran.
  The live daemon: `omarchy-follow` not loaded, mode off, `custom-enabled-themes` nil.
- The PDF was not "stuck in dark": it was init.el's midnight hook (white on black, mode line
  ` Mid`), which applies when omarchy-follow is off.
- The daemon read init.el at 17:35, before the move here (19:57): its load path still has the
  deleted `~/repos/emacs-config`, so `M-x omarchy-follow-mode` there would fail too.
- The previous daemon started 2026-09-30 18:00, before the TEXSYNC block existed (14:23 today),
  so the client never had this package. Where it worked, it was probably a separate graphical
  Emacs (started directly or through texsync's `try.el`); not checked.
- texsync is on in the client frames: its check runs in `LaTeX-mode-hook`, when the frame is
  already graphical.
- The other entries: "Emacs" (`emacs.desktop`, `Exec=emacs`) resolves to Omarchy's wrapper
  `~/.local/bin/emacs`, which opens a terminal running `/usr/bin/emacs -nw`; "Emacs TUI"
  (`~/.local/share/applications/emacs-tui.desktop`) runs `/usr/bin/emacs -nw` in a terminal;
  "Emacs (Mail)" and "Emacs (Mail, Client)" are mailto handlers. Only "Emacs (Client)" gives a
  graphical Emacs.

**Checked (headless, `emacs -Q --batch`, `daemonp` forced true).** With the condition
`(or (display-graphic-p) (daemonp))` the mode turns on and loads `modus-operandi` with
Catppuccin Latte's palette (bg #eff1f5, fg #4c4f69, keyword #1e66f5); with neither, it stays
off, as before. (Read the palette with `(modus-themes-get-color-value 'bg-main t)`: without
the second argument it ignores the overrides and gives #ffffff.)

**Mistake.** The first run of that check called `emacs`, which is the terminal wrapper: it
opened two terminal windows on the user's desktop (they closed when batch Emacs exited). Use
`/usr/bin/emacs` for headless checks.

**Decision (user).** Change the condition, and restart the daemon to apply it.

**Done.** Backup `~/.emacs.d/init.el.bak-20261001-202640`. The TEXSYNC block of the live init
file and of `home/.emacs.d/init.el` turns the mode on when `(or (display-graphic-p) (daemonp))`,
with a comment saying why; the two blocks are identical, and the live file's 68 forms parse.
README.md (install snippet) and AGENTS.md say the same, and AGENTS.md now says to run headless
checks with `/usr/bin/emacs`. The daemon had no unsaved file buffers and no client frames; it
was restarted with `systemctl --user restart emacs`.

**Results.** The restarted daemon has the mode on, `custom-enabled-themes` (modus-operandi),
bg-main #eff1f5, fg-main #4c4f69 (Catppuccin Latte), the file watch set, and this directory on
its load path (the old `~/repos/emacs-config` is gone). `make compile` clean, `make test`
3 / 3. Not yet seen in a client frame on screen.

**Open.** The user to open a file with Emacs (Client) and switch light ↔ dark with a PDF open;
this also confirms the redraw fix of 14:29.

## 2026-10-01 20:47 CEST — init.el moved out of Dropbox into this repository

**Request (user).** Keep init.el locally in the dotfiles, backed up on GitHub; delete the
Dropbox copy. An automatic commit-and-push on every save was proposed; **decision (user):** no,
the user commits and pushes by hand.

**Done.**
- `~/.emacs.d/init.el` is now a symlink to `home/.emacs.d/init.el` here, which becomes the live
  file. It was identical to the Dropbox one except for one comment's chat link, which stays
  shortened. The full link survives only in the local `~/.emacs.d/init.el.bak-*` files.
- `~/Dropbox/etc/emacs/` deleted: init.el, `init.el.backup-before-improvements` (2025-10-26) and an
  `ampl-mode/` copy. `~/Dropbox/etc/zathura/` is still there.
- Two Dropbox paths in init.el were already broken: the ampl-mode load path
  (`~/Dropbox/libraries/…`, missing) and the dashboard banner picture (missing). The banner line
  is gone (the dashboard shows its default logo). ampl-mode now comes from
  github.com/ampl/ampl-mode (LGPL-3.0; the Dropbox copy was identical) through
  `(use-package ampl-mode :vc (:url … :lisp-dir "emacs" :rev :newest) :mode … :interpreter
  "ampl")`; it is installed in `~/.emacs.d/elpa/ampl-mode`.
- `vc-follow-symlinks` t, so opening `~/.emacs.d/init.el` visits the Git file without asking.
  `.gitignore` gains Emacs lock and auto-save files (`.#*`, `#*#`).
- home/README.md, README.md, AGENTS.md (root and here), `machine-state/symlinks.txt` updated.

**Mistakes.**
- I told the user ampl-mode was on MELPA without checking; it is not (neither the cached nor the
  live archive has it). Hence `:vc`.
- `:vc` without `:rev` asks for the latest release, which this repository does not have:
  `Wrong type argument: stringp, nil`. `:rev :newest` installs the latest commit (8059dc1).

**Results.** 63 top-level forms parse. The daemon was restarted (no unsaved buffers, no
client frames): it reads init.el from this repository, the Omarchy theme is on
(modus-operandi), `x.mod` opens in ampl-mode, `dashboard-startup-banner` is `official`.

**Open.** Not committed: the user commits and pushes.

## 2026-10-01 20:54 CEST — Confirmed in Emacs (Client); the two start-up warnings

**Result (user).** "The theme-color switch works at last!": Emacs (Client) frames follow
`omarchy theme set`. Whether a PDF was open during the switch (the redraw fix of 14:29) was
not said; that stays open.

**Report (user, screenshot).** A `*Warnings*` window at start: init.el has no
`lexical-binding` cookie (Emacs 31 warns), and pdf-tools warns that `display-line-numbers-mode`
is on in PDF buffers. Both predate this work. The first screenshots show the second one's
effect: a line-number column with a `1` beside the PDF page.

**Done.**
- First line of init.el: `-*- lexical-binding: nil -*-`. This keeps the dynamic binding init.el
  has always been read with and only silences the warning. Switching to `t` would change how
  every `let` and `lambda` in the file behaves and needs a review of the whole file first.
- In the pdf-tools `:config`: `pdf-view-mode-hook` turns `display-line-numbers-mode` off.
  `global-display-line-numbers-mode` (line 68) respects a mode turned off in the major mode's
  hook, and pdf-tools checks 1 s after the mode starts, so neither the warning nor the column
  appears. Emacs 31.1 has no `display-line-numbers-exempt-modes`.
- Running daemon: the same hook added, and line numbers turned off in the open PDF
  (`1-intro-informatica.pdf`) through `emacsclient --eval`; no restart. The cookie takes effect
  at the next daemon start.

**Checked (headless, `/usr/bin/emacs -Q --batch`).** Loading a file without the cookie gives the
warning, with `lexical-binding: nil` none. A derived mode whose hook turns line numbers off
stays without them under `global-display-line-numbers-mode`; text-mode gets them. init.el: 63
forms parse.

## 2026-10-01 21:13 CEST — Redraw fix confirmed on screen

**Result (user).** With a PDF open in Emacs (Client), switching the Omarchy theme changed the
PDF's colours too ("It worked."). The redraw fix of 14:29 is confirmed; the pdf-tools report
upstream is still open (ask before filing).

## 2026-10-01 21:55 CEST — Hook line removed; the pdf-tools bug is real and already fixed in a fork

**Decision (user).** Remove the hook line that calls `omarchy-theme-set-emacs`. Report the
pdf-tools bug, perhaps with a PR, if it really is a bug.

**Done (hook).** `~/.config/omarchy/hooks/theme-set` and its copy `home/.config/omarchy/hooks/
theme-set` are now only `#!/bin/bash`. Before, every `omarchy theme set` ran the missing command,
which failed. `omarchy-hook` then reports "Hook failed", but `omarchy-theme-set` sends that to
/dev/null, so nobody saw it. Now the hook exits 0. The file is kept, as asked;
deleting it would change nothing.

**Is it a bug? Yes.**
- In single-page mode, `pdf-view--redisplay` documents WINDOW t as "redisplay pages in all
  windows" and walks `get-buffer-window-list`. Sixteen `(pdf-view-redisplay t)` calls rely on
  that: midnight, themed, the annotation and link modes, the fit and scale commands.
- In roll mode, `pdf-view-redisplay` hands over to `pdf-roll-redisplay`, whose docstring calls it
  an "analogue". It turns t into `(selected-window)` and does nothing when that window shows
  another buffer. So a change made from another window (texsync's source window, a hook, a
  timer) redraws nothing, and with the PDF in two windows only the selected one is redrawn.
- Upstream master (vedang/pdf-tools) has the same code: pdf-roll.el dates from 2025-12-31
  (d54ba64), and the installed 20260102.1101 matches it.

**Upstream status.**
- alberti42 found and fixed this in their fork on 2026-09-28: commit bdb1c8f2c
  "fix(pdf-roll): redisplay every window when WINDOW is t", which walks `get-buffer-window-list`
  for t, with an ERT test. It is on branch `fix/roll-redisplay-all-windows` and in their
  `merged` branch (issue #372), but no upstream PR exists.
- Their seven upstream PRs (#361–#371) are open and untouched. #367 fixes the same "selected
  window only" pattern in another function (`displayed-pages`), not this one.
- No issue mentions this bug. The repository was last pushed to on 2026-01-08.

**Checked (headless).** alberti42's test, `pdf-roll-redisplay-t-reaches-every-window` (three
real windows in batch; the selected one shows another buffer), against the installed
pdf-roll: FAILED (`win-a` keeps its state). With their `pdf-roll-redisplay` loaded on top:
passed.

**Open.** How to report it, to be decided by the user: opening a PR of our own would duplicate
alberti42's fix.

## 2026-10-01 22:01 CEST — pdf-tools bug reported

**Decision (user).** Report it as an issue rather than a PR, which would duplicate alberti42's fix.
The user approved the draft as shown.

**Done.** https://github.com/vedang/pdf-tools/issues/373 describes the bug, gives a repro
(change the colours from another window in roll mode) and the expected behaviour, says the
two-windows case comes from reading the code and was not seen on screen, links alberti42's
commit bdb1c8f2c, and asks them to open a PR.

**Open.** Watch #373 for an answer. When a fixed pdf-tools is installed, the redraw loop in
`omarchy-follow--refresh-pdfs` can go; until then it stays (harmless with the fix).

## 2026-10-03 17:13 CEST — Its own repository

**Decision (user).** Each Emacs project in a repository of its own, so that others can pick
them up separately: this package, emacs-tui-default and the init file
(emacs-customizations) leave omarchy-customizations; texsync already had its own.

**Done.** `git subtree split` of the `emacs-omarchy-theme/` folder keeps its four commits; the
repository is github.com/stefanoconiglio/emacs-omarchy-theme, cloned at
`~/repos/emacs-omarchy-theme`. The init file's TEXSYNC block now puts that path on the load
path. Paths updated in README.md (load path, `emacs -Q` example, links to
emacs-customizations, emacs-tui-default and the theme-set hook in omarchy-customizations),
AGENTS.md (the rules it took from omarchy-customizations' AGENTS.md are now written out) and
the `URL:` header of omarchy-follow.el. Earlier entries keep the paths of their time.

**Open.** No licence yet (texsync is GPL-3.0): the user's call.
