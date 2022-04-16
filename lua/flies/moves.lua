local M = {}

local t = require('flies.utils').t
local flies = require 'flies'
local jump = require 'flies.utils'.jump

function M.move(query_map, qualifier, domain, start, mode)
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  local query = flies.queries[t(query_map)]
  if query then
    return query.move(query, domain, qualifier, start, mode)
  end
end

function M.query_obj()
  local qualifier
  local qualifier_char
  while true do
    local char = vim.fn.getchar()
    char = vim.fn.nr2char(char)
    local r = flies.qualifiers[char]
    if r then
      if qualifier then
        return
      end
      qualifier = r
      qualifier_char = char
    elseif char == t '<esc>' then
      return
    else
      return {
        query = flies.queries[char],
        query_char = char,
        qualifier = qualifier or 'plain',
        qualifiers_char = qualifier_char,
      }
    end
  end
end

-- TODO: reusable: accept a callback to set parameters
-- TODO: escape hatch
function M.meta_move(mode)
  local q = require('flies.repeater').querier(M.query_obj)
  if not q then
    return
  end
  local qualifier = q.qualifier
  local char = q.query_char
  local query_o = q.query
  if mode == 'o' and qualifier == 'next' then
    vim.cmd 'normal! v'
  end
  local start = (qualifier == 'previous')
  if query_o then
    local domain = mode == 'n' and 'outer' or 'inner'
    if query_o.name == 'line' then
      domain = 'inner'
    end
    if mode == 'n' and not query_o.normal_dir then
      start = true
    end
    if mode == 'n' then
      require('flies.move_again').register(function()
        M.move(char, 'previous', domain, start, 'n')
      end, function()
        M.move(char, 'next', domain, start, 'n')
      end)
    end
    M.move(char, qualifier, domain, start, mode)
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
  local q = require('flies.repeater').querier(M.query_obj)
  if not q then
    return
  end
  local qualifier = q.qualifier
  local char = q.query_char
  local query_o = q.query
  if query_o then
    M.move(char, qualifier, 'inner', qualifier == 'previous', 'n')
  else
    jump(char, qualifier, true, vim.v.count1)
  end
  -- TODO: linewiseness
  -- TODO: one space padding ??
  -- TODO: escape hatch
  if not query_o then
    if qualifier == 'previous' then
      vim.api.nvim_feedkeys('i', 'n', false)
    else
      vim.api.nvim_feedkeys('a', 'n', false)
    end
  elseif query_o.blank_text_object then
    if qualifier == 'previous' then
      vim.api.nvim_feedkeys('i', 'n', false)
    else
      vim.api.nvim_feedkeys('a', 'n', false)
    end
  else
    if qualifier == 'previous' then
      vim.api.nvim_feedkeys('i', 'n', false)
    else
      vim.api.nvim_feedkeys('a', 'n', false)
    end
  end
end

return M
