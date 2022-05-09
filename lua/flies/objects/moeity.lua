local M = setmetatable({}, { __index = require 'flies.objects.base' })
local util = require 'flies.objects.utils'
local repeater = require 'flies.repeater'
local query_obj = require('flies.utils').query_obj

function M.new(o)
  o = o or {}
  setmetatable(o, { __index = M })
  return o
end

local function get_right(init, s, e)
  local rs, re
  local wiseness = util.infer_wiseness(s, e)
  if wiseness == 'linewise' then
    local line = util.get_row(init[1])
    rs = { init[1], util.line_inner_start(line) }
  else
    rs = init
  end
  if util.cmp(init, s) < 0 then
    if wiseness == 'linewise' then
      -- TODO: take care or 1-line wide intervals
      re = { s[1] - 1, s[2] }
    else
      -- TODO: take care of first char case
      re = { s[1], s[2] - 1 }
    end
  else
    re = e
  end
  return rs, re
end

local function get_left(init, s, e)
  local rs, re
  local wiseness = util.infer_wiseness(s, e)
  if wiseness == 'linewise' then
    local row = init[1] - 1
    local line = util.get_row(row)
    rs = { row, util.line_inner_end(line) }
  else
    rs = { init[1], init[2] - 1 }
  end
  if util.cmp(s, rs) >= 0 then
    return
  end
  if util.cmp(init, e) > 0 then
    if wiseness == 'linewise' then
      -- TODO: take care or 1-line wide intervals
      re = { e[1] + 1, e[2] }
    else
      -- TODO: take care of first char case
      re = { e[1], e[2] + 1 }
    end
  else
    re = s
  end
  return rs, re
end

function M:search_smart(domain, init)
  return self:search_forward(domain, init, 1)
end

function M:search_upward(domain, init, count)
  return self:search_forward(domain, init, count)
end

function M:search_forward(domain, init, count)
  domain = 'inner'
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local query = q.query
  if q.qualifier == 'plain' then
    local s, e = query:search_upward(domain, init, count)
    if s then
      return get_right(init, s, e)
    end
  else
    local s, e = query:search_upward(domain, init, count)
    if s then
      return get_left(init, s, e)
    end
  end
end

function M:search_backward(domain, init, count)
  domain = 'inner'
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local query = q.query
  local s, e
  if q.qualifier == 'plain' then
    s, e = query:search_upward(domain, init, count)
    if s then
      return get_left(init, s, e)
    end
  else
    s, e = query:search_upward(domain, init, count)
    if s then
      return get_right(init, s, e)
    end
  end
  if not s then
    return
  end
  return get_left(init, s, e)
end

return M
