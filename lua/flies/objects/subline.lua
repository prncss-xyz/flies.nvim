local M = {}

local function any(...)
  local cbs = { ... }
  return function(line, init)
    local res = {}
    for _, cb in ipairs(cbs) do
      local res0 = { cb(line, init) }
      if not res[1] then
        res = res0
      elseif res[1] and res0[1] and (res0[1] < res[1]) then
        res = res0
      end
    end
    if res[1] then
      return unpack(res)
    end
  end
end

local function lua_pattern(pattern)
  return function(line, init)
    local os, oe, cs, ce, cd
    os, oe, cs, ce, cd = string.find(line, pattern, init)
    if not os then
      return
    end
    local is, ie = os, oe
    if type(cs) == 'string' then
      is = is + cs:len()
    end
    if type(ce) == 'string' then
      ie = ie - ce:len()
    end
    if type(cd) == 'string' then
      oe = oe - cd:len()
      ie = ie - cd:len()
    end
    return os, is, ie, oe
  end
end

local function search_forward(cb, in_place, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  for row, line in
    require('flies.objects.utils').row_forward_iterator(cursor[1])
  do
    local os = 1
    while true do
      local oe, is, ie
      os, is, ie, oe = cb(line, os)
      if not os then
        break
      end
      local col = cursor[2] + 1
      if
        row > cursor[1]
        or in_place and (os <= col and col <= oe)
        or os > col
      then
        if count == 1 then
          return row, os, is, ie, oe
        end
        count = count - 1
      end
      os = oe + 1
    end
  end
end

local function search_backward(cb, in_place, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  for row, line in
    require('flies.objects.utils').row_backward_iterator(cursor[1])
  do
    local os = 1
    local res = {}
    while true do
      local oe, is, ie
      os, is, ie, oe = cb(line, os)
      local col = cursor[2] + 1
      if
        os
        and (
          row < cursor[1]
          or in_place and (os <= col and col <= oe)
          or os < col
        )
      then
        table.insert(res, { os, is, ie, oe })
        os = oe + 1
      else
        local i = 1 + #res - count
        local r = res[i]
        if r then
          return row, unpack(r)
        end
        count = count - #res
        break
      end
    end
  end
end

function M.new(search_cb, name)
  return setmetatable(
    { search_cb = search_cb, name = name or 'regex' },
    { __index = M }
  )
end

function M:move(domain, qualifier, start, _)
  local row, os, is, ie, oe
  if qualifier == 'next' then
    row, os, is, ie, oe = search_forward(self.search_cb, false, vim.v.count1)
  elseif qualifier == 'previous' then
    row, os, is, ie, oe = search_backward(self.search_cb, false, vim.v.count1)
  end
  if not row then
    return
  end
  local s, e
  if domain == 'inner' then
    s, e = is, ie
  elseif domain == 'outer' then
    s, e = os, oe
  end
  local col = start and s or e
  vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

function M:textobject_outer_plain(_)
  local row, os, _, _, oe = search_forward(self.search_cb, true, vim.v.count1)
  if not row then
    return
  end
  require('flies.objects.utils').update_selection({ row, os }, { row, oe })
end

function M:textobject_inner_plain(_)
  local row, _, is, ie, _ = search_forward(self.search_cb, true, vim.v.count1)
  if not row then
    return
  end
  require('flies.objects.utils').update_selection({ row, is }, { row, ie })
end

function M:textobject_outer_np(qualifier, _)
  local row, os, oe
  if qualifier == 'next' then
    row, os, _, _, oe = search_forward(self.search_cb, false, vim.v.count1)
  elseif qualifier == 'previous' then
    row, os, _, _, oe = search_backward(self.search_cb, false, vim.v.count1)
  end
  if not row then
    return
  end
  require('flies.objects.utils').update_selection({ row, os }, { row, oe })
end

function M:textobject_inner_np(qualifier, _)
  local row, is, ie
  if qualifier == 'next' then
    row, _, is, ie, _ = search_forward(self.search_cb, false, vim.v.count1)
  elseif qualifier == 'previous' then
    row, _, is, ie, _ = search_backward(self.search_cb, false, vim.v.count1)
  end
  if not row then
    return
  end
  require('flies.objects.utils').update_selection({ row, is }, { row, ie })
end

-- TODO: change move to move char after separator

M.separator = setmetatable({}, { __index = M })

local function lua_regex_escape_char(char)
  if char == '%' then
    char = '%%'
  elseif char == '^' then
    char = '%^'
  end
  return string.format('[%s]', char)
end

function M.separator.new(char_name)
  local char_pat = lua_regex_escape_char(char_name)
  local search_cb = lua_pattern(
    string.format('(%s).-()(%s)', char_pat, char_pat)
  )
  local move_cb = lua_pattern(char_pat)
  local name = string.format('between %q', char_name)

  return setmetatable({
    search_cb = search_cb,
    move_cb = move_cb,
    name = name,
  }, { __index = M.separator })
end

function M.separator:move(domain, qualifier, start, _)
  local row, os, is, ie, oe
  if qualifier == 'next' then
    row, os, is, ie, oe = search_forward(self.move_cb, false, vim.v.count1)
  elseif qualifier == 'previous' then
    row, os, is, ie, oe = search_backward(self.move_cb, false, vim.v.count1)
  end
  if not row then
    return
  end
  local s, e
  if domain == 'inner' then
    s, e = is, ie
  elseif domain == 'outer' then
    s, e = os, oe
  end
  local col = start and s or e
  vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

-- TODO: use vim.regex instead of lua patters

M.word = M.new(lua_pattern '()[%w_]+(%s*)', 'word')

M.vimword = M.new(
  any(lua_pattern '%S$', lua_pattern '()%S(%s+)', lua_pattern '()[%w_]+(%s*)'),
  'vimword'
)

M.bigword = M.new(lua_pattern '()%S+(%s*)', 'bigword')

M.variable_segment = M.new(
  any(
    lua_pattern '()%u+()$',
    lua_pattern '()%u+()(%W)',
    lua_pattern '()%u+()(%u%S)',
    lua_pattern '()%u?%l+(_?)'
  ),
  'variable segment'
)

function M.variable_segment:textobject_outer_plain(_)
  local row, os, _, _, oe = search_forward(self.search_cb, true, vim.v.count1)
  if not row then
    return
  end
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  local c = string.sub(line, os - 1, os - 1)
  local d = string.sub(line, oe + 1, oe + 1)
  if (c == '_') and (not d or string.find(d, '[%A]')) then
    os = os - 1
  end
  require('flies.objects.utils').update_selection({ row, os }, { row, oe })
end

function M.variable_segment:textobject_outer_np(qualifier, _)
  local row, os, oe
  if qualifier == 'next' then
    row, os, _, _, oe = search_forward(self.search_cb, false, vim.v.count1)
  else
    row, os, _, _, oe = search_forward(self.search_cb, false, vim.v.count1)
  end
  if not row then
    return
  end
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  local c = string.sub(line, os - 1, os - 1)
  local d = string.sub(line, oe + 1, oe + 1)
  if (c == '_') and (not d or string.find(d, '[%A]')) then
    os = os - 1
  end
  require('flies.objects.utils').update_selection({ row, os }, { row, oe })
end

-- TODO: start search from begining
local function search_str(delims)
  local d = require('flies.utils').invert(delims)
  return function(line, init)
    local os
    local delim
    local esc = false
    for i = init, line:len() do
      local c = string.sub(line, i, i)
      if esc then
        esc = false
      elseif c == delim then
        -- TODO: zero length string
        return os, os + 1, i - 1, i
      elseif d[c] then
        os = i
        delim = c
      elseif c == '\\' then
        esc = true
      end
    end
  end
end

function M.string(...)
  local chars = { ... }
  -- local cb = any(unpack(map(chars, search_str)))
  local cb = search_str(chars)
  local name = string.format('quoted string: %s', table.concat(chars, ', '))
  return setmetatable(
    { search_cb = cb, name = name or 'lua_pattern' },
    { __index = M }
  )
end

-- TODO: target style argument object

return M
