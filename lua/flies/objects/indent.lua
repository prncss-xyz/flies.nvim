local move_cursor = require('flies.objects.utils').move_cursor
local to_pos = require('flies.objects.utils').to_pos
local line_ending_pos = require('flies.objects.utils').line_ending_pos
local select_line_range = require('flies.objects.utils').select_line_range
local line_bounds = require('flies.objects.utils').line_bounds

-- TODO: previous, next

local function is_blank(row)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  return string.find(line, '^[%s]*$')
end

local function lookahead(row)
  local max = vim.api.nvim_buf_line_count(0)
  while true do
    if not is_blank(row) then
      return row
    end
    if row == max then
      return nil
    end
    row = row + 1
  end
end

local function lookbehind(row)
  while true do
    if not is_blank(row) then
      return row
    end
    if row == 1 then
      return nil
    end
    row = row - 1
  end
end

local function start(domain, row)
  local indent_base = vim.fn.indent(row)
  local last_row, last_indent = row, indent_base
  local indent = indent_base
  local count = vim.v.count1
  while true do
    if row == 1 then
      return row, indent
    end
    last_row, last_indent = row, indent
    row = row - 1
    indent = vim.fn.indent(row)
    local blank = is_blank(row)
    if (domain == 'inner' or not blank) and indent < indent_base then
      if count == 1 then
        return last_row, last_indent
      end
      count = count - 1
      indent_base = indent
    end
    if domain == 'inner' and blank then
      return last_row, last_indent
    end
  end
end

local function ending(domain, row, indent_base)
  local last_row = row
  local indent = indent_base
  local max = vim.api.nvim_buf_line_count(0)
  while true do
    if row == max then
      return row
    end
    last_row = row
    row = row + 1
    indent = vim.fn.indent(row)
    local blank = is_blank(row)
    if (domain == 'inner' or not blank) and indent < indent_base then
      return last_row
    end
    if domain == 'inner' and blank then
      return last_row
    end
  end
end

local function previous_end(domain, row)
  local count = vim.v.count1
  local indent = vim.fn.indent(row)
  local last_indent
  local last_blank = false
  while true do
    if row == 1 then
      return nil
    end
    row = row - 1
    local blank = is_blank(row)
    if blank then
      if domain == 'inner' then
        last_blank = true
      end
    elseif last_blank then
      indent = vim.fn.indent(row)
      if count == 1 then
        return row, indent
      end
      count = count - 1
    else
      last_indent = indent
      indent = vim.fn.indent(row)
      if indent < last_indent then
        if count == 1 then
          return row, indent
        end
        count = count - 1
      end
    end
  end
end

local function next_start(domain, row)
  local count = vim.v.count1
  local max = vim.api.nvim_buf_line_count(0)
  local indent = vim.fn.indent(row)
  local last_indent
  local last_blank = false
  while true do
    if row == max then
      return nil
    end
    row = row + 1
    local blank = is_blank(row)
    if blank then
      if domain == 'inner' then
        last_blank = true
      end
    elseif last_blank then
      indent = vim.fn.indent(row)
      if count == 1 then
        return row, indent
      end
      count = count - 1
    else
      last_indent = indent
      indent = vim.fn.indent(row)
      if indent > last_indent then
        if count == 1 then
          return row, indent
        end
        count = count - 1
      end
    end
  end
end

local function textobject_plain(domain)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  row = lookahead(row)
  if not row then
    return
  end
  local row_s, indent = start(domain, row)
  local row_e = ending(domain, row, indent)
  select_line_range(row_s, row_e)
end

local M = require('flies.objects.base').new()

function M.new()
  return setmetatable({}, { __index = M })
end

M.name = 'indent'

function M:textobject_inner_plain(_)
  textobject_plain 'inner'
end

function M:textobject_outer_plain(_)
  textobject_plain 'outer'
end

-- TODO: count
-- TODO: find meaningful behavior
function M.move(domain, qualifier, start0)
  if qualifier == 'previous' then
    local row = vim.api.nvim_win_get_cursor(0)[1]
    if row == 1 then
      return
    end
    row = row - 1
    row = lookbehind(row)
    if not row then
      return
    end
    if start0 then
      row = start(domain, row)
    else
      row = previous_end(domain, row)
      if not row then
        return
      end
    end

    local col_s, col_e = line_bounds('inner', row)
    move_cursor(to_pos(row, start0 and col_s or col_e), 'V')
  else
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local max = vim.api.nvim_buf_line_count(0)
    if row == max then
      return
    end
    if start then
      row = lookahead(row)
      if not row then
        return
      end
      row = next_start(domain, row)
      if not row then
        return
      end
    else
      row = row + 1
      row = lookahead(row)
      if not row then
        return
      end
      local indent = vim.fn.indent(row)
      row = ending(domain, row, indent)
    end

    local col_s, col_e = line_bounds('inner', row)
    move_cursor(to_pos(row, start and col_s or col_e), 'V')
  end
end

return M
