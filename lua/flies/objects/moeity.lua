local M = require('flies.objects.base'):new()

local util = require 'flies.objects.utils'
local repeater = require 'flies.repeater'
local query_obj = require('flies.utils').query_obj
local iter = require 'flies.util.iterator'

M.name = 'moeity'

local function get_right(cursor, s, e, wiseness)
  local rs, re
  wiseness = wiseness or util.infer_wiseness(s, e)
  if wiseness == 'V' then
    local line = util.get_row(cursor[1])
    rs = { cursor[1], util.line_inner_start(line) }
  else
    rs = cursor
  end
  if util.cmp(cursor, s) < 0 then
    if wiseness == 'V' then
      -- TODO: take care or 1-line wide intervals
      re = { s[1] - 1, s[2] }
    else
      -- TODO: take care of first char case
      re = { s[1], s[2] - 1 }
    end
  else
    re = e
  end
  return rs, re, wiseness
end

local function get_left(cursor, s, e, wiseness)
  local rs, re
  wiseness = wiseness or util.infer_wiseness(s, e)
  if wiseness == 'V' then
    local row = cursor[1] - 1
    local line = util.get_row(row)
    rs = { row, util.line_inner_end(line) }
  else
    -- TODO: prevchar
    rs = { cursor[1], cursor[2] - 1 }
  end
  if util.cmp(s, rs) >= 0 then
    return
  end
  if util.cmp(cursor, e) > 0 then
    if wiseness == 'V' then
      -- TODO: take care of 1-line wide intervals
      re = { e[1] + 1, e[2] }
    else
      -- TODO: take care of first char case
      re = { e[1], e[2] + 1 }
    end
  else
    re = s
  end
  return rs, re, wiseness
end

local function up_iter(query, domain, cursor)
  if query.up_cb then
    return iter.map(function(count)
      return query:up_cb(domain, cursor, count)
    end)(iter.range())
  elseif query.up_iterator then
    return query:up_iterator(domain, cursor)
  else
    return function() end
  end
end

-- with this limited and slightly out of specs implementation,
-- moeity forward from right surrouding actualy moves backward;
-- this will be overcome with a complete implementation

function M:np_iterator(_, init, forward, _, extremum)
  local cursor = require('flies.utils').get_cursor()
  local q = repeater.querier(query_obj)
  local domain = 'inner'
  if not q then
    return
  end

  if q.qualifier == 'previous' then
    forward = not forward
  end
  local query = q.query
  return iter.compose(
    iter.filter(function(s, e, w)
      if forward then
        return util.cmp(cursor, e) < 0
      else
        return util.cmp(cursor, s) > 0
      end
    end),
    iter.map(function(s, e, w)
      if forward then
        return get_right(cursor, s, e, w)
      else
        return get_left(cursor, s, e, w)
      end
    end)
  )(up_iter(query, domain, cursor))
end

M.actions = {
  move = {
    start = false,
  },
}

M.reversed = M:new()
M.reversed.name = 'reversed moeity'

function M.reversed:np_iterator(domain, init, forward, start, extremum)
  return self:super('np_iterator', domain, init, not forward, start, extremum)
end

return M
