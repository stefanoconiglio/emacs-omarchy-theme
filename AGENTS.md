# Working on emacs-omarchy-theme

For an agent (or a person) resuming work on `omarchy-follow`. The repository-wide rules in
`../AGENTS.md` apply too: this repository is **public**, the live machine is read-only unless
the user says otherwise, and no secrets or private details are committed.

## Where things are

- **The package:** `omarchy-follow.el` here. Design: `DESIGN.md`. History, findings and
  mistakes: `RESEARCH_LOG.md`. Read both before changing anything.
- **Where it is used:** the user's live init file, `~/.emacs.d/init.el`, a symlink to
  `~/Dropbox/etc/emacs/init.el`. Its TEXSYNC block (near the end) puts this directory and
  `~/repos/texsync` on the load path and turns `omarchy-follow-mode` on in graphical Emacs and
  in the Emacs daemon (`emacs.service`, which "Emacs (Client)" connects to; the user's usual
  way in). The daemon reads init.el with no graphical frame: test it with `daemonp` forced
  true, and restart it (`systemctl --user restart emacs`, after the user has saved) to reload.
  `home/.emacs.d/init.el` in this repository mirrors the live file, sanitized (a chat link is
  shortened); keep the two in step by hand, applying only the intended change.
- **Companion:** texsync, `~/repos/texsync` (github.com/stefanoconiglio/texsync, public): LaTeX
  and PDF side by side, synced both ways. It has its own AGENTS.md. Both are loaded together;
  texsync's `try.el` turns this package on when it is on the load path.
- **Omarchy's side:** current theme in `~/.local/state/omarchy/current/` (`theme.name`,
  `theme/colors.toml`); `omarchy-theme-color --file … mode` for light/dark. Never edit
  `/usr/share/omarchy/`.
- **History:** the package first lived in a local repository, `~/repos/emacs-config`, deleted
  once everything was here (RESEARCH_LOG.md).

## State (2026-10-01)

- Works on screen: Emacs takes the theme and follows `omarchy theme set`; dark-theme PDFs take
  the theme's colours.
- Fixed, not yet confirmed on screen: PDF windows are redrawn after a change (they kept the old
  colours, a pdf-tools bug in continuous mode).
- `make test` 3 / 3.

## Open

- Confirm on screen with the user, in an Emacs (Client) frame, that the daemon follows the
  theme (fixed 2026-10-01 20:28: it never turned the mode on) and the redraw fix (switch
  light ↔ dark with a PDF open).
- Report the pdf-tools redraw bug upstream (`pdf-view-refresh-themed-buffer` →
  `(pdf-roll-redisplay t)` redraws only the selected window). Ask before filing.
- `home/.config/omarchy/hooks/theme-set` calls the non-existent `omarchy-theme-set-emacs`.
  Removing that line was offered; the user has not decided.
- The init file lives in Dropbox, which is full: changes there may not sync.

## Checks

- `make compile` (warnings are errors) and `make test` (headless, about a second) before every
  commit. The test uses a temporary state directory; it never changes the real theme.
- **Do not open windows on the user's desktop** (graphical Emacs, test runs) without asking:
  they work on this machine at the same time. Check behaviour headless where possible: load the
  init file in `/usr/bin/emacs --batch` (plain `emacs` is Omarchy's wrapper and opens a
  terminal window) with `(advice-add 'display-graphic-p :override (lambda (&rest _) t))`, or
  `daemonp` likewise, to take the graphical branch; or run `omarchy-follow-apply` in batch and read the
  palette with `modus-themes-get-color-value`.
- In batch Emacs, file-notify events arrive through the input queue: wait with `read-event`.
- Modus themes are in Emacs's theme directory: load them with `(require-theme 'modus-themes)`.

## Conventions

- Each finding, decision or mistake gets a dated entry in `RESEARCH_LOG.md` (time from `date`)
  when it happens; `DESIGN.md` changes in the same commit as the code it describes.
- Commit only when the user asks; stage only the files of the change (the repository often has
  unrelated uncommitted edits).
