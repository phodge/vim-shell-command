# vim-shell-command
Run a shell command from within vim and see the output in a new window

## How to use it

To run the `man test` and see the output in a new window, use:

    :Shell man test

## Options

By default, the output of your shell command will be filtered through `col -b`
to strip out terminal escape sequences (such as colors). You can disable this
behaviour using the following variable:

    let g:shell_command_use_col = 0

You can re-run the shell command by pressing `F5` while your cursor is in the
shell window. If you would like to use an alternate key for the mapping, add
this global variable to your `.vimrc`

    let g:shell_command_reload_map = "<F10>"
