--syntax
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

vim.opt.completeopt = { "menu", "menuone", "noselect" }
 
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.bo[args.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
  end,
})
