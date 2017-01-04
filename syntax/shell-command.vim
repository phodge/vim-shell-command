if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syntax region Comment start=/^\%1l## Shelli\=:/ end=/$/
