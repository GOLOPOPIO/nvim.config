-- colors
vim.opt.termguicolors = true      -- true color, иначе многие темы будут выглядеть иначе
vim.cmd.colorscheme("retrobox")

local function transparent_bg()
  local groups = {
    "Normal", "NormalNC", "NormalFloat",
    "SignColumn", "EndOfBuffer", "LineNr",
    "FoldColumn", "VertSplit", "WinSeparator",
  }
  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = transparent_bg })
transparent_bg()

-- line num
vim.opt.number = true
vim.opt.relativenumber = true

_G.statuscolumn = function()
  local width = math.max(3, #tostring(vim.api.nvim_buf_line_count(0)))
  local num
  if vim.v.relnum == 0 then
    num = string.format("%-" .. width .. "d", vim.v.lnum)
  else
    num = string.format("%" .. width .. "d", vim.v.relnum)
  end
  return "%s" .. num .. " %#NonText#│%* "
end

vim.opt.statuscolumn = "%!v:lua.statuscolumn()"

