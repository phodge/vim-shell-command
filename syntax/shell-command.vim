if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn match shComment "^##.*$"


hi def link shComment Comment
