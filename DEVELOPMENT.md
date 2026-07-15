# Vim-Shell-Command Developer Instructions

Use `bin/test/setup-environment` to ensure dev/test dependencies are present
(include checking the current versions of vim/nvim in your $PATH are new enough).

Use `bin/test/test-one tests/...` to run one or more tests. Optionally provide `--vim` or `--nvim` to limit to just vim/nvim, otherwise test(s) will be executed with both.

Use `bin/test/test-all` to run the whole test suite.

## Test Depenencies

Tests are written using [Vader.vim](https://github.com/junegunn/vader.vim) and stored in `tests/`.

### Dependencies

* **Vim** (≥ 7.4) or **Neovim**
* [Vader.vim](https://github.com/junegunn/vader.vim)
* **col** CLI utility

No Lua, no Neovim-only APIs, and no external build tools are required.
