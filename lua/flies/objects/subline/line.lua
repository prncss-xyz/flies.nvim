local f = require 'flies.util.iterator'

local function line_seek_cb(line, _)
  local len = line:len()
  if len == 0 then
    return 1, 1, 1, 1
  end
  local is = require('flies.objects.utils').line_inner_start(line) or len
  local ie = require('flies.objects.utils').line_inner_end(line)
  return 1, is, ie, len
end

local M = require('flies.objects.subline'):new {
  name = 'line',
  seek_cb = line_seek_cb,
  blank_text_object = true,
  meta_move = { start = false },
}

function M:up_iterator(domain, pos)
  local line = require('flies.objects.utils').get_row(pos[1])
  local s, e = M.format_result(domain, pos[1], {
    line_seek_cb(line, pos[1]),
  })
  return f.once(s, e, domain == 'inner' and 'v' or 'V')
end

return M
