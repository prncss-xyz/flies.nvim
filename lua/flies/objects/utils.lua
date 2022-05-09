local M = {}

-- adapted from https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua
-- Set visual selection to range
-- @param selection_mode One of "charwise" (default) or "v", "linewise" or "V",
--   "blockwise" or "<C-v>" (as a string with 5 characters or a single character)

function M.infer_wiseness(s, e)
  local line = M.get_row(s[1])
  if M.cmp(e, s) < 0 then
    e, s = s, e
  end
  local is = M.line_inner_start(line)
  if is ~= s[2] then
    return 'charwise'
  end
  line = M.get_row(e[1])
  local ie = M.line_inner_end(line)
  if ie ~= e[2] then
    return 'charwise'
  end
  return 'linewise'
end

function M.update_selection(s, e, selection_mode)
  -- FIXME: cutting a zero length range should leave in insert mode, as in targets
  if e == nil then
    vim.fn.setpos('.', { 0, s[1], s[2], 0 })
    return
  end

  selection_mode = selection_mode or M.infer_wiseness(s, e)

  vim.fn.setpos('.', { 0, s[1], s[2], 0 })

  -- Start visual selection in appropriate mode
  local v_table = { charwise = 'v', linewise = 'V', blockwise = '<C-v>' }
  ---- Call to `nvim_replace_termcodes()` is needed for sending appropriate
  ---- command to enter blockwise mode
  local mode_string = vim.api.nvim_replace_termcodes(
    v_table[selection_mode] or selection_mode,
    true,
    true,
    true
  )
  vim.cmd('normal! ' .. mode_string)

  vim.fn.setpos('.', { 0, e[1], e[2], 0 })
end

function M.cmp(c1, c2)
  if c1[1] < c2[1] then
    return -1
  end
  if c1[1] > c2[1] then
    return 1
  end
  if c1[2] < c2[2] then
    return -1
  end
  if c1[2] > c2[2] then
    return 1
  end
  return 0
end

function M.get_row(row)
  return vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
end

function M.row_forward_iterator(start)
  return function(max, row)
    if row == max then
      return
    end
    row = row + 1
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    return row, line
  end,
    vim.api.nvim_buf_line_count(0),
    start and start - 1 or 0
end

function M.row_backward_iterator(start)
  return function(_, row)
    row = row - 1
    if row == 0 then
      return
    end
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    return row, line
  end,
    nil,
    start and start + 1 or vim.api.nvim_buf_line_count(0) + 1
end

function M.to_pos(row, col)
  col = col and col - 1
  return { row, col }
end

function M.from_pos(pos)
  local row = pos[1]
  local col = pos[2] and pos[2] + 1
  return row, col
end

function M.pre_jump()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_mark(0, "'", pos[1], pos[2], {})
end

function M.set_selection(start, ending, wiseness)
  vim.fn.setpos('.', { 0, start[1], start[2] + 1, 0 })
  vim.cmd('normal! ' .. wiseness)
  vim.fn.setpos('.', { 0, ending[1], ending[2] + 1, 0 })
end

function M.move_cursor(pos, wiseness)
  vim.api.nvim_win_set_cursor(0, pos)
end

function M.line_inner_start(line)
  -- parenthesis to get only first value
  return (string.find(line, '%S'))
end

function M.line_inner_end(line)
  -- parenthesis to get only first value
  return (string.find(line, '.%s*$'))
end

function M.line_bounds(domain, line)
  local oe = line:len()
  if oe == 0 then
    oe = 1
  end
  if domain == 'outer' then
    return 1, oe
  end
  local is = string.find(line, '.%S')
  local ie = string.find(line, '.%s*$')
  if domain == 'inner' then
    return is, ie
  end
end

function M.line_ending(domain, line)
  if domain == 'outer' then
    return col
  end
end

function M.line_ending_col(row)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  if line == '' then
    return 1
  else
    return line:len()
  end
end

function M.line_ending_pos(row)
  local col = M.line_ending_col(row)
  return M.to_pos(row, col)
end

function M.select_line_range(start, ending)
  local len = M.line_ending_col(ending)
  M.set_selection(M.to_pos(start, 1), M.to_pos(ending, len), 'V')
end

function M.inc_pos(pos, fwd)
  local row = pos[1]
  local col = pos[2] + 1
  if fwd then
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
    local len = string.len(line)
    if col < len then
      return { row, col }
    end
    local max = vim.api.nvim_buf_line_count(0)
    if row < max then
      return { row + 1, col - 1 }
    end
    return pos
  else
    if col > 1 then
      return { row, col - 2 }
    end
    if row > 1 then
      local line = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1]
      local len = string.len(line)
      if len == 0 then
        len = 1
      end
      return { row - 1, 1 }
    end
    return { 1, 0 }
  end
end

return M
