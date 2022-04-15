local M = {}

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

function M.line_bounds(domain, row)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  if line == '' then
    return 1, 1
  end
  if domain == 'inner' then
    local col_s = string.find(line, '[%S]')
    local col_e = string.find(line, '.[%s]*$')
    return col_s, col_e
  end
  if domain == 'outer' then
    return 1, line:len()
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
