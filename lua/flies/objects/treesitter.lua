local M = setmetatable({}, { __index = require 'flies.objects.base' })

local ts_utils = require 'nvim-treesitter.ts_utils'
local ts_query = require 'nvim-treesitter.query'
local cmp = require('flies.objects.utils').cmp

function M.new(t)
  if type(t) == 'string' then
    t = { t }
  end
  t = setmetatable(t, { __index = M })
  local q = t[1]
  if q:sub(1, 1) == '@' then
    t.name = t[1]
    t.query1 = t[1]
  else
    t.name = string.format('@%s inner/outer', q)
    t.query1 = string.format('@%s.outer', q)
    t.query2 = string.format('@%s.inner', q)
  end
  return t
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
  else
    vim_range = {
      ts_utils.get_vim_range({ range.node:range() }, 0),
    }
  end
  return { vim_range[1], vim_range[2] }, { vim_range[3], vim_range[4] }
end

function M:is_node_inside_range(os, oe, inner_node)
  local i_start_line, i_start_col, i_end_line, i_end_col = inner_node:range()
  local cstart = cmp({ i_start_line, i_start_col }, { os[1] - 1, os[2] - 1 })
  local cend = cmp({ i_end_line, i_end_col }, { oe[1] - 1, oe[2] }) -- HACK: why?
  if cstart < 0 then
    return false
  end
  if cend > 0 then
    return false
  end
  return true
end

local function is_node_stricly_inside_node(inner_node, outer_node)
  local i_start_line, i_start_col, i_end_line, i_end_col = inner_node:range()
  local o_start_line, o_start_col, o_end_line, o_end_col = outer_node:range()
  local cstart = cmp(
    { i_start_line, i_start_col },
    { o_start_line, o_start_col }
  )
  local cend = cmp({ i_end_line, i_end_col }, { o_end_line, o_end_col })
  if cstart == 0 and cend == 0 then
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
  matches = vim.tbl_filter(filter_cb, matches)
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

local function earliest(m1, m2)
  return latest(m2, m1)
end

local function shortest_latest(m1, m2)
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

local function widest_latest(m1, m2)
  return shortest_latest(m2, m1)
end

function M:innerize(os, oe)
  if not self.query2 then
    return os, oe
  end

  local function filter_cb(m)
    return m.node and self:is_node_inside_range(os, oe, m.node)
  end

  local matches = search(self.query2, filter_cb, widest_latest)
  local match = matches[1]
  if not match then
    return
  end
  return get_lua_range(match)
end

function M:_search_np(domain, pos, forward, count)
  local row, col = pos[1] - 1, pos[2] - 1
  local query = domain == 'inner' and self.query2 or self.query1

  -- TODO: should it be cached
  local sort_cb = forward and earliest or latest
  local function filter_cb(match)
    local range = { match.node:range() }
    if forward then
      return cmp({ row, col }, { range[1], range[2] }) < 0
    else
      return cmp({ row, col }, { range[3], range[4] }) > 0
    end
  end
  local matches = search(query, filter_cb, sort_cb)
  local match = matches[count]

  if not match then
    return
  end
  return get_lua_range(match)
end

function M:search_all(domain, start, end_)
  local query = domain == 'inner' and self.query2 or self.query1
  local function filter_cb(match)
    local range = { match.node:range() }
    return range[1] >= start - 1 and range[1] < end_ - 1
  end
  local matches = search(query, filter_cb)
  return vim.tbl_map(function(match)
    return { get_lua_range(match) }
  end, matches)
end

function M:search_forward(domain, pos, count)
  return self:_search_np(domain, pos, true, count)
end

function M:search_backward(domain, pos, count)
  return self:_search_np(domain, pos, false, count)
end

-- TODO: skip query1 when blank_text_object
function M:search_upward(domain, pos, count)
  local row, col = pos[1] - 1, pos[2] - 1
  local function filter_cb(m)
    return m.node and ts_utils.is_in_node_range(m.node, row, col)
  end

  -- disabling innerize heuristic on blank_text_object
  local query = self.blank_text_object and domain == 'inner' and self.query2
    or self.query1
  local matches = search(query, filter_cb, shortest_latest)
  local match = matches[count]
  if not match then
    return
  end

  local os, oe = get_lua_range(match)
  if domain == 'outer' or self.blank_text_object then
    return os, oe
  end
  if not self.query2 then
    return
  end
  local is, ie = self:innerize(os, oe)
  if not is then
    return
  end
  if domain == 'inner' then
    return is, ie
  end
  assert(false, string.format('unknown domain %q', domain))
end

return M
