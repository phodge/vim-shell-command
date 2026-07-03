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
