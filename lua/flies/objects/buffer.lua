local M = require('flies.objects.base').new()

function M.new()
  return setmetatable({}, { __index = M })
end

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

local line = require('flies.objects.subline').line()

function M:search_upward(domain, _, _)
  return starting(domain), ending(domain)
end

function M:search_forward(domain, pos, count)
  if vim.v.count == 1 or count > 1 then
    return line:search_count(domain, pos, count)
  end

  return ending(domain), ending(domain)
end

function M:search_backward(domain, _, _)
  return starting(domain), starting(domain)
end

M.name = 'buffer'
M.blank_text_object = true

return M
