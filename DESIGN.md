# Emacs follows the Omarchy theme — design

## Files and data flow

- `omarchy-follow.el`: the package; one global minor mode, `omarchy-follow-mode`.
- `test/omarchy-follow-test.el`: ERT tests, run by `make test`.
- `Makefile`: `make compile` (byte-compile, warnings are errors), `make test`, `make clean`.

```
~/.local/state/omarchy/current/        file-notify watch (directory)
  theme.name, theme/colors.toml   ──►  change to a file named theme…
                                         └─► timer 0.5 s (debounced) ─► omarchy-follow-apply
omarchy-follow-apply:
  omarchy-follow-colors  (colors.toml + mode)
  omarchy-follow-overrides ─► modus-vivendi/operandi-palette-overrides
  disable enabled themes, load-theme modus-vivendi | modus-operandi
  omarchy-follow--refresh-pdfs ─► pdf-view-themed-minor-mode on (dark) / off (light),
                                  redraw every window showing a PDF
pdf-view-mode-hook ─► omarchy-follow--pdf-hook (new PDFs, dark theme: themed mode on)
```

## Reading the theme

- **Where.** Omarchy keeps the current theme in `~/.local/state/omarchy/current/`:
  `theme/colors.toml` (`background`, `foreground`, `accent`, `selection`, `cursor`,
  `color0`…`color15`) and `theme.name`. `omarchy-follow--parse-toml` reads the
  `key = "value"` lines; nothing else of TOML is needed.
- **Light or dark**, as Omarchy's own per-app scripts decide it (`omarchy-theme-set-gnome`,
  `-tmux`): `omarchy-theme-color --file colors.toml mode`. Without that command: a `mode` key,
  a legacy `light.mode` file beside `colors.toml`, or the background's relative luminance
  (0.2126 R + 0.7152 G + 0.0722 B > 0.5 is light).

## Emacs: Modus with the Omarchy palette

Emacs 31 ships Modus themes 5.2, which take palette overrides
(`modus-vivendi-palette-overrides`, `modus-operandi-palette-overrides`) set before
`load-theme`; Modus maps its semantic palette entries to all faces, AUCTeX's included. Mapping
(blend(a, b, f) = colour a moved a fraction f towards b, per RGB channel):

- `bg-main` = background, `fg-main` = foreground, `cursor` = cursor (else foreground);
- `fg-dim`, `comment`, `fg-mode-line-inactive` = blend(foreground, background, 0.4);
- `bg-dim` 0.06, `bg-hl-line` 0.08, `bg-mode-line-inactive` 0.08, `bg-inactive` 0.09,
  `bg-active` 0.18, `border` 0.3 = blend(background, foreground, f);
- `bg-region` = blend(background, selection, 0.35), `fg-region` = foreground;
- `bg-mode-line-active` = blend(background, accent, 0.35), `fg-mode-line-active` = foreground;
- `bg-paren-match` = blend(background, accent, 0.5);
- `err` = color1, `warning` = color3, `string` and `docstring` = color2, `constant` = color4,
  `keyword` = color5, `type` = color6, `builtin` = color13, `variable` = color14, `fnname` and
  `fg-heading-1` = accent (each falls back to accent or foreground when missing).

All other enabled themes are disabled first, so the result does not depend on what was loaded.

## PDFs

In a dark theme `pdf-view-themed-minor-mode` is turned on in every pdf-view buffer (new ones
through `pdf-view-mode-hook`): pdf-tools then renders pages with the default face's
foreground and background, so they take the theme's colours (pictures are tinted too). In a
light theme it is turned off and PDFs keep their own colours. `omarchy-follow-pdf` nil leaves
PDFs alone. The user's init.el had pdf-tools' midnight mode (white on black) for every PDF; it
now applies only when `omarchy-follow-mode` is off.

**Redraw.** Turning themed mode on or off, or refreshing it, ends in pdf-tools with
`(pdf-view-redisplay t)`, meaning all windows. In continuous mode (`pdf-roll`) that becomes
`(pdf-roll-redisplay t)`, which takes a non-window as the selected window — with texsync, the
source window — finds no page overlays there and does nothing: the pages already drawn kept
their old colours. So after a change `omarchy-follow--refresh-pdfs` calls `pdf-view-redisplay`
on every window that shows the PDF. (A pdf-tools bug; reporting it upstream is open.)

## Following changes

`file-notify-add-watch` on the state directory (inotify on this machine). A change to any file
whose name contains `theme` starts (or restarts) a 0.5 s timer that runs `omarchy-follow-apply`:
`omarchy theme set` swaps the theme directory and then rewrites `theme.name`, and the delay
lets it finish. Turning the mode off removes the watch and the hook.

## Tests

`make test`, 3 ERT tests, headless, against a temporary state directory (the real theme is not
touched):

- palette and light/dark, with `omarchy-theme-color` and without it (empty `exec-path`): dark
  Retro Fallout colours; Catppuccin Latte colours, light by luminance; an explicit
  `mode = "light"`; a missing directory gives nil;
- colour blends at 0, 0.5 and 1;
- turning the mode on with a dark theme loads Vivendi with its background, foreground and
  keyword (color5); rewriting the directory to a light theme switches to Operandi with its
  background within 5 s. File events arrive through the input queue, so the test waits with
  `read-event`, as the command loop does; `accept-process-output` never sees them.

Not covered: PDFs (no windows in batch). The redraw fix rests on reading pdf-tools' code; it
has not been confirmed on screen yet (RESEARCH_LOG.md).
