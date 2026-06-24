# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-06-23

### Changed

- Rechecked the binding set against upstream `tmux-plugins/tmux-pain-control`.
  Pane navigation, repeatable resizing, directory-preserving splits, window
  swapping, and the synchronize-panes toggle are all present, each carries a
  `-N` key description, and the plugin adds full-width and full-height splits
  plus optional vim navigation beyond the upstream. No code change needed.

## [1.0.0] - 2026-06-21

### Added

- Pane navigation (h/j/k/l and C-h/j/k/l), repeatable resizing with a
  configurable step, splits that keep the current directory including the
  default `"` and `%` keys, new window in the current path, repeatable window
  move, and a synchronize-panes toggle.
- Version gating for tmux 1.9 and up: full splits use `-f` on 2.3+, the
  copy-mode table is used on 2.4+, and binding description notes on 3.1+.
- Configurable keys and an `@pane_control_disabled_keys` option so any binding
  can be turned off to avoid a conflict.
- Optional prefixless Ctrl+h/j/k/l navigation that detects vim with the standard
  is_vim check, off by default, to coexist with or replace vim-tmux-navigator.
