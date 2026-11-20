vim.keymap.set('n', 'b<Tab>', ':ls<CR>:b<Space>')

--- LSP
vim.keymap.set('n', '<M-r>n', vim.lsp.buf.rename, { desc = 'Переименовать символ' })
vim.keymap.set('n', '<M-e>', vim.diagnostic.open_float, { desc = 'Показать диагностику под курсором' })

vim.keymap.set('n', '<M-f>', function()
	local formatter = require('format')
	local ft = vim.bo.filetype

	if formatter.has_tool(ft) then
		formatter.run(0, { notify_errors = true })
		return
	end

	local clients = vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/formatting' })
	if #clients == 0 then
		vim.notify('Нет форматтера для filetype=' .. ft, vim.log.levels.WARN)
		return
	end
	vim.lsp.buf.format({ async = true })
end, { desc = 'Форматировать буфер' })

--- Автоформатирование при сохранении
-- C# — csharpier, Lua — stylua, остальное — LSP
vim.api.nvim_create_autocmd('BufWritePre', {
	callback = function(args)
		local formatter = require('format')
		local ft = vim.bo[args.buf].filetype

		if formatter.has_tool(ft) then
			formatter.run(args.buf)
			return
		end

		local clients = vim.lsp.get_clients({ bufnr = args.buf, method = 'textDocument/formatting' })
		if #clients == 0 then
			return
		end
		vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 2000 })
	end,
})

--- .NET
vim.keymap.set('n', '<M-n>', '<cmd>Template<cr>', { desc = 'Новый файл из шаблона' })
vim.keymap.set('n', '<M-b>', '<cmd>Dotnet build<cr>', { desc = 'dotnet build → quickfix' })
vim.keymap.set('n', '<M-t>', '<cmd>Dotnet test<cr>', { desc = 'dotnet test → quickfix' })
vim.keymap.set('n', '<M-r>r', '<cmd>Dotnet run<cr>', { desc = 'dotnet run в терминале' })
