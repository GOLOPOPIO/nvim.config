-- :Ex
vim.g.netrw_liststyle = 3
vim.g.netrw_keepdir = 0
vim.g.netrw_keepdir = 0

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'netrw',
  callback = function()
    vim.keymap.set('n', '%', function()
      local name = vim.fn.input('Новый файл: ')
      if name == '' then return end
      local dir = vim.b.netrw_curdir
      local path = dir .. '/' .. name
      vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p') -- на случай sub/dir/file.txt
      vim.fn.writefile({}, path)
      vim.cmd('e ' .. vim.fn.fnameescape(dir)) -- обновить список
    end, { buffer = true, desc = 'Создать файл без перехода в его буфер' })
  end,
})

-- ssh clipboard
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- buffer
vim.opt.wildmenu = true
vim.opt.wildmode = 'longest:full,full'
vim.opt.wildoptions = 'pum'
vim.opt.showtabline = 1  -- дефолт: показывать только если вкладок больше 1 (авто)

-- отступы для C#/HTML/JSON/XML/SQL
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- встроенный matchit: % по парным тегам HTML/XML/XAML/Razor (без плагинов)
pcall(vim.cmd, 'packadd matchit')
