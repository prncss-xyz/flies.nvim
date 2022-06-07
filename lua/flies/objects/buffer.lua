local M = require('flies.objects.base'):new {
  name = 'buffer',
  blank_text_object = true,
}

local utils = require 'flies.objects.utils'

local function starting(domain)
  if domain == 'outer' then
    return { 1, 1 }
  end
  for row, line in utils.row_forward_iterator(1) do
    local start = utils.line_inner_start(line)
    if start then
      return { row, start }
    end
  end
  return { 1, 1 }
end

local function ending(domain)
  local last_row = vim.api.nvim_buf_line_count(0)
  if domain == 'outer' then
    local line = utils.get_row(last_row)
    local col = line:len()
    if col == 0 then
      col = 1
    end
    return { last_row, col }
  end
  for row, line in utils.row_backward_iterator(last_row) do
    local end_ = utils.line_inner_end(line)
    if end_ then
      return { row, end_ }
    end
  end
end

function M:up_iterator(domain, _)
  return require('flies.utils').from_list {
    { starting(domain), ending(domain) },
  }
end

function M:np_iterator(domain, _, forward, start)
  if forward and start then
    return require('flies.utils').from_list {
      { ending(domain), starting(domain) },
    }
  else
    return require('flies.utils').from_list {
      { starting(domain), ending(domain) },
    }
  end
end

return M
