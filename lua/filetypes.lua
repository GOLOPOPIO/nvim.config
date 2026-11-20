-- Дополнительные типы файлов для .NET и работы с данными.
-- .cshtml и .razor Neovim 0.12 уже определяет как `razor`, здесь добавляем остальное.
-- ВАЖНО: vim.filetype.add сам анкорит pattern (^...$), поэтому якорей в шаблоне быть не должно.

vim.filetype.add({
  pattern = {
    -- XAML (MAUI, WPF, WinUI)
    ['.*%.xaml'] = 'xaml',
    ['.*%.axaml'] = 'xaml',

    -- проектные файлы .NET
    ['.*%.csproj'] = 'xml',
    ['.*%.props'] = 'xml',
    ['.*%.targets'] = 'xml',
    ['.*%.nuspec'] = 'xml',
    ['.*%.slnx'] = 'xml',
    ['.*%.csx'] = 'cs',

    -- PostgreSQL
    ['.*%.psql'] = 'sql',
    ['.*%.pgsql'] = 'sql',
    ['.*%.plpgsql'] = 'sql',
  },
})
