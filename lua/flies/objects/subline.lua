local M = setmetatable({}, { __index = require 'flies.objects.generic' })

-- local M = require('flies.objects.generic').new()

local function with_row2(row, s, e)
  return s and { row, s }, e and { row, e }
end

local function with_row4(row, os, is, ie, oe)
  return os and { row, os },
    is and { row, is },
    ie and { row, ie },
    oe and { row, oe }
end

function M.any(...)
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

function M.lua_pattern(pattern)
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

function M:search_upward(domain, init, count)
  if count > 1 then
    return
  end
  local line_str = require('flies.objects.utils').get_row(init[1])
  local col = init[2]
  local os = 1
  local is, ie, oe
  while true do
    os, is, ie, oe = self.search_cb(line_str, os)
    if not os then
      return
    end
    if os <= col and col <= oe then
      local line = init[1]
      if domain == 'outer' then
        return with_row2(line, os, oe)
      elseif domain == 'inner' then
        return with_row2(line, is, ie)
      elseif domain == 'both' then
        return with_row4(line, os, is, ie, oe)
      else
        assert(false, string.format('unknown domain %q', domain))
      end
    elseif os > col then
      return
    end
    os = oe + 1
  end
end

function M:search_forward(domain, init, count)
  for row, line_str in
    require('flies.objects.utils').row_forward_iterator(init[1])
  do
    local os = 1
    while true do
      local oe, is, ie
      os, is, ie, oe = self.search_cb(line_str, os)
      if not os then
        break
      end
      if row > init[1] or os > init[2] then
        if count == 1 then
          if domain == 'outer' then
            return with_row2(row, os, oe)
          elseif domain == 'inner' then
            return with_row2(row, is, ie)
          elseif domain == 'both' then
            return with_row4(row, os, is, ie, oe)
          else
            assert(false, string.format('unknown domain %q', domain))
          end
        end
        count = count - 1
      end
      os = oe + 1
    end
  end
end

function M:search_backward(domain, init, count)
  for row, line_str in
    require('flies.objects.utils').row_backward_iterator(init[1])
  do
    local os = 1
    local res = {}
    while true do
      local oe, is, ie
      os, is, ie, oe = self.search_cb(line_str, os)
      if os and (row < init[1] or os < init[2]) then
        table.insert(res, { os, is, ie, oe })
        os = oe + 1
      else
        local i = 1 + #res - count
        local r = res[i]
        if r then
          os, is, ie, oe = unpack(r)
          if domain == 'outer' then
            return with_row2(row, os, oe)
          elseif domain == 'inner' then
            return with_row2(row, is, ie)
          elseif domain == 'both' then
            return with_row4(row, os, is, ie, oe)
          else
            assert(false, string.format('unknown domain %q', domain))
          end
        end
        count = count - #res
        break
      end
    end
  end
end

function M.new(o)
  setmetatable(o, { __index = M })
  return o
end

-- TODO: change move to move char after separator

local function lua_regex_escape_char(char)
  if char == '%' then
    char = '%%'
  elseif char == '^' then
    char = '%^'
  end
  return string.format('[%s]', char)
end

function M.separator(char_name)
  local char_pat = lua_regex_escape_char(char_name)
  local search_cb = M.lua_pattern(
    string.format('(%s).-()(%s)', char_pat, char_pat)
  )
  local name = string.format('between %q', char_name)
  return M.new { name = name, search_cb = search_cb }
end

function M.word()
  return M.new { name = 'word', search_cb = M.lua_pattern '()[%w_]+(%s*)' }
end

function M.vimword()
  return M.new {
    name = 'vimword',
    search_cb = M.any(
      M.lua_pattern '%S$',
      M.lua_pattern '()%S(%s+)',
      M.lua_pattern '()[%w_]+(%s*)'
    ),
  }
end

function M.bigword()
  return M.new { name = 'bigword', search_cb = M.lua_pattern '()%S+(%s*)' }
end

local function variable_segment_post_proc(_, os, is, ie, oe)
  local line = require('flies.objects.utils').get_row(os[1])
  local c = string.sub(line, os[2] - 1, os[2] - 1)
  local d = string.sub(line, oe[2] + 1, oe[2] + 1)
  if (c == '_') and (d == '' or string.find(d, '[%A]')) then
    os[2] = os[2] - 1
  end
  return os, is, ie, oe
end

function M.variable_segment()
  local o = M.new {
    name = 'variable_segment',
    search_cb = M.any(
      M.lua_pattern '()%u+()$',
      M.lua_pattern '()%u+()(%W)',
      M.lua_pattern '()%u+()(%u%S)',
      M.lua_pattern '()%u?%l+(_?)'
    ),
    post_proc = variable_segment_post_proc,
  }
  return o
end

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
      elseif c == '\\' then
        esc = true
      elseif c == delim then
        -- TODO: zero length string
        if os + 1 == i then
          return os, i, nil, i
        end
        return os, os + 1, i - 1, i
      elseif d[c] and not delim then
        os = i
        delim = c
      end
    end
  end
end

local function succ(line, init, p1, pats)
  line = string.sub(line, init)
  local ofs = init
  line = string.sub(line, init)
  local s, e = p1:match_str(line)
  if not s then
    return
  end
  local res = { ofs + s }
  for _, pat in ipairs(pats) do
    ofs = ofs + e
    table.insert(res, ofs)
    line = string.sub(line, e + 1)
    s, e = pat:match_str(line)
    if s ~= 0 then
      return
    end
  end
  ofs = ofs + e
  table.insert(res, ofs)
  return res
end

local function vim_pattern(a, b, c)
  if a and not b and not c then
    return function(line, init)
      local r = succ(line, init, vim.regex(a), {})
      if not r then
        return
      end
      local s, e = unpack(r)
      e = e - 1
      return s, s, e, e
    end
  end
  if a and b and not c then
    return function(line, init)
      local r = succ(line, init, vim.regex(a), { vim.regex(b) })
      if not r then
        return
      end
      local is, ie, oe = unpack(r)
      oe = oe - 1
      return is, is, ie, oe
    end
  end
  if a and b and c then
    return function(line, init)
      local r = succ(line, init, vim.regex(a), { vim.regex(b), vim.regex(c) })
      if not r then
        return
      end
      local os, is, ie, oe = unpack(r)
      oe = oe - 1
      return os, is, ie, oe
    end
  end
  assert(false)
end

function M.string(...)
  local chars = { ... }
  -- local cb = any(unpack(map(chars, search_str)))
  local search_cb = search_str(chars)
  local name = string.format('quoted string: %s', table.concat(chars, ', '))
  return M.new { name = name, search_cb = search_cb }
end

-- TODO: target style argument object

return M
