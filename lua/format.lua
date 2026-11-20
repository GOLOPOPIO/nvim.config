-- Внешние форматтеры без плагинов: csharpier для C#, stylua для Lua.
-- Остальные filetypes форматируются через LSP (см. lua/keymap.lua).
local M = {}

local function exepath(name)
  local path = vim.fn.exepath(name)
  return path ~= '' and path or nil
end

local function dotnet_tool(name)
  local path = vim.fs.joinpath(vim.env.HOME or '', '.dotnet', 'tools', name)
  if vim.fn.executable(path) == 1 then
    return path
  end
  return nil
end

local tools = {
  cs = {
    name = 'csharpier',
    exe = exepath('csharpier') or dotnet_tool('csharpier'),
    -- форматирует stdin и печатает результат в stdout
    args = function(path)
      return { 'format', '--stdin-path', path }
    end,
  },
  lua = {
    name = 'stylua',
    exe = exepath('stylua'),
    args = function(path)
      return { '--stdin-filepath', path, '-' }
    end,
  },
}

function M.has_tool(ft)
  local tool = tools[ft or vim.bo.filetype]
  return tool ~= nil and tool.exe ~= nil
end

--- Форматирует буфер внешним форматтером.
-- true  — буфер обработан (даже если изменений не потребовалось);
-- false — форматтера нет, буфер без имени или в коде синтаксические ошибки.
function M.run(bufnr, opts)
  opts = opts or {}
  bufnr = bufnr or 0

  local tool = tools[vim.bo[bufnr].filetype]
  if not tool or not tool.exe then
    return false
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(lines, '\n') .. '\n'

  local res = vim.system(vim.list_extend({ tool.exe }, tool.args(path)), {
    stdin = input,
    text = true,
  }):wait(15000)

  if res.code ~= 0 then
    if opts.notify_errors then
      local msg = vim.trim(res.stderr or '')
      vim.notify(
        tool.name .. ': ' .. (msg ~= '' and msg or ('ошибка, код ' .. tostring(res.code))),
        vim.log.levels.WARN
      )
    end
    return false
  end

  local out = res.stdout or ''
  if out == '' then
    return false
  end

  local formatted = vim.split((out:gsub('\n$', '')), '\n', { plain = true })
  if vim.deep_equal(formatted, lines) then
    return true
  end

  -- сохраняем позицию курсора/скролл вокруг замены
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
  if vim.api.nvim_get_current_buf() == bufnr then
    vim.fn.winrestview(view)
  end

  return true
end

vim.api.nvim_create_user_command('Csharpier', function()
  if vim.bo.filetype ~= 'cs' then
    vim.notify('csharpier форматирует только C#', vim.log.levels.WARN)
    return
  end
  if not tools.cs.exe then
    vim.notify('csharpier не найден. Установи: dotnet tool install -g csharpier', vim.log.levels.ERROR)
    return
  end
  if M.run(0, { notify_errors = true }) then
    vim.notify('csharpier: буфер отформатирован (сохрани :w)', vim.log.levels.INFO)
  end
end, { desc = 'Форматировать текущий C#-файл через csharpier' })

return M
