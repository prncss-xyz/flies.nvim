local M = require('flies.operators.base'):new()

local repeater = require 'flies.repeater'
local query_obj = require('flies.utils').query_obj

M.name = 'substitute'

local q

function M:query_n()
  repeater.init()
  q = repeater.querier(query_obj)
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
  local os, oe, w = require('flies.utils').get_marks_pos(mode)
  if q.query and q.query.innerize then
    if mode == 'o' then
      local is, ie = q.query:innerize(os, oe)
      if not is then
        return
      end
      local q_ = repeater.querier(query_obj)
      if not q_ then
        return
      end
      if q_.query and q_.query.substitute then
        q_.query:substitute(os, is, ie, oe, w, q.qualifier == 'previous')
      end
    else
      -- TODO:
    end
  end
end

return M
