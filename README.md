<div align="center">

<h1>tmux-pain-control-revamped</h1>

**Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable.**

[![Tests](https://github.com/gufranco/tmux-pain-control-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/gufranco/tmux-pain-control-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

**20+** bindings · **tmux 1.9 to 3.5** · **vim aware** · **46** tests · **95%+** coverage

Pane navigation, resizing, splits that keep the current directory, and window movement, the conventions almost everyone hand-rolls, as a perfected superset of [tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control). Every binding is gated to the tmux versions that support it, so the same plugin runs cleanly on every tmux TPM supports, from 1.9 up. Any key can be turned off to avoid a conflict, and an optional smart `Ctrl+h/j/k/l` coexists with [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator).

Built from [tmux-plugin-template](https://github.com/gufranco/tmux-plugin-template).

<table>
<tr>
<td><strong>Keeps your directory</strong><br>Every split and new window opens in the current pane's path, including the default `"` and `%` keys.</td>
<td><strong>Version-aware</strong><br>Full splits, the copy-mode table, and binding notes are applied only on the tmux versions that support them.</td>
</tr>
<tr>
<td><strong>Conflict-free</strong><br>Any key can be disabled through one option, so it never fights another plugin or your own bindings.</td>
<td><strong>Vim friendly</strong><br>Prefixed nav coexists with vim-tmux-navigator, and an optional smart `Ctrl+h/j/k/l` adds split-aware navigation.</td>
</tr>
</table>

## Bindings

All keys are pressed after the prefix.

| Key | Action | Repeatable | Min tmux |
|-----|--------|------------|----------|
| `h` `j` `k` `l` (and `C-h` `C-j` `C-k` `C-l`) | select pane left, down, up, right | no | 1.9 |
| `H` `J` `K` `L` | resize pane, by `@pane_resize` cells | yes | 1.9 |
| `\|` | split right, keep path | no | 1.9 |
| `-` | split down, keep path | no | 1.9 |
| `\` | split full width, keep path | no | 2.3, normal split below |
| `_` | split full height, keep path | no | 2.3, normal split below |
| `"` and `%` | the default splits, now keeping path | no | 1.9 |
| `c` | new window, keep path | no | 1.9 |
| `<` `>` | move the current window left or right | yes | 1.9 |
| `S` | toggle synchronized input across panes | no | 1.9 |

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'gufranco/tmux-pain-control-revamped'
```

Then press `prefix + I` to install.

Manual install:

```bash
git clone https://github.com/gufranco/tmux-pain-control-revamped ~/.tmux/plugins/tmux-pain-control-revamped
run-shell ~/.tmux/plugins/tmux-pain-control-revamped/pain-control-revamped.tmux
```

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@pane_resize` | `5` | cells each resize binding moves |
| `@new_window_path` | `true` | new window opens in the current path; set `false` for the default behavior |
| `@pane_control_sync_key` | `S` | key that toggles `synchronize-panes` |
| `@pane_control_disabled_keys` | empty | space or comma separated keys to leave unbound, for example `"c <"` |
| `@pane_control_vim_navigation` | `off` | set `on` for prefixless `Ctrl+h/j/k/l` and `Ctrl+\` pane and vim-split navigation |
| `@pane_control_vim_pattern` | the vim-family regex | the process pattern that marks a pane as running vim; override for a wrapped or renamed editor |

## Working with vim-tmux-navigator

The prefixed `h/j/k/l` here and the prefixless `Ctrl+h/j/k/l` of vim-tmux-navigator live in different key tables and never collide, so the two are complementary: keep using both. To stop running vim-tmux-navigator's tmux side, set `@pane_control_vim_navigation 'on'` and this plugin provides the same prefixless `Ctrl+h/j/k/l` plus `Ctrl+\` for the previous pane, with the same `is_vim` process check, so the same chord moves your vim split when vim is focused and the tmux pane otherwise. The `is_vim` pattern is overridable through `@pane_control_vim_pattern`, matching vim-tmux-navigator's `@vim_navigator_pattern`. This needs tmux 2.4 or newer and binds the chords without a prefix, which shadows `Ctrl+l` clear-screen, so it stays off by default.

This replaces only the tmux half of vim-tmux-navigator. The Neovim or Vim half, the in-editor keymaps, is a Vim plugin and still belongs in your editor config.

## Compatibility

Works on every tmux version TPM supports, 1.9 and up, on Linux (x86_64 and arm64) and macOS (Intel and Apple Silicon). Below tmux 2.3 the full-width and full-height splits fall back to normal splits; below 3.1 the binding description notes are omitted; the optional smart navigation needs 2.4 for the copy-mode table.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

The decision logic lives in [`src/lib/pain/pain.sh`](src/lib/pain/pain.sh) as pure, seam-backed helpers, and the applier in [`src/pain.sh`](src/pain.sh) runs under a dry-run mode so the full binding matrix is validated without a live tmux.

## License

[MIT](LICENSE), copyright Gustavo Franco.
