local M = require('flies.objects.base'):new()

-- quick and dirty port of https://github.com/David-Kunz/treesitter-unit/

local ts_utils = require 'nvim-treesitter.ts_utils'

local get_text = function(bufnr, line)
  return vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
end

local get_node_for_cursor = function(cursor)
  local root = ts_utils.get_root_for_position(
    unpack { cursor[1] - 1, cursor[2] }
  )
  if not root then
    return
  end
  return root:named_descendant_for_range(
    cursor[1] - 1,
    cursor[2],
    cursor[1] - 1,
    cursor[2]
  )
end

local get_main_node = function(cursor)
  local node = get_node_for_cursor(cursor)
  if node == nil then
    return node
  end
  local parent = node:parent()
  local root = ts_utils.get_root_for_node(node)
  local start_row = node:start()
  while parent ~= nil and parent ~= root and parent:start() == start_row do
    node = parent
    parent = node:parent()
  end
  return node
end

local move_row_while_empty = function(bufnr, curr_line, delta)
  local line = curr_line
  if get_text(bufnr, line) == '' then
    local parent = line + delta
    local line_parent = get_text(bufnr, parent)
    while parent >= 0 and line_parent == '' do
      line = parent
      parent = line + delta
      line_parent = get_text(bufnr, parent)
    end
  end
  return line
end

local move_col_while_empty = function(bufnr, curr_line)
  local line = curr_line
  local text = get_text(bufnr, line)
  local found = string.find(text, '[^%s]')
  return found and found - 1 or 0
end

function M:up_cb(domain, cursor, count)
  if count > 1 then
    return
  end
  local outer = domain == 'outer'
  local bufnr = vim.api.nvim_get_current_buf()

  local sel_row = cursor[1]
  local sel_col = cursor[2]
  if outer and get_text(bufnr, sel_row) == '' then
    sel_row = move_row_while_empty(bufnr, sel_row, 1) + 1
    sel_col = 0
  end
  if outer then
    sel_col = move_col_while_empty(bufnr, sel_row)
  end

  local node = get_main_node { sel_row, sel_col }
  if node == nil then
    return
  end
  local start_row, start_col, end_row, end_col = node:range()

  local mode = 'charwise'
  if outer then
    if cursor[1] < sel_row then
      start_row = move_row_while_empty(bufnr, start_row, -1)
    else
      local text = get_text(bufnr, end_row + 2)
      if text == '' then
        end_row = move_row_while_empty(bufnr, end_row + 1, 1)
        start_col = 0
        mode = 'V'
      end
    end
  end
  return { start_row + 1, start_col + 1 }, { end_row + 1, end_col }, mode
end

return M
