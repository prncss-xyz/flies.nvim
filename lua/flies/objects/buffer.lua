local move_cursor = require('flies.utils').move_cursor
local to_pos = require('flies.utils').to_pos
local line_ending_pos = require('flies.utils').line_ending_pos
local select_line_range = require('flies.utils').select_line_range

local function inner_start()
  local max = vim.api.nvim_buf_line_count(0)
  local row = 1
  while true do
    if row > max then
      return nil
    end
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    if not string.find(line, '^[%s]*$') then
      return row
    end
    row = row + 1
  end
end

local function inner_ending()
  local row = vim.api.nvim_buf_line_count(0)
  while true do
    if row == 0 then
      return nil
    end
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    if not string.find(line, '^[%s]*$') then
      return row
    end
    row = row - 1
  end
end

local M = require('flies.objects.base').new()

function M.new()
  return setmetatable({}, { __index = M })
end

function M:textobject_outer_plain(_)
  local max = vim.api.nvim_buf_line_count(0)
  select_line_range(1, max)
end

function M:move_outer_plain(start)
  if start then
    move_cursor(to_pos(1, 1), 'V')
  else
    move_cursor(line_ending_pos(vim.api.nvim_buf_line_count(0)), 'V')
  end
end

function M:move_inner_plain(start)
  if start then
    move_cursor(to_pos(inner_start(), 1), 'V')
  else
    move_cursor(line_ending_pos(inner_ending()), 'V')
  end
end

function M:textobject_inner_plain(_)
  local row_s = inner_start()
  if not row_s then
    return
  end
  local row_e = inner_ending() or vim.api.nvim_buf_line_count(0)
  select_line_range(row_s, row_e)
end

return M
