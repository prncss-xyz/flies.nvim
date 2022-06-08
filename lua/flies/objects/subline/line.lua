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

-- TODO: iterator
function M:up_cb(domain, pos, count)
  local line_no
  if count == 'last' then
    line_no = pos[1]
  else
    line_no = pos[1] + count - 1
  end
  local line = require('flies.objects.utils').get_row(line_no)
  local s, e = M.format_result(domain, pos[1], {
    line_seek_cb(line, line_no),
  })
  return s, e, domain == 'inner' and 'charwise' or 'linewise'
end

return M
