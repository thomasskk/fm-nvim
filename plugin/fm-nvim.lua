vim.cmd("command! -nargs=? -complete=dir Nnn :lua require('fm-nvim').Nnn(<f-args>)")
