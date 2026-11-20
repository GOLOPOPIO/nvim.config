-- C# / ASP.NET / MAUI: csharp-ls (Roslyn) из ~/.dotnet/tools
vim.lsp.config('csharp_ls', {
    cmd = { 'csharp-ls' },

    filetypes = { 'cs' },

    root_markers = {
        function(name)
            return name:match('%.slnx?$')
                or name:match('%.csproj$')
        end,
        'global.json',
        'Directory.Build.props',
        'Directory.Packages.props',
        '.git',
    },

    init_options = {
        AutomaticWorkspaceInit = true,
    },
})

vim.lsp.enable('csharp_ls')

if vim.fn.executable('csharp-ls') == 0 then
    vim.schedule(function()
        vim.notify(
            'csharp-ls не найден в PATH. Установи: dotnet tool install -g csharp-ls',
            vim.log.levels.WARN
        )
    end)
end
