if exists('g:loaded_shell_command') || v:version < 700 || &cp
    finish
endif
let g:loaded_shell_command = 1

if ! exists('s:shell_buffers') || type(s:shell_buffers) != type({})
  let s:shell_buffers = {}
endif


" run a shell command
command! -nargs=+ -complete=shellcmd Shell  call ShellCommandRun(0, <q-args>)

" run a shell command interactively
command! -nargs=+ -complete=shellcmd Shelli call ShellCommandRun(1, <q-args>)

" rerun any shell commands in windows open in the current tab
command! -nargs=0 ShellRerun call ShellCommandRerunAll()


" helper function
function! ShellCommandRun(interactive, command) "{{{
  " create a new buffer
  new
  setfiletype shell-command

  " register the new buffer, clean out old buffers
  let s:shell_buffers[bufnr('')] = 0
  call <SID>CleanShellBuffersList()

  setlocal buftype=nofile bufhidden=wipe noswapfile
  " line-wrapping may cause dramas when the user is trying to edit the :Shell
  " line, so we disable it now
  setlocal textwidth=0

  " put the header on the file
  normal! ggdG
  call setline(1, '## Shell'.(a:interactive?'i':'').': '.a:command)

  call <SID>RunShellCommandHere()

  " add a keymapping for re-running the shell command
  let l:keymap = "<F5>"
  if exists('g:shell_command_reload_map') && strlen(g:shell_command_reload_map)
    let l:keymap = g:shell_command_reload_map
  endif
  execute 'nnoremap <buffer> '.l:keymap.' :call <SID>RunShellCommandHere()<CR>'
endfunction "}}}

function! <SID>RunShellCommandHere() "{{{
  " get the shell command from the header line
  let l:header = getline(1)
  let l:prefix = matchstr(l:header, '^## Shelli\=:')
  if ! strlen(l:prefix)
    echoerr "File doesn't start with '## Shell:' or '## Shelli:"
    return
  endif

  let l:interactive = (l:prefix =~ 'Shelli')

  let l:command = strpart(l:header, strlen(l:prefix))

  " make sure we capture STDERR as well
  let l:cmd = '{ '.escape(l:command, '%#$!').'; }'

  " TODO: use the 'shellredir' option to either capture STDERR or engage
  " interactive mode ... interactive doesn't work currently
  " NOTE: currently the 2>&1 is needed, otherwise STDERR is prepended to STDOUT
  " which isn't really what you want
  if ! l:interactive
    let l:cmd .= ' 2>&1'
  endif

  " get ready for editing the file again
  setlocal modifiable noreadonly

  " Delete everything but the first line of the file. Also, this puts the
  " cursor in line 1 which is where we want to be for the :read call
  if line('$') > 1
    silent 2,$delete
    normal! G
  endif

  " if there is more than 1 line in the file, 
  " run the command and capture the output
  redraw!
  echohl MoreMsg
  echo printf('Buffer [%d]: %s', bufnr(''), l:command)
  echohl None

  echohl error
  try
    exe 'read !'.l:cmd
    let l:shell_error = v:shell_error

    " whether or not to use the 'col' utility to strip escape sequences (colors,
    " etc)
    if ! exists('g:shell_command_use_col') || g:shell_command_use_col
      if line('$') > 1
        2,$!col -bx
      endif
    endif
  finally
    echohl None
  endtry
  normal! gg

  " set options to prevent user editing by accident? No never mind
  setlocal nomodified

  if l:shell_error
    silent exe 'file ['.l:shell_error.']\ '.escape(l:command, '`|"\! #%')
  else
    silent exe 'file' escape(l:command, '`|"\! #%')
  endif
  redraw!
endfunction "}}}


" remove from :shell_buffers, any buffer numbers that no longer exist
function! <SID>CleanShellBuffersList() "{{{
  for l:bufnr in keys(s:shell_buffers)
    if ! bufexists(l:bufnr * 1)
      call remove(s:shell_buffers, l:bufnr)
    endif
  endfor
endfunction "}}}


" rerun shell commands in any buffers that are open in the current window
function! ShellCommandRerunAll() "{{{
  let l:origwinnr = winnr()
  try
    for l:bufnr in keys(s:shell_buffers)
      let l:winnr = bufwinnr(l:bufnr * 1)
      if l:winnr > -1
        " jump to the window
        exe l:winnr.'wincmd w'
        " rerun the shell command in this window
        silent call <SID>RunShellCommandHere()
      endif
    endfor
  finally
    " return to the original window
    exe l:origwinnr.'wincmd w'
  endtry
endfunction "}}}
