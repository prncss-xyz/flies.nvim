local M = require('flies.objects.base'):new()

local ts_utils = require 'nvim-treesitter.ts_utils'
local ts_query = require 'nvim-treesitter.query'
local cmp = require('flies.objects.utils').cmp
local get_row = require('flies.utils').get_row

local infer_wiseness = require('flies.objects.utils').infer_wiseness

function M:new(t)
  if type(t) == 'string' then
    t = { t }
  end
  local q = t[1]
  if q:sub(1, 1) == '@' then
    t.name = t[1]
    t.query1 = t[1]
  else
    t.name = string.format('@%s inner/outer', q)
    t.query1 = string.format('@%s.outer', q)
    t.query2 = string.format('@%s.inner', q)
  end
  local mt = getmetatable(self).__index
  return mt.new(self, t)
end

local function get_lua_range(range)
  local vim_range
  if range.start then
    local start_range = { range.start.node:range() }
    local node_range = { range.node:range() }
    vim_range = {
      ts_utils.get_vim_range({
        start_range[1],
        start_range[2],
        node_range[3],
        node_range[4],
      }, 0),
    }
  elseif range.node then
    vim_range = {
      ts_utils.get_vim_range({ range.node:range() }, 0),
    }
  end
  local row = get_row(vim_range[1] - 1)
  if true then
    if vim_range[2] > row:len() then
      vim_range[1] = vim_range[1] + 1
      vim_range[2] = 1
    end
    row = get_row(vim_range[3] - 1)
    if vim_range[4] > row:len() then
      vim_range[3] = vim_range[3] + 1
      vim_range[4] = 1
    end
  end
  return { vim_range[1], vim_range[2] }, { vim_range[3], vim_range[4] }
end

function M:is_node_inside_range(strict, os, oe, inner_node)
  local i_start_line, i_start_col, i_end_line, i_end_col = inner_node:range()
  local cstart = cmp({ i_start_line, i_start_col }, { os[1] - 1, os[2] - 1 })
  local cend = cmp({ i_end_line, i_end_col }, { oe[1] - 1, oe[2] })
  if strict and cstart == 0 and cend == 0 then
    return false
  end
  if cstart < 0 then
    return false
  end
  if cend > 0 then
    return false
  end
  return true
end

local function is_node_inside_node(strict, inner_node, outer_node)
  local i_start_line, i_start_col, i_end_line, i_end_col = inner_node:range()
  local o_start_line, o_start_col, o_end_line, o_end_col = outer_node:range()
  local cstart = cmp(
    { i_start_line, i_start_col },
    { o_start_line, o_start_col }
  )
  local cend = cmp({ i_end_line, i_end_col }, { o_end_line, o_end_col })
  if strict and cstart == 0 and cend == 0 then
    return false
  end
  if cstart < 0 then
    return false
  end
  if cend > 0 then
    return false
  end
  return true
end

local function search(query, filter_cb, sort_cb)
  local bufnr = vim.api.nvim_get_current_buf()
  local matches = ts_query.get_capture_matches_recursively(
    bufnr,
    query,
    'textobjects'
  )
  if filter_cb then
    matches = vim.tbl_filter(filter_cb, matches)
  end
  if sort_cb then
    table.sort(matches, sort_cb)
  end
  return matches
end

local function latest(m1, m2)
  local end1 = m1.end_
  if not end1 then
    return false
  end
  local end2 = m2.end_
  if not end2 then
    return true
  end
  local _, _, end_byte1 = end1.node:start()
  local _, _, end_byte2 = end2.node:start()
  return end_byte1 > end_byte2
end

local function widest_latest(m1, m2)
  local node_length = ts_utils.node_length
  local length1 = node_length(m1.node)
  local length2 = node_length(m2.node)
  if length1 > length2 then
    return true
  end
  if length1 < length2 then
    return false
  end
  -- for nodes with same length take the one with the latest end
  return latest(m1, m2)
end

local function shortest_earliest(m1, m2)
  return widest_latest(m2, m1)
end

function M:create_cache()
  local cache = search(self.query2, nil, widest_latest)
  dump(1, cache)
  return cache
end

function M:innerize(os, oe, cache)
  if not self.query2 then
    return os, oe
  end

  local function filter_cb(m)
    return m.node and self:is_node_inside_range(true, os, oe, m.node)
  end

  local matches = search(self.query2, filter_cb, widest_latest)
  local match = matches[1]
  if not match then
    return
  end
  return get_lua_range(match)
end

function M:np_iterator(domain, pos, forward, start, extremum)
  local query = domain == 'inner' and self.query2 or self.query1
  local bufnr = vim.api.nvim_get_current_buf()
  local matches = ts_query.get_capture_matches_recursively(
    bufnr,
    query,
    'textobjects'
  )
  local res = {}
  for _, match in ipairs(matches) do
    local s, e = get_lua_range(match)
    local p = start and s or e
    if forward then
      if cmp(pos, p) < 0 and (not extremum or p[1] <= extremum) then
        table.insert(res, { s, e })
      end
    else
      if cmp(pos, p) > 0 and (not extremum or p[1] >= extremum) then
        table.insert(res, { s, e })
      end
    end
  end
  local index = start and 1 or 2
  local function sort_cb(a, b)
    if forward then
      return cmp(a[index], b[index]) < 0
    else
      return cmp(a[index], b[index]) > 0
    end
  end
  table.sort(res, sort_cb)
  vim.tbl_map(function(args)
    s, e = unpack(args)
    return s, e, infer_wiseness(s, e)
  end, res)
  return require('flies.utils').from_list(res)
end

-- TODO: skip query1 when blank_text_object
function M:up_cb(domain, pos, count)
  local row, col = pos[1] - 1, pos[2] - 1
  local function filter_cb(m)
    return m.node and ts_utils.is_in_node_range(m.node, row, col)
  end

  -- disabling innerize heuristic on blank_text_object
  local query = self.blank_text_object and domain == 'inner' and self.query2
    or self.query1
  local matches = search(query, filter_cb, shortest_earliest)
  if count == 'last' then
    count = #matches
  end
  local match = matches[count]
  if not match then
    return
  end

  local os, oe = get_lua_range(match)
  if domain == 'outer' or self.blank_text_object then
    return os, oe, infer_wiseness(os, oe)
  end
  if not self.query2 then
    return
  end
  local is, ie = self:innerize(os, oe)
  if not is then
    return
  end
  if domain == 'inner' then
    return is, ie, infer_wiseness(is, ie)
  end
  assert(false, string.format('unknown domain %q', domain))
end

return M
