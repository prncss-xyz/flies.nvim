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

local k = 0
function M:np_iterator0(_, init, forward, _, extremum)
  k = k + 1
  local domain = 'inner'
  local pos = require('flies.utils').get_cursor()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local query = q.query
  local f, state, i = query:up_iterator(domain, init, true, false, extremum)
  local s, e
  local j = 0
  return function()
    j = j + 1
    i, s, e = f(state, i)
    if forward then
      return j, get_right(pos, s, e)
    else
      return j, get_left(pos, s, e)
    end
  end
end

function M:np_iterator1(_, init, forward, _, extremum)
  local domain = 'inner'
  local pos = require('flies.utils').get_cursor()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local query = q.query
  local f, state, i = query:up_iterator(domain, init, true, false, extremum)
  local s, e
  local j = 0
  local res = {}
  local t = 0
  local function ncmp(a, b)
    if forward then
      return util.cmp(a, b)
    else
      return util.cmp(b, a)
    end
  end
  while true do
    i, s, e = f(state, i)
    if i then
      table.insert(res, { s, e })
      if forward then
        if util.cmp(s, init) > 0 then
          return
        end
      else
        if util.cmp(init, e) < 0 then
          return
        end
      end
    else
      break
    end
  end
  local get_dir, get_rev
  if forward then
    get_dir, get_rev = get_right, get_left
  else
    get_dir, get_rev = get_left, get_right
  end
  local n = #res
  return function()
    j = j + 1
    local ndx = n - j + 1
    if ndx > 0 then
      local r = res[ndx]
      return j, get_rev(pos, r[1], r[2])
    end
    ndx = j - n
    if ndx <= n then
      local r = res[ndx]
      return j, get_dir(pos, r[1], r[2])
    end
    if i then
      i, s, e = f(state, i)
      return j, get_dir(pos, s, e)
    end
  end
end

function M:np_iterator2(_, init, forward, _, extremum)
  local domain = 'inner'
  local pos = require('flies.utils').get_cursor()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local query = q.query
  local f, state, i = query:up_iterator(domain, init, true, false, extremum)
  local s, e
  local res = {}
  repeat
    i, s, e = f(state, i)
    table.insert(res, { s, e })
  until not s or i == 2
  local j = 0
  local n = #res
  return function()
    j = j + 1
    local ndx = j
    if ndx <= n then
      local r = res[ndx]
      if forward then
        return j, get_right(pos, r[1], r[2])
      else
        return j, get_left(pos, r[1], r[2])
      end
    end
    i, s, e = f(state, i)
    if forward then
      return j, get_right(pos, s, e)
    else
      return j, get_left(pos, s, e)
    end
  end
end

M.np_iterator = M.np_iterator1

return M
