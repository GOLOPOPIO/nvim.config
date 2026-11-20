-- Создание типичных файлов .NET по шаблонам из ~/.config/nvim/templates
-- Без плагинов: :Template [шаблон] [имя] [папка]
local M = {}

local template_dir = vim.fs.joinpath(vim.fn.stdpath('config'), 'templates')

-- files = { { файл шаблона, маска имени } }, %s подставляет имя
-- suffix добавляется к имени, если его ещё нет (Controller, DbContext, ...)
local specs = {
  { id = 'class', label = 'C# класс', files = { { 'class.cs', '%s.cs' } } },
  { id = 'interface', label = 'C# интерфейс', files = { { 'interface.cs', '%s.cs' } } },
  { id = 'record', label = 'C# record', files = { { 'record.cs', '%s.cs' } } },
  { id = 'struct', label = 'C# record struct', files = { { 'struct.cs', '%s.cs' } } },
  { id = 'enum', label = 'C# enum', files = { { 'enum.cs', '%s.cs' } } },
  {
    id = 'controller',
    label = 'ASP.NET API-контроллер',
    suffix = 'Controller',
    files = { { 'controller.cs', '%s.cs' } },
  },
  {
    id = 'razor-page',
    label = 'Razor Page (.cshtml + .cshtml.cs)',
    files = { { 'razor-page/Page.cshtml', '%s.cshtml' }, { 'razor-page/Page.cshtml.cs', '%s.cshtml.cs' } },
  },
  { id = 'razor-view', label = 'Razor View (MVC, .cshtml)', files = { { 'razor-view.cshtml', '%s.cshtml' } } },
  { id = 'blazor', label = 'Blazor-компонент (.razor)', files = { { 'blazor-component.razor', '%s.razor' } } },
  {
    id = 'maui-page',
    label = 'MAUI ContentPage (.xaml + .xaml.cs)',
    files = { { 'maui-page/Page.xaml', '%s.xaml' }, { 'maui-page/Page.xaml.cs', '%s.xaml.cs' } },
  },
  {
    id = 'viewmodel',
    label = 'View-Model (INotifyPropertyChanged)',
    suffix = 'ViewModel',
    files = { { 'viewmodel.cs', '%s.cs' } },
  },
  { id = 'entity', label = 'EF-сущность', suffix = nil, files = { { 'entity.cs', '%s.cs' } } },
  {
    id = 'dbcontext',
    label = 'EF DbContext',
    suffix = 'DbContext',
    files = { { 'dbcontext.cs', '%s.cs' } },
  },
  {
    id = 'middleware',
    label = 'ASP.NET middleware',
    suffix = 'Middleware',
    files = { { 'middleware.cs', '%s.cs' } },
  },
  {
    id = 'options',
    label = 'Класс настроек (IOptions)',
    suffix = 'Options',
    files = { { 'options.cs', '%s.cs' } },
  },
  { id = 'test', label = 'xUnit-тест', suffix = 'Tests', files = { { 'test.cs', '%s.cs' } } },
  { id = 'program', label = 'Program.cs (ASP.NET Razor Pages)', files = { { 'program-web.cs', 'Program.cs' } } },
  { id = 'sql', label = 'SQL-скрипт (PostgreSQL)', files = { { 'sql.sql', '%s.sql' } } },
  { id = 'html', label = 'HTML-страница', files = { { 'html.html', '%s.html' } } },
  { id = 'json', label = 'JSON-файл', files = { { 'json.json', '%s.json' } } },
  { id = 'xml', label = 'XML-файл', files = { { 'xml.xml', '%s.xml' } } },
}

local function sanitize_ns(part)
  part = part:gsub('[^%w_]', '_')
  if part:match('^%d') then
    part = '_' .. part
  end
  return part
end

-- Находит .csproj (приоритет) / .sln / global.json вверх по дереву и собирает namespace.
local function namespace_for(dir)
  local proj = vim.fs.find(function(name)
    return name:match('%.csproj$')
  end, { upward = true, path = dir, type = 'file', limit = 1 })[1]

  if not proj then
    proj = vim.fs.find(function(name)
      return name:match('%.slnx?$') or name == 'global.json'
    end, { upward = true, path = dir, type = 'file', limit = 1 })[1]
  end

  local root_ns
  local proj_dir

  if proj then
    proj_dir = vim.fs.dirname(proj)
    if proj:match('%.csproj$') then
      local ok, lines = pcall(vim.fn.readfile, proj)
      if ok then
        local text = table.concat(lines, '\n')
        root_ns = text:match('<RootNamespace>%s*([^<%s]+)')
      end
      root_ns = root_ns or vim.fs.basename(proj):gsub('%.csproj$', '')
    else
      -- .sln / global.json: имя solution как корень namespace
      root_ns = vim.fs.basename(proj):gsub('%.slnx?$', '')
      if root_ns == 'global' then
        root_ns = vim.fs.basename(proj_dir)
      end
    end
  end

  if not root_ns then
    -- проект не найден: используем имя папки как namespace
    local base = vim.fs.basename(dir)
    return sanitize_ns(base ~= '' and base or 'App')
  end

  local parts = { root_ns }
  if proj_dir then
    local rel = vim.fs.relpath(proj_dir, dir)
    if rel and rel ~= '.' then
      for part in rel:gmatch('[^/\\]+') do
        if part ~= '..' then
          parts[#parts + 1] = sanitize_ns(part)
        end
      end
    end
  end

  return table.concat(parts, '.')
end

-- Папка по умолчанию: каталог текущего файла / netrw / cwd
local function default_dir()
  local buf = vim.api.nvim_get_current_buf()
  local netrw_dir = vim.b[buf].netrw_curdir
  if netrw_dir and netrw_dir ~= '' then
    return netrw_dir
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name ~= '' and vim.fn.isdirectory(vim.fs.dirname(name)) == 1 then
    return vim.fs.dirname(name)
  end

  return vim.fn.getcwd()
end

local function render(text, vars)
  return (text:gsub('{{(%w+)}}', function(key)
    return vars[key] or ''
  end))
end

-- Возвращает отрендеренный текст и позицию курсора (строка, байт в строке, 1-based)
local function render_with_cursor(text, vars)
  local before, after = text:match('^([%s%S]-){{cursor}}(.*)$')
  if not before then
    return render(text, vars), nil
  end

  local head = render(before, vars)
  local tail = render(after, vars)
  local line = 1
  for _ in head:gmatch('\n') do
    line = line + 1
  end
  local col = #(head:match('[^\n]*$') or '')

  return head .. tail, { line, col }
end

local function normalize_name(name, suffix)
  name = vim.trim(name or ''):gsub('%.%w+$', '')
  if name == '' then
    return nil
  end
  if suffix and name:sub(-#suffix) ~= suffix then
    name = name .. suffix
  end
  return name
end

function M.create(spec, raw_name, dir)
  raw_name = vim.trim(raw_name or '')
  local name = normalize_name(raw_name, spec.suffix)
  if not name then
    vim.notify('Имя файла не может быть пустым', vim.log.levels.ERROR)
    return
  end

  dir = dir and vim.fs.normalize(vim.fn.expand(dir)) or default_dir()

  local vars = {
    name = name,
    raw = raw_name,
    namespace = namespace_for(dir),
    date = os.date('%Y-%m-%d'),
  }

  local created = {}
  local cursor

  for _, file in ipairs(spec.files) do
    local src = vim.fs.joinpath(template_dir, file[1])
    local ok, lines = pcall(vim.fn.readfile, src)
    if not ok then
      vim.notify('Шаблон не найден: ' .. src, vim.log.levels.ERROR)
      return
    end

    local dest = vim.fs.joinpath(dir, string.format(file[2], name))
    if vim.uv.fs_stat(dest) then
      local choice = vim.fn.confirm('Файл уже существует, перезаписать?\n' .. dest, '&Да\n&Нет', 2)
      if choice ~= 1 then
        return
      end
    end

    local text, pos = render_with_cursor(table.concat(lines, '\n'), vars)
    vim.fn.mkdir(vim.fs.dirname(dest), 'p')
    local wrote = vim.fn.writefile(vim.split(text, '\n', { plain = true }), dest)
    if wrote ~= 0 then
      vim.notify('Не удалось записать ' .. dest, vim.log.levels.ERROR)
      return
    end

    created[#created + 1] = dest
    if pos and not cursor then
      cursor = { dest = dest, pos = pos }
    end
  end

  if #created == 0 then
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(created[1]))
  if cursor and cursor.dest == created[1] then
    pcall(vim.api.nvim_win_set_cursor, 0, cursor.pos)
  end
  for i = 2, #created do
    vim.cmd.badd(vim.fn.fnameescape(created[i]))
  end

  vim.notify('Создано: ' .. table.concat(created, ', '), vim.log.levels.INFO)
end

function M.prompt_name(spec)
  local dir = default_dir()
  vim.ui.input({ prompt = 'Имя файла (' .. M.namespace_hint(dir) .. '): ' }, function(input)
    if not input or vim.trim(input) == '' then
      return
    end
    M.create(spec, input, dir)
  end)
end

function M.namespace_hint(dir)
  return 'namespace: ' .. namespace_for(dir)
end

function M.pick()
  vim.ui.select(specs, {
    prompt = 'Шаблон файла:',
    format_item = function(item)
      return item.label
    end,
  }, function(spec)
    if spec then
      M.prompt_name(spec)
    end
  end)
end

local function find_spec(id)
  for _, spec in ipairs(specs) do
    if spec.id == id then
      return spec
    end
  end
end

vim.api.nvim_create_user_command('Template', function(opts)
  local args = vim.split(vim.trim(opts.args), '%s+', { trimempty = true })
  if #args == 0 then
    M.pick()
    return
  end

  local spec = find_spec(args[1])
  if not spec then
    local ids = {}
    for _, item in ipairs(specs) do
      ids[#ids + 1] = item.id
    end
    vim.notify('Неизвестный шаблон: ' .. args[1] .. '\nДоступно: ' .. table.concat(ids, ', '), vim.log.levels.ERROR)
    return
  end

  if #args < 2 then
    M.prompt_name(spec)
    return
  end

  M.create(spec, args[2], args[3])
end, {
  nargs = '*',
  desc = 'Создать файл из шаблона',
  complete = function(arg_lead)
    local ids = {}
    for _, item in ipairs(specs) do
      if item.id:match('^' .. vim.pesc(arg_lead)) then
        ids[#ids + 1] = item.id
      end
    end
    return ids
  end,
})

return M
