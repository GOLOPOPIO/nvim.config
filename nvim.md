# Neovim: настройки и шпаргалка

Актуально на ноябрь 2026. Конфиг: `~/.config/nvim` (Neovim 0.12.5, .NET SDK 10).
Подход прежний — **минимум плагинов**: внешних плагинов нет вообще, только то, что встроено в Neovim + LSP-серверы и `csharpier`.

## Что настроено

| Что | Чем |
| --- | --- |
| C# / ASP.NET / MAUI | `csharp-ls` (Roslyn LSP), `csharpier` для форматирования |
| Razor (`.cshtml`, `.razor`) | собственный syntax: HTML + C# внутри Razor-блоков |
| XAML (`.xaml`, `.axaml`) | XML + `{Binding}`, `x:Class` |
| PostgreSQL | `sql.vim` + доп. подсветка `RETURNING`, `ON CONFLICT`, `::`, `jsonb_*`, `\dt` |
| HTML / XML / JSON | встроенный syntax + matchit |
| Python | `pyright` + `ruff` |
| Lua | `lua_ls` + `stylua` при сохранении |
| Автодополнение | встроенное `vim.lsp.completion` (без nvim-cmp) |
| Файлы-шаблоны | `:Template` без плагинов (`templates/` + Lua) |
| Сборка/тесты | `:Dotnet ...` с выводом ошибок в quickfix |

## Структура конфига

```
~/.config/nvim/
├── init.lua              -- точка входа
├── lua/
│   ├── options.lua       -- netrw, clipboard, отступы, matchit
│   ├── colors.lua        -- retrobox, прозрачный фон, номера строк
│   ├── keymap.lua        -- хоткеи, автоформат при сохранении
│   ├── filetypes.lua     -- .xaml/.csproj/.psql и т.д.
│   ├── dotnet.lua        -- :Dotnet, :DotnetNew, quickfix
│   ├── templates.lua     -- :Template (создание файлов)
│   ├── format.lua        -- csharpier
│   └── lsp/
│       ├── init.lua      -- syntax on, completeopt, автодополнение LSP
│       ├── csharp.lua    -- csharp_ls
│       ├── python.lua    -- pyright + ruff
│       ├── lua.lua       -- lua_ls + stylua
│       └── php.lua       -- (пусто намеренно)
├── syntax/               -- razor.vim, xaml.vim
├── ftplugin/             -- razor.vim, xaml.vim
├── indent/               -- razor.vim, xaml.vim
├── after/syntax/         -- cs.vim (C# 11+), sql.vim (PostgreSQL)
├── templates/            -- заготовки файлов
└── cheatsheet.md         -- шпаргалка по Vim + .NET-раздел
```

Бекап конфига до последней настройки: `~/.config/nvim.old`.

## Типы файлов и подсветка

| Файлы | filetype | Что подсвечивается |
| --- | --- | --- |
| `*.cs` | cs | C# + `required`, `file`, `scoped`, `with { }` |
| `*.cshtml`, `*.razor` | razor | HTML, C# в `@{ }`, `@code { }`, `@(...)`, `@Model.X`, `@if/@foreach`, `@page/@model/@inject/@using`, Blazor `@onclick/@bind` |
| `*.xaml`, `*.axaml` | xaml | XML, `{Binding}`, `{StaticResource}`, `{x:Static}`, `x:Class`/`x:Name` |
| `*.csproj`, `*.props`, `*.targets`, `*.nuspec`, `*.slnx` | xml | обычный XML |
| `*.sql`, `*.psql`, `*.pgsql`, `*.plpgsql` | sql | PostgreSQL-специфика (см. выше) |
| `*.json`, `*.html`, `*.xml` | встроенные | как в стандартном Neovim |
| `*.csx` | cs | C#-скрипты |

`%` ходит по парным тегам в HTML/XML/XAML/Razor (встроенный matchit).

## Шаблоны файлов — `:Template` / `<M-n>`

`:Template` — интерактивное меню; `:Template <шаблон> [имя] [папка]` — сразу.
Файл создаётся в папке текущего файла (в netrw — в открытой папке), курсор ставится в нужное место.
Namespace берётся из ближайшего `.csproj` (`RootNamespace`), иначе из `.sln`/`global.json`, плюс подпапки: `Pages/Account` → `App.Pages.Account`.

| Шаблон | Результат |
| --- | --- |
| `class`, `interface`, `record`, `struct`, `enum` | C#-файл с file-scoped namespace |
| `controller Products` | `ProductsController.cs` (api-контроллер) |
| `razor-page Index Pages` | `Pages/Index.cshtml` + `Pages/Index.cshtml.cs` |
| `razor-view` | MVC-представление `.cshtml` |
| `blazor` | Blazor-компонент `.razor` |
| `maui-page MainPage Views` | `MainPage.xaml` + `MainPage.xaml.cs` |
| `viewmodel` | ViewModel с `INotifyPropertyChanged` |
| `dbcontext`, `entity`, `middleware`, `options`, `test`, `program` | типовые классы .NET |
| `sql`, `html`, `json`, `xml` | заготовки файлов |

Суффиксы подставляются автоматически: `:Template test Orders` → `OrdersTests.cs`, `:Template controller Products` → `ProductsController.cs`, `:Template options Mail` → `MailOptions.cs` (внутри `SectionName = "Mail"`).

Свои шаблоны: файл в `~/.config/nvim/templates/` + строка в списке `specs` в `lua/templates.lua`. Плейсхолдеры: `{{name}}`, `{{raw}}`, `{{namespace}}`, `{{cursor}}`, `{{date}}`.

## Команды dotnet

| Команда | Действие |
| --- | --- |
| `:Dotnet build` | сборка, ошибки в quickfix (`:copen`), дубли MSBuild убираются |
| `:Dotnet test` | тесты, ошибки в quickfix |
| `:Dotnet run`, `:Dotnet watch` | запуск в терминале (сплит снизу) |
| `:Dotnet restore/format/publish/pack/clean/...` | пробрасываются в `dotnet` |
| `:Dotnet new ...` | вывод с результатом в уведомлении |
| `:DotnetNew` | интерактивно: список шаблонов SDK → имя → папка |
| `:make` | то же, что `:Dotnet build` (`makeprg=dotnet build`) |

Корень проекта ищется вверх по дереву, приоритет у `.sln`/`.slnx`, затем `.csproj`/`global.json`.

Быстрые клавиши: `<M-b>` build, `<M-t>` test, `<M-r>r` run.

## Форматирование

- **C# (`*.cs`)** — `csharpier` 1.4.0 (`dotnet tool install -g csharpier`), CLI, без плагинов:
  - автоформат при сохранении;
  - `<M-f>` — отформатировать вручную;
  - `:Csharpier` — форматирует буфер (сохранить — `:w`), при синтаксических ошибках покажет их;
  - при синтаксических ошибках сохранение не падает, форматирование просто пропускается;
  - учитываются `.editorconfig`, `.csharpierrc.json`, `.csharpierignore` проекта.
- **Lua (`*.lua`)** — `stylua` при сохранении (через `vim.system`, без `:!` и «Press ENTER»).
- **Остальные filetypes** — LSP-formatting при сохранении, если сервер умеет (`ruff` для python и т.п.).
- `<M-f>` без доступного форматтера честно скажет «Нет форматтера для filetype=...».

## Хоткеи

| Клавиши | Действие |
| --- | --- |
| `b<Tab>` | список буферов + переход (`:ls` + `:b`) |
| `<M-r>n` | переименовать символ (LSP rename) |
| `<M-e>` | диагностика под курсором |
| `<M-f>` | форматировать буфер |
| `<M-n>` | меню шаблонов файлов |
| `<M-b>` | `dotnet build` |
| `<M-t>` | `dotnet test` |
| `<M-r>r` | `dotnet run` |

`<M-...>` = Alt (Option) + клавиша. В терминале может понадобиться включить «Option as Meta» (iTerm2: Profiles → Keys → Left Option key = Esc+).

## Прочие настройки

- `colorscheme retrobox`, прозрачный фон, `number` + `relativenumber`, свой `statuscolumn`;
- отступы: 4 пробела (`expandtab`, `shiftwidth=4`);
- netrw: `:Ex`, древовидный вид (`netrw_liststyle=3`); в netrw `%` создаёт файл, не переходя в него;
- `:ls`/`:b` с wildmenu и popup-меню;
- буфер обмена по OSC 52 (работает и по ssh);
- `completeopt = menu,menuone,noselect`, автодополнение от LSP включается на `LspAttach`;
- формат при сохранении срабатывает только если есть форматтер.

## Шпаргалка по Vim

### Перемещение (Normal mode)

| Клавиши | Действие |
| --- | --- |
| h j k l | влево / вниз / вверх / вправо |
| w / W, b / B, e / E | слово / WORD вперёд-назад |
| 0, ^, $ | начало строки / первый непробел / конец строки |
| gg, G, `{n}G` | начало файла / конец / строка n |
| `{` / `}` | абзац назад / вперёд |
| `%` | парная скобка или тег |
| f{c}, t{c}, ; , | прыжок к символу и повтор |
| Ctrl-d / Ctrl-u, Ctrl-f / Ctrl-b | прокрутка |
| zz / zt / zb | центрировать / наверх / вниз |
| H / M / L | верх / середина / низ экрана |
| m{a}, `\`{a}, '{a} | метка, переход к метке |
| Ctrl-o / Ctrl-i | назад / вперёд по jumplist |

### Поиск

| Клавиши | Действие |
| --- | --- |
| `/`, `?` | поиск вперёд / назад |
| n / N | следующий / предыдущий результат |
| `*` / `#` | слово под курсором вперёд / назад |

### Редактирование

| Клавиши | Действие |
| --- | --- |
| i / a, I / A, o / O | вход в insert разными способами |
| x / X, dd, D | удаление символа / строки / до конца строки |
| yy, p / P | копировать строку, вставить после / перед |
| cw / ciw, cc | изменить слово / строку |
| u, Ctrl-r, . | отмена, повтор отмены, повтор изменения |
| r{c}, R | заменить символ / режим замены |
| J | склеить строки |
| `~` | сменить регистр |
| >> / <<, == | отступы |

### Визуальный режим

| Клавиши | Действие |
| --- | --- |
| v / V / Ctrl-v | посимвольно / построчно / блочно |
| gv | вернуть последнее выделение |
| o | другой конец выделения |
| d / y, > / < | удалить / скопировать, сдвинуть отступ |

### Текстовые объекты (после d/c/y/v)

| Объект | Значение |
| --- | --- |
| iw / aw | слово |
| i" a" / i( a( / i{ a{ / i[ a[ | внутри / вместе со скобками или кавычками |
| it / at | внутри / вместе с HTML-тегом |
| ip / ap | абзац |

### Регистры и макросы

| Клавиши | Действие |
| --- | --- |
| `"{a}yy`, `"{a}p` | копировать в регистр / вставить из регистра |
| `"0p` | вставить последний yank |
| q{a} ... q, @{a}, @@ | запись и повтор макроса |

### Буферы и вкладки

| Команда | Действие |
| --- | --- |
| `:e {file}`, `:ls`, `:b {N}` | открыть, список, перейти |
| `:bn` / `:bp`, `:bd` | следующий / предыдущий / закрыть |
| Ctrl-^ | предыдущий буфер |
| `:tabnew`, gt / gT, `{N}gt`, `:tabclose` | вкладки |

### netrw (`:Ex`)

| Клавиша | Действие |
| --- | --- |
| Enter | открыть файл / войти в папку |
| - | вверх на директорию |
| i | стиль отображения |
| gh | скрытые файлы |
| s / r | сортировка / обратная сортировка |
| % | создать файл (у тебя — без перехода в буфер) |
| d, D, R | создать папку, удалить, переименовать |
| mf, mt, mc, mm, mu | пометки, цель, копировать, переместить, снять |
| o / v / t | открыть в сплите / вертикальном сплите / новой вкладке |
| p, qf, x | предпросмотр, информация, открыть системной программой |

## Если что-то не работает

| Симптом | Что проверить |
| --- | --- |
| C# без автодополнения | `:lua =vim.lsp.get_clients()`, `dotnet tool list -g`, `csharp-ls --version` |
| `csharpier` не найден | `csharpier --version`; бинарь в `~/.dotnet/tools`, PATH должен его видеть |
| Формат не срабатывает при сохранении | filetype должен быть `cs`, файл должен иметь имя (не scratch) |
| `:Dotnet` не находит проект | открой файл внутри папки проекта или `:cd` в корень |
| Нет подсветки Razor | `:set ft?` должен быть `razor`; syntax лежит в `~/.config/nvim/syntax/razor.vim` |
| Логи LSP | `:lua vim.print(vim.lsp.get_log_path())` |
