local move_cursor = require('flies.objects.utils').move_cursor
local to_pos = require('flies.objects.utils').to_pos
local line_ending_pos = require('flies.objects.utils').line_ending_pos
local select_line_range = require('flies.objects.utils').select_line_range
local count = require('flies.utils').count
local line_bounds = require('flies.objects.utils').line_bounds

local function line_start(line)
  local s, _ = line_bounds('inner', line)
  return to_pos(line, s)
end

local function line_end(line)
  local _, e = line_bounds('inner', line)
  return to_pos(line, e)
end

local function inner_start()
  local max = vim.api.nvim_buf_line_count(0)
  local row = 0
  while true do
    if row > max then
      -- buffer is empty
      return 1
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
      -- buffer is empty
      return 0
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

M.name = 'buffer'

function M:textobject_outer_plain(_)
  local max = vim.api.nvim_buf_line_count(0)
  select_line_range(1, max)
end

function M:textobject_inner_plain(_, _)
  local row_s = inner_start()
  if not row_s then
    return
  end
  local row_e = inner_ending() or vim.api.nvim_buf_line_count(0)
  select_line_range(row_s, row_e)
end

function M:move(domain, qualifier, _, _)
  if qualifier == 'previous' then
    if domain == 'outer' then
      move_cursor({ 1, 0 }, 'V')
    else
      move_cursor(line_start(inner_start()), 'V')
    end
    return
  end
  local lines = vim.api.nvim_buf_line_count(0)
  local c = count()
  if c then
    c = math.min(c, lines)
    move_cursor(line_start(c), 'V')
    return
  end
  local line
  if domain == 'inner' then
    line = inner_ending()
  else
    line = lines
  end
  move_cursor(line_end(line), 'V')
end

return M
