local M = require('flies.objects.subline').new {}

local function line_seek_cb(line, _)
  local len = line:len()
  if len == 0 then
    return 1, 1, 1, 1
  end
  local is = require('flies.objects.utils').line_inner_start(line) or len
  local ie = require('flies.objects.utils').line_inner_end(line)
  return 1, is, ie, len
end

function M:up_cb(domain, _, count)
  local line = require'flies.objects.utils'.get_row(count)
  return M.format_result(domain, count, { line_seek_cb(line, count) })
end

M.name = 'line'
M.seek_cb = line_seek_cb
M.blank_text_object = true
M.meta_move = { start = false }

return M
