local M = require('flies.operations.base').new()

local repeater = require 'flies.repeater'
local query_obj = require('flies.utils').query_obj

M.name = 'swap'

local pos
local s2, e2, w2
local domain
local query
local qualifier

function M:query_n()
  repeater.init()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  query = q.query
  domain = query.blank_text_object and 'inner' or 'outer'
  qualifier = q.qualifier

  pos = require('flies.utils').get_cursor()
  s2, e2, w2 = query:search(domain, 'plain', pos, 1)
  if not s2 then
    return
  end
  require('flies.utils').set_cursor(s2)
  local str = string.format(
    ':<c-u>lua require"flies".textobject(%q, %q, %q)<cr>',
    q.query_char,
    domain,
    qualifier
  )
  return str
end

local cmp = require('flies.objects.utils').cmp

local function post(s1, e1, s2, e2)
  if not s2 then
    return
  end
  -- TODO: zero length intervals
  if cmp(s1, s2) <= 0 and cmp(e1, e2) >= 0 then
    require('flies.utils').strip(s1, s2, e2, e1)
    return
  end
  if cmp(s1, s2) >= 0 and cmp(e1, e2) <= 0 then
    require('flies.utils').strip(s2, s1, e1, e2)
    return
  end
  require('flies.utils').swap(s1, e1, s2, e2, true)
end

function M:op(mode)
  local s1, e1 = require('flies.utils').get_marks_pos(mode)
  if mode == 'o' then
    post(s2, e2, s1, e1)
  elseif mode == 'x' then
    assert(false)
    local q = require('flies.repeater').querier(
      require('flies.utils').query_obj
    )
    if not q then
      return
    end
    query = q.query
    if not q.query then
      return
    end
    domain = query.blank_text_object and 'inner' or 'outer'
    -- domain = require('flies.utils').get_path(query, 'operator', M.name, 'domain')
    --   or 'inner'
    local pos = require('flies.utils').get_cursor()
    if q.qualifier == 'plain' then
      if vim.v.count == vim.v.count1 then
        qualifier = 'up'
      else
        qualifier = 'plain'
      end
    else
      qualifier = q.qualifier
    end
    count = vim.v.count1
    query:search_cb(domain, qualifier, pos, count, function(s2, e2)
      post(s1, e1, s2, e2)
    end)
  end
end

return M
