local M = require('flies.operators.base'):new()

local repeater = require 'flies.repeater'
local query_obj = require('flies.utils').query_obj

M.name = 'wrap'

local domain
local qualifier

function M:query_n()
  repeater.init()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  domain = q.query.blank_text_object and 'inner' or 'outer'
  qualifier = q.qualifier

  local str = string.format(
    ':<c-u>lua require"flies".textobject(%q, %q, %q)<cr>',
    q.query_char,
    domain,
    qualifier
  )
  return str
end

function M:op(mode)
  -- TODO: wiseness
  local s, e, w = require('flies.utils').get_marks_pos(mode)
  local q = repeater.querier(query_obj)
  if not q  then
    return
  end
  if q.query and q.query.wrap then
    q.query:wrap(s, e, w)
  end
end

return M
