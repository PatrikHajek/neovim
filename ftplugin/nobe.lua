--@ Set comment format for Comment.nvim.
vim.bo.commentstring = '// %s'

--@ `b:` means it needs a blank (space) after.
vim.bo.comments = 'b://'

--@ Enable continuation on Enter ('r') and on 'o'/'O' ('o').
vim.opt_local.formatoptions:append('ro')
