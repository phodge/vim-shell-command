# OBJECTIVE

Right now the `:Shell` command is synchronous, and blocks Vim completely while it runs. I'd like the *option* to have it
run a command in the background instead.

## User-Facing Design

When I run `:Shell <command>` AND the command ends with an '&', the plugin should engage an asynchronous backend
instead to run the Job:

* The new buffer is created and switched to immediately.
* The first line of the buffer is written with the leading '##' characters
* The next line of the buffer says '<<<WAITING FOR PID {$PID} :: {$MINUTES}:{$SECONDS}>>>'
* Output from the shell command (Job) is added to the buffer line-by-line until the Job process has terminated.
* When the Job has terminated, the '<<<WAITING FOR PID ...>>>' is deleted. This should be done in such a way that if the
  user has already selected some lines of output with Visual Mode, their visual mode selection doesn't move around (it
  "sticks" to the output text that it was already encompassing).
* If I press <F12> to re-run the command, the currently-running Job must be terminated first.

## Implementation Notes

Must be written in Vimscript so that it's compatible with Vim as well.

Prefer to put functions in an autoload namespace (`VimShell#...`) so that they don't all load on startup.

Plan what new functions need to be written, what existing functions need to be refactored first.

If existing code needs refactoring, make those changes first and then stop and ask me to review the changes before
starting work on the new async parts.

Make sure all new features are mentioned in the README.md

## Tests

### Preparing the local environment

1. Clone this repository.
2. Install Vader.vim into the project-local vendor directory:
   ```
   git clone https://github.com/junegunn/vader.vim.git tests/vendor/vader.vim
   ```

### Running tests

**Full test suite:**

```sh
vim -Nu tests/test-vimrc -c 'Vader! tests/*.vader'
```

The `!` causes Vim to exit with status 0 (pass) or 1 (fail), making the command suitable for CI.

**Single test file:**

```sh
vim -Nu tests/test-vimrc -c 'Vader! tests/sync_basic.vader'
```

**Single test case within a file** (by pattern):

```sh
vim -Nu tests/test-vimrc -c 'Vader! tests/sync_basic.vader' -c '/header line'
```

### Existing Functionality

#### `tests/sync_basic.vader` — Synchronous `:Shell` basics

* `:Shell echo hello` creates a new buffer whose first line is `## Shell: echo hello`.
* The buffer's filetype is `shell-command`.
* The buffer's `buftype` is `nofile`.
* Command output (line 2+) contains the expected text.
* The buffer is listed in `s:shell_buffers` and cleaned up when wiped.

#### `tests/sync_rerun.vader` — Re-running commands

* After `:Shell echo hello`, pressing `<F5>` re-executes the command and refreshes the output.
* Editing the `## Shell:` header line and pressing `<F5>` runs the edited command.
* `g:shell_command_reload_map` overrides the re-run key.
* `:ShellRerun` re-runs all shell buffers visible in the current tab.

#### `tests/sync_options.vader` — Configuration options

* `g:shell_command_use_col = 0` disables `col -b` filtering.
* `g:shell_command_escape_chars` overrides the default escape characters.

#### `tests/sync_error.vader` — Exit code handling

* A failing command (e.g. `:Shell false`) sets the buffer name to `[1] false`.
* A succeeding command (e.g. `:Shell true`) sets the buffer name to `true` (no error prefix).

### New (Async) Functionality

#### `tests/async_basic.vader` — Async buffer creation and output

* `:Shell sleep 5 &` creates a buffer immediately.
* Line 1 is `## Shell: sleep 5 &`.
* Line 2 matches `<<<WAITING FOR PID \d\+ :: \d\+:\d\+>>>`.
* Output is appended line-by-line as the job runs.
* When the job finishes, the `<<<WAITING ...>>>` line is removed.
* After completion, the buffer contains only the header and output lines.

#### `tests/async_output.vader` — Line-by-line streaming

* A command that prints multiple lines (e.g. `:Shell for i in 1 2 3; do echo $i; done &`) produces one buffer line per output line in the correct order.

#### `tests/async_visual_stickiness.vader` — Visual selection preservation

* Start a long-running async command, select output lines in Visual Mode, wait for the job to finish, and confirm the visual selection still covers the same text (the `<<<WAITING ...>>>` line is deleted without shifting the selection).

#### `tests/async_rerun.vader` — `<F12>` re-run terminates active job

* Start `:Shell sleep 10 &`, then press `<F12>`. The original job is terminated (confirmed via `job_status()` or process check) and a new job starts.
* The buffer header is updated and a fresh `<<<WAITING ...>>>` line appears.

#### `tests/async_no_col.vader` — Async respects `col` option

* With `g:shell_command_use_col = 0`, an async command's output is not filtered through `col`.

#### `tests/async_error.vader` — Async exit code handling

* A failing async command (e.g. `:Shell false &`) sets the buffer name to `[1] false` after the job finishes.
