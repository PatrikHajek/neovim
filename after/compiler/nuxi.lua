--[[
To iterate quickly on trying if the errorformat string works, you can use
`set efm=<the format string>` to set the current errorformat and
`cexpr "<test string>"` to populate quickfix list with this entry. For example:

```
set efm=%f(%l\\,%c):\ error\ TS%n:\ %m
cexpr "src/test.ts(10,5): error TS1234: Manual test message"
```
--]]

vim.api.nvim_buf_set_var(0, 'current_compiler', 'nuxi')

vim.opt_local.makeprg = [[NO_COLOR=1 pnpm nuxi typecheck]]

vim.opt_local.errorformat = {
  [[%f(%l\,%c):\ %trror\ TS%n:\ %m]],
  [[%-G%[ℹ✔]%.%#]], -- ignore the info output at the start
  [[%-G\ ERROR\ %.%#]], -- ignore the big ERROR block
  [[%-G\ \ \ \ at\ %.%#]], -- ignore stack traces
  [[%-G%\\s%#]], -- ignore lines that are only whitespace
  [[%-G]], -- ignore totally empty lines
  [[%-G%.%#]],
}
