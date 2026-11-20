-- Команды для работы с .NET без плагинов.
-- :Dotnet build | run | test | watch | restore | format | publish ... (аргументы пробрасываются)
-- :DotnetNew — интерактивное создание проекта из `dotnet new`
-- Ошибки сборки попадают в quickfix (:copen), запуск идёт в терминале.
local M = {}

local EFM = table.concat({
  '%E%f(%l\\,%c): error %m',
  '%W%f(%l\\,%c): warning %m',
  '%E%f(%l): error %m',
  '%W%f(%l): warning %m',
  '%E%f: error %m',
  '%W%f: warning %m',
  '%Eerror %m',
  '%Wwarning %m',
  '%-G%.%#', -- остальные строки сборки в quickfix не нужны
}, ',')

-- Корень проекта: вверх до .sln/.slnx/.csproj/global.json
function M.root(start)
  if not start or start == '' then
    local name = vim.api.nvim_buf_get_name(0)
    -- netrw-буфер: именем служит сама директория
    if name ~= '' and vim.fn.isdirectory(name) == 1 then
      start = name
    else
      start = vim.fn.expand('%:p:h')
    end
  end
  if start == '' or vim.fn.isdirectory(start) == 0 then
    start = vim.fn.getcwd()
  end

  -- предпочитаем solution: dotnet build соберёт весь solution
  local found = vim.fs.find(function(name)
    return name:match('%.slnx?$')
  end, { upward = true, path = start, type = 'file', limit = 1 })[1]

  found = found or vim.fs.find(function(name)
    return name:match('%.csproj$') or name == 'global.json'
  end, { upward = true, path = start, type = 'file', limit = 1 })[1]

  return found and vim.fs.dirname(found) or start
end

-- Разбирает вывод MSBuild по errorformat и делает пути абсолютными.
local function fill_qflist(title, output, root)
  local lines = vim.split(output, '\n', { trimempty = true })
  vim.fn.setqflist({}, ' ', { title = title, lines = lines, efm = EFM })

  local items = vim.fn.getqflist()
  local seen = {}
  local unique = {}
  for _, item in ipairs(items) do
    if item.bufnr and item.bufnr > 0 then
      local name = vim.api.nvim_buf_get_name(item.bufnr)
      if name ~= '' and not name:match('^/') then
        item.bufnr = vim.fn.bufadd(vim.fs.joinpath(root, name))
        item.valid = 1
      end
    end

    -- MSBuild печатает ошибку дважды (при компиляции и в итоге) — убираем дубли
    local key = string.format('%s:%d:%d:%s', item.bufnr, item.lnum, item.col, item.text or '')
    if not seen[key] then
      seen[key] = true
      unique[#unique + 1] = item
    end
  end

  vim.fn.setqflist({}, 'r', { title = title, items = unique })
  return #unique
end

local function report(title, code, output, root, opts)
  opts = opts or {}
  local errors = fill_qflist(title, output, root)
  if errors > 0 then
    vim.cmd.copen()
  end

  local level = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
  local summary = code == 0 and (title .. ' — успешно')
    or (title .. ' — ошибка (код ' .. tostring(code) .. '), см. quickfix')
  if errors > 0 then
    summary = summary .. '; проблем: ' .. errors
  end

  -- последние строки вывода полезны при ошибках и при создании проекта
  if code ~= 0 or opts.show_output then
    local tail = vim.trim(table.concat(vim.split(output, '\n'), '\n'))
    local tail_lines = vim.split(tail, '\n', { trimempty = true })
    local extra = {}
    for i = math.max(1, #tail_lines - 4), #tail_lines do
      extra[#extra + 1] = tail_lines[i]
    end
    if #extra > 0 then
      summary = summary .. '\n' .. table.concat(extra, '\n')
    end
  end

  vim.notify(summary, level)
end

local function run_capture(args, opts)
  opts = opts or {}
  local root = opts.cwd or M.root()
  local title = 'dotnet ' .. table.concat(args, ' ')

  vim.notify(title .. ' …', vim.log.levels.INFO)
  vim.system(vim.list_extend({ 'dotnet' }, args), { cwd = root, text = true }, function(obj)
    local output = table.concat({ obj.stdout or '', obj.stderr or '' }, '\n')
    vim.schedule(function()
      report(title, obj.code, output, root, opts)
    end)
  end)
end

local function run_terminal(args)
  local root = M.root()
  vim.cmd.botright('15split')
  vim.cmd('lcd ' .. vim.fn.fnameescape(root))
  vim.cmd('terminal dotnet ' .. table.concat(args, ' '))
  vim.cmd.startinsert()
end

local function split_args(str)
  local args = vim.split(vim.trim(str or ''), '%s+', { trimempty = true })
  return args
end

-- Разбор `dotnet new list`
local function list_templates(callback)
  vim.system({ 'dotnet', 'new', 'list' }, { text = true }, function(obj)
    local out = table.concat({ obj.stdout or '', obj.stderr or '' }, '\n')
    local templates = {}
    local in_table = false

    for _, line in ipairs(vim.split(out, '\n')) do
      if line:match('^%-%-%-') then
        in_table = true
      elseif in_table and line:match('%S') then
        local cols = vim.split(line, '%s%s+', { trimempty = true })
        if #cols >= 3 then
          templates[#templates + 1] = {
            name = cols[1],
            short = cols[2],
            language = cols[3],
            tags = cols[4] or '',
          }
        end
      end
    end

    vim.schedule(function()
      callback(templates)
    end)
  end)
end

vim.api.nvim_create_user_command('Dotnet', function(opts)
  local args = split_args(opts.args)
  if #args == 0 then
    vim.notify('Использование: :Dotnet build | run | test | watch | restore | format | publish ...', vim.log.levels.INFO)
    return
  end

  local cmd = args[1]
  if cmd == 'run' or cmd == 'watch' then
    run_terminal(args)
  elseif cmd == 'new' then
    run_capture(args, { show_output = true })
  else
    run_capture(args)
  end
end, {
  nargs = '*',
  desc = 'Запустить dotnet (build/test/run/watch/…) в корне проекта',
  complete = function()
    return { 'build', 'run', 'test', 'watch', 'restore', 'format', 'publish', 'clean', 'pack', 'list', 'new' }
  end,
})

vim.api.nvim_create_user_command('DotnetNew', function()
  list_templates(function(templates)
    if #templates == 0 then
      vim.notify('Не удалось получить список шаблонов dotnet new', vim.log.levels.ERROR)
      return
    end

    local choices = {}
    for _, t in ipairs(templates) do
      choices[#choices + 1] = t
    end

    vim.ui.select(choices, {
      prompt = 'dotnet new:',
      format_item = function(t)
        return string.format('%-45s %s', vim.trim(t.name), t.short)
      end,
    }, function(template)
      if not template then
        return
      end

      local root = M.root()
      vim.ui.input({ prompt = 'Имя проекта: ', default = vim.fs.basename(root) }, function(name)
        if not name or vim.trim(name) == '' then
          return
        end

        local args = { 'new', template.short, '-n', vim.trim(name) }
        vim.ui.input({ prompt = 'Папка (Enter — текущая): ', default = '.' }, function(dir)
          if dir and vim.trim(dir) ~= '' and vim.trim(dir) ~= '.' then
            args[#args + 1] = '-o'
            args[#args + 1] = vim.fs.normalize(vim.fn.expand(vim.trim(dir)))
          end
          run_capture(args, { cwd = root, show_output = true })
        end)
      end)
    end)
  end)
end, { desc = 'Создать проект через dotnet new' })

-- :make и внешние сборщики — тоже через dotnet
vim.o.makeprg = 'dotnet build'
vim.o.errorformat = EFM

return M
