local name = require('flies.utils').name
local set_selection = require('flies.utils').set_selection
local move_cursor = require('flies.utils').move_cursor
local to_pos = require('flies.utils').to_pos
local line_bounds = require('flies.utils').line_bounds

local function select_line(row, start, ending, wiseness)
  if row then
    set_selection(to_pos(row, start), to_pos(row, ending), wiseness)
  end
end

local function get_row(qualifier)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if qualifier == 'plain' then
    if vim.v.count > 0 then
      row = vim.v.count
    else
      return row
    end
  end
  if qualifier == 'previous' then
    row = row - vim.v.count1
    if row < 1 then
      return nil
    end
    return row
  end
  if qualifier == 'next' then
    row = row + vim.v.count1
  end
  local max = vim.api.nvim_buf_line_count(0)
  if row > max then
    return nil
  end
  return row
end

local M = require('flies.objects.base').new()

function M.new()
  return setmetatable({}, { __index = M })
end

function M:name()
  return 'line'
end

M.blank_text_object = true
M.normal_dir = true

M[name('move', 'outer', 'hint')] = function(_, start, mode)
  require('hop').hint_lines()
end

M[name('move', 'inner', 'hint')] = function(_, start, mode)
  require('hop').hint_lines_skip_whitespace()
end

for _, domain in ipairs { 'inner', 'outer' } do
  for _, qualifier in ipairs { 'plain', 'next', 'previous' } do
    local wiseness = domain == 'inner' and 'v' or 'V'
    M[name('textobject', domain, qualifier)] = function(_, _)
      local row = get_row(qualifier)
      if not row then
        return
      end
      local col_s, col_e = line_bounds(domain, row)
      select_line(row, col_s, col_e, wiseness)
    end
    M[name('move', domain, qualifier)] = function(_, start, mode)
      print(domain, mode)
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local col_s, col_e = line_bounds(domain, row)
      local bound = start and col_s or col_e
      if qualifier == 'previous' then
        if col + 1 <= bound then
          if row == 1 then
            return
          end
          row = row - 1
          col_s, col_e = line_bounds(domain, row)
        end
      else
        if col + 1 >= bound then
          local max = vim.api.nvim_buf_line_count(0)
          if row == max then
            return
          end
          row = row + 1
          col_s, col_e = line_bounds(domain, row)
        end
      end
      bound = start and col_s or col_e
      move_cursor(to_pos(row, bound), wiseness)
    end
  end
end

return M
