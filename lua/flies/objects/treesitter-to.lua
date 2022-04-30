local M = setmetatable({}, { __index = require 'flies.objects.generic' })

function M.new(query)
  local o = setmetatable({}, { __index = M })
  o.name = string.format('@%s inner/outer', query)
  o.query = query
  return o
end

local function get_range(smallest_range)
  local s, e
  if smallest_range.start then
    local start_range = { smallest_range.start.node:range() }
    local node_range = { smallest_range.node:range() }
    s = { start_range[1], start_range[2] }
    e = {
      node_range[3],
      node_range[4],
    }
  else
    local a1, a2, b1, b2 = smallest_range.node:range()
    s = { a1, a2 }
    e = { b1, b2 }
  end
  return s, e
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

local function search_next(query_string, pos, count, forward) end

function M:search_forward(pos, count)
  local os, oe = search_next(pos, count, true)
  -- TODO: find inner
  return os, os, oe, oe
end

function M:search_backward(pos, count)
  local os, oe = search_next(pos, count, false)
  -- TODO: find inner
  return os, os, oe, oe
end

function M:get_queries()
  local parsers = require 'nvim-treesitter.parsers'
  local queries = require 'nvim-treesitter.query'
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = parsers.get_buf_lang(bufnr)
  if not lang then
    -- TODO: fallback
    print 'no tree, fallback'
    return
  end

  local parsed_queries = queries.get_query(lang, 'textobjects')
  local found_textobjects = parsed_queries and parsed_queries.captures or {}

  local has_outer = vim.tbl_contains(found_textobjects, self.query .. '.outer')
  local has_inner = vim.tbl_contains(found_textobjects, self.query .. '.inner')

  local query1 = has_outer and string.format('@%s.outer', self.query)
    or has_inner and string.format('@%s.inner', self.query)
  local query2 = has_outer
    and has_inner
    and string.format('@%s.inner', self.query)

  if not query1 then
    -- TODO:
    print 'no obj, fallback'
    dump(found_textobjects)
    return
  end

  return query1, query2
end

function M:search_upward(pos, _)
  local ts_utils = require 'nvim-treesitter.ts_utils'
  local queries = require 'nvim-treesitter.query'
  local bufnr = vim.api.nvim_get_current_buf()

  local query1, query2 = self:get_queries()

  if not query1 then
    -- TODO:
    return
  end

  local row, col = unpack(pos)
  row = row - 1

  local matches
  local match_length
  local smallest_range
  local earliest_start

  matches = queries.get_capture_matches_recursively(
    bufnr,
    query1,
    'textobjects'
  )
  for _, m in pairs(matches) do
    if m.node then
      if ts_utils.is_in_node_range(m.node, row, col) then
        local length = ts_utils.node_length(m.node)
        if not match_length or length < match_length then
          smallest_range = m
          match_length = length
        end
        -- for nodes with same length take the one with earliest start
        if match_length and length == smallest_range then
          local start = m.start
          if start then
            local _, _, start_byte = m.start.node:start()
            dump('.!', start_byte)
            if not earliest_start or start_byte < earliest_start then
              smallest_range = m
              match_length = length
              earliest_start = start_byte
            end
          end
        end
      end
    end
  end

  if not smallest_range then
    return
  end
  local s, e = get_range(smallest_range)
  local os, oe = { s[1] + 1, s[2] }, { e[1] + 1, e[2] }
  -- empty inner object
  if os[1] == oe[2] and os[2] + 2 == oe[2] then
    return os, nil, oe, oe
  end
  if not query2 then
    return os, os, oe, oe
  end

  local largest_range
  local latest_stop
  match_length = nil
  matches = queries.get_capture_matches_recursively(
    bufnr,
    query2,
    'textobjects'
  )
  for _, m in pairs(matches) do
    -- if m.node and ts_utils.is_in_node_range(m.node, row, col) then
    if m.node and is_node_stricly_inside_node(m.node, smallest_range.node) then
      local length = ts_utils.node_length(m.node)
      if not match_length or length > match_length then
        largest_range = m
        match_length = length
      end
      -- for nodes with same length take the one with earliest start
      if match_length and length == largest_range then
        local stop = m.stop
        if stop then
          local _, _, stop_byte = m.stop.node:end_()
          dump('..', stop_byte)
          if not latest_stop or stop_byte > latest_stop then
            largest_range = m
            match_length = length
            latest_stop = stop_byte
          end
        end
      end
    end
  end

  if not largest_range then
    print ':-('
    return os, os, oe, oe
  end
  s, e = get_range(largest_range)
  local is, ie = { s[1] + 1, s[2] }, { e[1] + 1, e[2] }
  return os, is, ie, oe
end

return M
