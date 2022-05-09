local M = require('flies.operations.base').new()

local repeater = require 'flies.repeater'
local query_obj = require('flies.utils').query_obj

M.name = 'swipe'

local q

function M:query_n()
  repeater.init()
  q = repeater.querier(query_obj)
  q = require('flies.repeater').querier(require('flies.utils').query_obj)
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

function M:op(mode)
  local os, oe = require('flies.utils').get_marks_pos(mode)
  if mode == 'o' then
    local is, ie = q.query:innerize(os, oe)
    if not is then
      return
    end
    require('flies.utils').strip(os, is, ie, oe)
  end
end

return M
