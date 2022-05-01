local M = setmetatable({}, { __index = require 'flies.objects.generic' })

function M.new(query)
  local o = setmetatable({}, { __index = M })
  o.name = string.format('@%s inner/outer', query)
  o.query1 = string.format('@%s.outer', query)
  o.query2 = string.format('@%s.inner', query)
  return o
end

function M.query(query)
  local o = setmetatable({}, { __index = M })
  o.name = query
  o.query1 = query
  return o
end

local function get_lua_range(range)
  local vim_range
  if range.start then
    local start_range = { range.start.node:range() }
    local node_range = { range.node:range() }
    vim_range = {
      require('nvim-treesitter.ts_utils').get_vim_range({
        start_range[1],
        start_range[2],
        node_range[3],
        node_range[4],
      }, 0),
    }
  else
    vim_range = {
      require('nvim-treesitter.ts_utils').get_vim_range(
        { range.node:range() },
        0
      ),
    }
  end
  return { vim_range[1], vim_range[2] }, { vim_range[3], vim_range[4] }
end

local cmp = require('flies.objects.utils').cmp

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
  local matches =
    require('nvim-treesitter.query').get_capture_matches_recursively(
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

local function get_inner(inner_query, outer_range)
  local ts_utils = require 'nvim-treesitter.ts_utils'

  local function filter_cb(m)
    return m.node and is_node_stricly_inside_node(m.node, outer_range.node)
  end

  local function sort_cb(m1, m2)
    local length1 = ts_utils.node_length(m1.node)
    local length2 = ts_utils.node_length(m2.node)
    if length1 > length2 then
      return true
    end
    if length1 < length2 then
      return false
    end
    -- for nodes with same length take the one with latest end
    local end1 = m1.end_
    local end2 = m2.end_
    if end1 and not end2 then
      return true
    end
    if not end1 then
      return false
    end
    local _, _, end_byte1 = end1.node:start()
    local _, _, end_byte2 = end2.node:start()
    return end_byte1 > end_byte2
  end

  local matches = search(inner_query, filter_cb, sort_cb)
  local match = matches[1]
  return match
end

local function search_np(self, pos, forward, count)
  local function sort_cb(match1, match2)
    if forward then
      local _, _, score1 = match1.node:start()
      local _, _, score2 = match2.node:start()
      return score1 < score2
    else
      local _, _, score1 = match1.node:end_()
      local _, _, score2 = match2.node:end_()
      return score1 > score2
    end
  end

  local function filter_cb(match)
    local range = { match.node:range() }
    if forward then
      return cmp(pos, { range[1] + 1, range[2] }) < 0
    else
      return cmp(pos, { range[3] + 1, range[4] }) > 0
    end
  end
  local matches = search(self.query1, filter_cb, sort_cb)
  local match = matches[count]

  if not match then
    return
  end
  local s, e = get_lua_range(match)
  local os, oe = { s[1], s[2] }, { e[1], e[2] }
  -- empty inner object
  if os[1] == oe[2] and os[2] + 2 == oe[2] then
    return os, nil, oe, oe
  end
  if not self.query2 then
    return os, os, oe, oe
  end

  local inner_range = get_inner(self.query2, match)

  if not inner_range then
    return os, os, oe, oe
  end
  s, e = get_lua_range(inner_range)
  local is, ie = { s[1], s[2] }, { e[1], e[2] }
  return os, is, ie, oe
end

function M:search_forward(pos, count)
  return search_np(self, pos, true, count)
end

function M:search_backward(pos, count)
  return search_np(self, pos, false, count)
end

function M:search_upward(pos, count)
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local row, col = unpack(pos)
  row = row - 1
  local function filter_cb(m)
    return m.node and ts_utils.is_in_node_range(m.node, row, col)
  end

  local function sort_cb(m1, m2)
    local length1 = ts_utils.node_length(m1.node)
    local length2 = ts_utils.node_length(m2.node)
    if length1 < length2 then
      return true
    end
    if length1 > length2 then
      return false
    end
    -- for nodes with same length take the one with earliest start
    local start1 = m1.start
    local start2 = m2.start
    if start1 and not start2 then
      return true
    end
    if not start1 then
      return false
    end
    local _, _, start_byte1 = start1.node:start()
    local _, _, start_byte2 = start2.node:start()
    return start_byte1 < start_byte2
  end

  local matches = search(self.query1, filter_cb, sort_cb)
  local match = matches[count]
  if not match then
    return
  end
  local s, e = get_lua_range(match)
  local os, oe = { s[1], s[2] }, { e[1], e[2] }
  -- empty inner object
  if os[1] == oe[2] and os[2] + 2 == oe[2] then
    return os, nil, oe, oe
  end
  if not self.query2 then
    return os, os, oe, oe
  end

  local inner_range = get_inner(self.query2, match)

  if not inner_range then
    return os, os, oe, oe
  end
  s, e = get_lua_range(inner_range)
  local is, ie = { s[1], s[2] }, { e[1], e[2] }
  return os, is, ie, oe
end

return M
