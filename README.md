<div align="center">

<h1>tmux-pain-control-revamped</h1>

**Standard pane and window management bindings for tmux, version aware, vim friendly, and fully configurable.**

[![Tests](https://github.com/tmux-revamped/tmux-pain-control-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-pain-control-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](CHANGELOG.md)

</div>

**35+** bindings · **tmux 1.9 to 3.5** · **vim aware** · **77** tests · **95%+** coverage

Pane navigation, resizing, splits that keep the current directory, and window movement, the conventions almost everyone hand-rolls, as a perfected superset of [tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control). Every binding is gated to the tmux versions that support it, so the same plugin runs cleanly on every tmux TPM supports, from 1.9 up. Any key can be turned off to avoid a conflict, and an optional smart `Ctrl+h/j/k/l` coexists with [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator).

Built from [tmux-plugin-template](https://github.com/tmux-revamped/tmux-plugin-template).

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
| `*` | smart split along the longer axis, keep path | no | 1.9 |
| `@` | join a pane in from another window (prompt) | no | 1.9 |
| `!` | break the current pane out to its own window | no | 1.9 |
| `{` `}` | swap the current pane with the previous or next | yes | 1.9 |
| `+` | promote the current pane to the main slot | no | 3.0, pane index 0 below |
| `m` `=` | mark a pane, then swap the current pane with the marked one | no | 2.1 |
| `E` `V` `B` | even-horizontal, even-vertical, main-vertical layout | no | 1.9 |
| `.` | move the current window to another session (prompt) | no | 1.9 |
| `&` | kill the current window, after a confirm | no | 1.9 |
| `R` | respawn the current pane, after a confirm | no | 1.9 |
| `P` | name the current pane (prompt) | no | 2.6 |
| `C` | capture the whole scrollback to a file (prompt) | no | 1.9 |
| `g` | open an ephemeral scratch shell over the session | no | 3.2 |

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-revamped/tmux-pain-control-revamped'
```

Then press `prefix + I` to install.

Manual install:

```bash
git clone https://github.com/tmux-revamped/tmux-pain-control-revamped ~/.tmux/plugins/tmux-pain-control-revamped
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
| `@pane_control_no_wrap` | `off` | set `on` so pane selection stops at the edge instead of wrapping to the far side (tmux 2.6+) |
| `@pane_control_pane_titles` | `off` | set `on` to show pane titles in the pane border (tmux 2.3+) |
| `@pane_control_smart_split_key` | `*` | key for the longer-axis smart split |
| `@pane_control_join_key` | `@` | key that prompts to join a pane in |
| `@pane_control_break_key` | `!` | key that breaks the current pane to its own window |
| `@pane_control_swap_prev_key` | `{` | key that swaps the pane with the previous |
| `@pane_control_swap_next_key` | `}` | key that swaps the pane with the next |
| `@pane_control_promote_key` | `+` | key that promotes the pane to the main slot |
| `@pane_control_mark_key` | `m` | key that marks a pane (tmux 2.1+) |
| `@pane_control_swap_mark_key` | `=` | key that swaps the current pane with the marked one (tmux 2.1+) |
| `@pane_control_layout_even_h_key` | `E` | key for the even-horizontal layout |
| `@pane_control_layout_even_v_key` | `V` | key for the even-vertical layout |
| `@pane_control_layout_main_v_key` | `B` | key for the main-vertical layout |
| `@pane_control_move_window_key` | `.` | key that prompts to move the window to another session |
| `@pane_control_kill_window_key` | `&` | key that kills the window after a confirm |
| `@pane_control_respawn_key` | `R` | key that respawns the pane after a confirm |
| `@pane_control_pane_name_key` | `P` | key that prompts for a pane title (tmux 2.6+) |
| `@pane_control_capture_key` | `C` | key that prompts to save the scrollback to a file |
| `@pane_control_scratch_key` | `g` | key that opens the scratch popup (tmux 3.2+) |
| `@pane_control_scratch_command` | empty | command the scratch popup runs; empty opens your default shell |

## Working with vim-tmux-navigator

The prefixed `h/j/k/l` here and the prefixless `Ctrl+h/j/k/l` of vim-tmux-navigator live in different key tables and never collide, so the two are complementary: keep using both. To stop running vim-tmux-navigator's tmux side, set `@pane_control_vim_navigation 'on'` and this plugin provides the same prefixless `Ctrl+h/j/k/l` plus `Ctrl+\` for the previous pane, with the same `is_vim` process check, so the same chord moves your vim split when vim is focused and the tmux pane otherwise. The `is_vim` pattern is overridable through `@pane_control_vim_pattern`, matching vim-tmux-navigator's `@vim_navigator_pattern`. This needs tmux 2.4 or newer and binds the chords without a prefix, which shadows `Ctrl+l` clear-screen, so it stays off by default.

This replaces only the tmux half of vim-tmux-navigator. The Neovim or Vim half, the in-editor keymaps, is a Vim plugin and still belongs in your editor config.

## Compatibility

Works on every tmux version TPM supports, 1.9 and up, on Linux (x86_64 and arm64) and macOS (Intel and Apple Silicon). Newer operations are gated to the versions that support them: the marked-pane swap needs 2.1, pane titles need 2.6, edge no-wrap selection needs 2.6, the promote-to-main token needs 3.0, and the scratch popup needs 3.2. Below tmux 2.3 the full-width and full-height splits fall back to normal splits; below 3.1 the binding description notes are omitted; the optional smart navigation needs 2.4 for the copy-mode table. Each gated binding is simply omitted on older tmux; nothing errors.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

The decision logic lives in [`src/lib/pain/pain.sh`](src/lib/pain/pain.sh) as pure, seam-backed helpers, and the applier in [`src/pain.sh`](src/pain.sh) runs under a dry-run mode so the full binding matrix is validated without a live tmux.

## License

[MIT](LICENSE), copyright Gustavo Franco.
