local M = require('flies.operations.base').new()

M.name = 'swipe'

function M:op(mode)
  local s, e = require('flies.utils').get_marks_pos(mode)
  dump('hello', s, e)
end

function M:query_n()
  local q = require('flies.repeater').querier(require('flies.utils').query_obj)
  if not q then
    return
  end
  local domain = 'outer'
  local str = string.format(
    ':<c-u>lua require"flies".textobject(%q, %q, %q)<cr>',
    q.query_char,
    domain,
    q.qualifier
  )
  return str
end

return M
