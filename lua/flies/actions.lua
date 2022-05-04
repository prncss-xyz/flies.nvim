local M = {}

local t = require('flies.utils').t
-- TODO: bad dependancy scheme, find better way to share config
local flies = require 'flies'
local jump = require('flies.utils').jump

function M.move(query_map, qualifier, domain, start)
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  local query = flies.queries[t(query_map)]
  if query then
    return query.motion(query, domain, qualifier, start)
  end
end

-- TODO: reusable: accept a callback to set parameters
-- TODO: escape hatch
-- TODO: o mode: if inside an object, actual behavior, if outside, reverse start, end
function M.meta_move(mode)
  local q = require('flies.repeater').querier(require'flies.utils'.query_obj)
  if not q then
    return
  end
  local qualifier = q.qualifier
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  local char = q.query_char
  local query_o = q.query
  if mode == 'o' and qualifier == 'next' then
    vim.cmd 'normal! v'
  end
  if query_o then
    local domain
    if query_o.name == 'line' then
      domain = 'inner'
    elseif query_o.blank_text_object and mode == 'n' then
      domain = 'inner'
    elseif query_o.blank_text_object and mode ~= 'n' then
      domain = 'outer'
    elseif mode == 'n' then
      domain = 'outer'
    else
      domain = 'inner'
    end
    local start
    if mode == 'n' or query_o.name == 'line' then
      start = true
    else
      start = (qualifier == 'previous')
    end
    if mode == 'n' then
      require('flies.move_again').register(function()
        M.move(char, 'previous', domain, start)
      end, function()
        M.move(char, 'next', domain, start)
      end)
    end
    M.move(char, qualifier, domain, start)
  else
    if mode == 'n' then
      require('flies.move_again').register(function()
        jump(char, 'previous', false, vim.v.count1)
      end, function()
        jump(char, 'next', false, vim.v.count1)
      end)
    end
    jump(char, qualifier, mode ~= 'n', vim.v.count1)
  end
end

function M.append_insert()
  local q = require('flies.repeater').querier(require'flies.utils'.query_obj)
  if not q then
    return
  end
  local qualifier = q.qualifier
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  local char = q.query_char
  local query_o = q.query
  if query_o then
    M.move(char, qualifier, 'inner', qualifier == 'previous')
  else
    jump(char, qualifier, true, vim.v.count1)
  end
  -- TODO: linewiseness
  -- TODO: one space padding ??
  -- TODO: escape hatch
  if not query_o then
    vim.api.nvim_feedkeys('i', 'n', false)
  else
    if qualifier == 'previous' then
      vim.api.nvim_feedkeys('i', 'n', false)
    else
      vim.api.nvim_feedkeys('a', 'n', false)
    end
  end
end

function M.op(op, domain_param, noremap)
  local q = require('flies.repeater').querier(require'flies.utils'.query_obj)
  if not q then
    return
  end
  local domain
  if type(domain_param) == 'string' then
    domain = domain_param
  elseif type(domain_param) == 'function' then
    domain = domain_param(q)
  else
    domain = 'outer'
  end
  vim.api.nvim_feedkeys(t(op), noremap and 'n' or 'm', true)
  local str = string.format(
    ':<c-u>lua require"flies".textobject(%q, %q, %q)<cr>',
    q.query_char,
    domain,
    q.qualifier
  )
  vim.api.nvim_feedkeys(t(str), 'n', true)
end

-- TODO: only if successful
function M.op_insert(op, domain_param, noremap)
  M.op(op, domain_param, noremap)
  vim.schedule(function()
    vim.cmd 'startinsert'
  end)
end

return M
