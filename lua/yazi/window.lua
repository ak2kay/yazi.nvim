local M = {}

---@class YaziFloatingWindow
---@field win integer floating_window_id
---@field border_window integer
---@field content_buffer integer
---@field config YaziConfig
local YaziFloatingWindow = {}
YaziFloatingWindow.__index = YaziFloatingWindow

M.YaziFloatingWindow = YaziFloatingWindow

---@param config YaziConfig
function YaziFloatingWindow.new(config)
  local self = setmetatable({}, YaziFloatingWindow)

  self.config = config

  return self
end

function YaziFloatingWindow:close()
  if
    vim.api.nvim_buf_is_valid(self.content_buffer)
    and vim.api.nvim_buf_is_loaded(self.content_buffer)
  then
    vim.api.nvim_buf_delete(self.content_buffer, { force = true })
  end

  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end

  if vim.api.nvim_win_is_valid(self.border_window) then
    vim.api.nvim_win_close(self.border_window, true)
  end
end

function YaziFloatingWindow:open_and_display()
  local height = math.ceil(
    vim.o.lines * self.config.floating_window_scaling_factor
  ) - 1
  local width =
    math.ceil(vim.o.columns * self.config.floating_window_scaling_factor)

  local row = math.ceil(vim.o.lines - height) / 2
  local col = math.ceil(vim.o.columns - width) / 2

  local border_opts = {
    style = 'minimal',
    relative = 'editor',
    row = row - 1,
    col = col - 1,
    width = width + 2,
    height = height + 2,
  }

  local opts = {
    style = 'minimal',
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
  }

  local topleft, top, topright, right, botright, bot, botleft, left =
    '╭', '─', '╮', '│', '╯', '─', '╰', '│'

  local border_lines = { topleft .. string.rep(top, width) .. topright }
  local middle_line = left .. string.rep(' ', width) .. right
  for _ = 1, height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, botleft .. string.rep(bot, width) .. botright)

  -- create a unlisted scratch buffer for the border
  local border_buffer = vim.api.nvim_create_buf(false, true)

  -- set border_lines in the border buffer from start 0 to end -1 and strict_indexing false
  vim.api.nvim_buf_set_lines(border_buffer, 0, -1, true, border_lines)
  -- create border window
  local border_window = vim.api.nvim_open_win(border_buffer, true, border_opts)
  vim.api.nvim_set_hl(0, 'YaziBorder', { link = 'Normal', default = true })
  vim.cmd('set winhl=NormalFloat:YaziBorder')

  local yazi_buffer = vim.api.nvim_create_buf(false, true)
  -- create file window, enter the window, and use the options defined in opts
  local win = vim.api.nvim_open_win(yazi_buffer, true, opts)

  vim.bo[yazi_buffer].filetype = 'yazi'

  vim.cmd('setlocal bufhidden=hide')
  vim.cmd('setlocal nocursorcolumn')
  vim.api.nvim_set_hl(0, 'YaziFloat', { link = 'Normal', default = true })
  vim.cmd('setlocal winhl=NormalFloat:YaziFloat')
  vim.cmd('set winblend=' .. self.config.yazi_floating_window_winblend)

  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = yazi_buffer,
    callback = function()
      self:close()
    end,
  })

  self.win = win
  self.border_window = border_window
  self.content_buffer = yazi_buffer

  return self
end

--- open a floating window with nice borders
---@param config YaziConfig
---@return integer, integer, integer
function M.open_floating_window(config)
  local height = math.ceil(vim.o.lines * config.floating_window_scaling_factor)
    - 1
  local width = math.ceil(vim.o.columns * config.floating_window_scaling_factor)

  local row = math.ceil(vim.o.lines - height) / 2
  local col = math.ceil(vim.o.columns - width) / 2

  local border_opts = {
    style = 'minimal',
    relative = 'editor',
    row = row - 1,
    col = col - 1,
    width = width + 2,
    height = height + 2,
  }

  local opts = {
    style = 'minimal',
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height,
  }

  local topleft, top, topright, right, botright, bot, botleft, left =
    '╭', '─', '╮', '│', '╯', '─', '╰', '│'

  local border_lines = { topleft .. string.rep(top, width) .. topright }
  local middle_line = left .. string.rep(' ', width) .. right
  for _ = 1, height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, botleft .. string.rep(bot, width) .. botright)

  -- create a unlisted scratch buffer for the border
  local border_buffer = vim.api.nvim_create_buf(false, true)

  -- set border_lines in the border buffer from start 0 to end -1 and strict_indexing false
  vim.api.nvim_buf_set_lines(border_buffer, 0, -1, true, border_lines)
  -- create border window
  local border_window = vim.api.nvim_open_win(border_buffer, true, border_opts)
  vim.api.nvim_set_hl(0, 'YaziBorder', { link = 'Normal', default = true })
  vim.cmd('set winhl=NormalFloat:YaziBorder')

  local yazi_buffer = vim.api.nvim_create_buf(false, true)
  -- create file window, enter the window, and use the options defined in opts
  local win = vim.api.nvim_open_win(yazi_buffer, true, opts)

  vim.bo[yazi_buffer].filetype = 'yazi'

  vim.cmd('setlocal bufhidden=hide')
  vim.cmd('setlocal nocursorcolumn')
  vim.api.nvim_set_hl(0, 'YaziFloat', { link = 'Normal', default = true })
  vim.cmd('setlocal winhl=NormalFloat:YaziFloat')
  vim.cmd('set winblend=' .. config.yazi_floating_window_winblend)

  -- use autocommand to ensure that the border_buffer closes at the same time as the main buffer
  vim.cmd("autocmd WinLeave <buffer> silent! execute 'hide'")
  local cmd = [[autocmd WinLeave <buffer> silent! execute 'silent bdelete! %s']]
  vim.cmd(cmd:format(border_buffer))

  return win, border_window, yazi_buffer
end

return M
