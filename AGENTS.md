# Working on emacs-omarchy-theme

For an agent (or a person) resuming work on `omarchy-follow`. This repository is **public**
(github.com/stefanoconiglio/emacs-omarchy-theme): no secrets, credentials, chat links or other
private details are committed. The live machine is read-only unless the user says otherwise:
inspect it, but do not change files, packages or services outside this repository without
being asked.

## Where things are

- **The package:** `omarchy-follow.el` here. Design: `DESIGN.md`. History, findings and
  mistakes: `RESEARCH_LOG.md`. Read both before changing anything.
- **Where it is used:** the user's live init file, `~/.emacs.d/init.el`, a symlink to
  `~/repos/emacs-customizations/init.el` (github.com/stefanoconiglio/emacs-customizations,
  public): editing that file edits the live one, and it is committed only when the user asks.
  Its TEXSYNC block (near the end) puts this directory and
  `~/repos/texsync` on the load path and turns `omarchy-follow-mode` on in graphical Emacs and
  in the Emacs daemon (`emacs.service`, which "Emacs (Client)" connects to; the user's usual
  way in). The daemon reads init.el with no graphical frame: test it with `daemonp` forced
  true, and restart it (`systemctl --user restart emacs`, after the user has saved) to reload.
- **Companion:** texsync, `~/repos/texsync` (github.com/stefanoconiglio/texsync, public): LaTeX
  and PDF side by side, synced both ways. It has its own AGENTS.md. Both are loaded together;
  texsync's `try.el` turns this package on when it is on the load path.
- **Omarchy's side:** current theme in `~/.local/state/omarchy/current/` (`theme.name`,
  `theme/colors.toml`); `omarchy-theme-color --file … mode` for light/dark. Never edit
  `/usr/share/omarchy/`.
- **History:** the package first lived in a local repository, `~/repos/emacs-config` (deleted),
  then in the `emacs-omarchy-theme/` folder of omarchy-customizations (the user's machine
  repository, private since 2026-10-03),
  and since 2026-10-03 in this repository, with that folder's history (RESEARCH_LOG.md).

## State (2026-10-01)

- Works on screen: Emacs takes the theme and follows `omarchy theme set`; dark-theme PDFs take
  the theme's colours. Also in Emacs (Client) frames of the daemon, the user's usual Emacs
  (fixed and confirmed by the user 2026-10-01).
- PDF windows are redrawn after a change (they kept the old colours, a pdf-tools bug in
  continuous mode): fixed, confirmed on screen by the user 2026-10-01.
- `make test` 3 / 3.

## Open

- The pdf-tools redraw bug (`(pdf-roll-redisplay t)` redraws only the selected window) is
  confirmed, and already fixed in alberti42's fork (commit bdb1c8f2c, 2026-09-28), but not
  proposed upstream (vedang/pdf-tools, no maintainer activity since 2026-01-08). Reported as
  vedang/pdf-tools#373 (2026-10-01), asking alberti42 to open the PR. Keep the workaround in
  `omarchy-follow--refresh-pdfs` until a fixed pdf-tools is installed: it is harmless with the
  fix.

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
