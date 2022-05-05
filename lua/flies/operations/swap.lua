local M = require('flies.operations.base').new()

M.name = 'swap'

local domain
local query
local count
local qualifier
function M:query_n()
  local q = require('flies.repeater').querier(require('flies.utils').query_obj)
  if not q then
    return
  end
  query = q.query
  domain = query.blank_text_object and 'inner' or 'outer'

  if q.qualifier == 'plain' then
    qualifier = 'next'
  else
    qualifier = q.qualifier
  end
  count = vim.v.count1
  vim.v.count = 0
  vim.v.count1 = 1

  local pos = require('flies.utils').get_cursor()
  pos = query:search(domain, 'smart', pos, 1)
  if not pos then
    return
  end
  -- local s, e = query:search(domain, qualifier, pos, vim.v.count1)
  require('flies.utils').set_cursor(pos)
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
    local s2, e2 = query:search(domain, 'smart', require('flies').cache.pos, 1)
    post(s2, e2, s1, e1)
  elseif mode == 'x' then
    local q = require('flies.repeater').querier(
      require('flies.utils').query_obj
    )
    if not q then
      return
    end
    query = q.query
    domain = query.blank_text_object and 'inner' or 'outer'
    -- domain = require('flies.utils').get_path(query, 'operator', M.name, 'domain')
    --   or 'inner'
    local pos = require('flies.utils').get_cursor()
    if q.qualifier == 'plain' then
      if vim.v.count == vim.v.count1 then
        qualifier = 'up'
      else
        qualifier = 'smart'
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
