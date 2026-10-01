# Emacs follows the Omarchy theme

`omarchy-follow-mode` (in `omarchy-follow.el`) gives graphical Emacs the colours of the current
Omarchy theme, and changes them, within about a second, whenever `omarchy theme set` runs:

- Emacs: the built-in Modus theme (Vivendi for a dark Omarchy theme, Operandi for a light one)
  with its palette replaced by the Omarchy palette.
- PDFs in pdf-tools: in a dark theme they take the theme's background and text colours
  (pictures are tinted too); in a light theme they keep their own colours.

Nothing in the Omarchy configuration is changed: Emacs reads the theme from Omarchy's state
directory (`~/.local/state/omarchy/current/`) and watches it.

It was written together with [texsync](https://github.com/stefanoconiglio/texsync) (LaTeX
source and PDF side by side in Emacs, kept in step), but works on its own.

## Use

In the init file (`home/.emacs.d/init.el` here does this, in its TEXSYNC block):

```elisp
(add-to-list 'load-path "~/repos/omarchy-customizations/emacs-omarchy-theme")
(when (and (or (display-graphic-p) (daemonp)) (require 'omarchy-follow nil t))
  (omarchy-follow-mode 1))
```

Only in graphical Emacs (`/usr/bin/emacs`) and in the Emacs daemon, whose frames "Emacs
(Client)" opens: a daemon reads the init file before it has a graphical frame, so
`display-graphic-p` alone would leave the mode off there. Terminal Emacs (`emacs`, which
`emacs-tui-default/` makes `emacs -nw`) keeps the terminal's colours.

Try it with texsync, without an init file:

```
/usr/bin/emacs -Q -L ~/repos/omarchy-customizations/emacs-omarchy-theme \
    -l ~/repos/texsync/try.el FILE.tex
```

Commands and options: `M-x omarchy-follow-apply` re-applies the current theme;
`omarchy-follow-pdf` (t) — nil leaves PDFs alone; `omarchy-follow-state-dir` — where Omarchy
keeps the current theme. To turn the PDF colours off for one PDF:
`M-x pdf-view-themed-minor-mode`.

## Files

- `omarchy-follow.el`: the package.
- `test/omarchy-follow-test.el`: batch tests; `make test` (headless, about a second).
- `DESIGN.md`: how it works (palette mapping, light/dark, PDFs, the file watch).
- `RESEARCH_LOG.md`: what was tried, found and fixed, dated.
- `AGENTS.md`: how to resume work on it (state, checks, open items).

## Note on the theme-set hook

`home/.config/omarchy/hooks/theme-set` calls `omarchy-theme-set-emacs`, a command that does not
exist on this machine (its output is discarded, so the failure is silent). It was presumably an
earlier attempt at the same thing; `omarchy-follow-mode` does not need it. It is left as found.
