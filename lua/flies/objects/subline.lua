local M = setmetatable({}, { __index = require 'flies.objects.base' })
local utils = require 'flies.objects.utils'

function M.format_result(domain, row, res)
  if domain == 'outer' then
    return res[1] and { row, res[1] }, res[4] and { row, res[4] }
  elseif domain == 'inner' then
    return res[2] and { row, res[2] }, res[3] and { row, res[3] }
  elseif domain == 'both' then
    return res[1] and { row, res[1] },
      res[2] and { row, res[2] },
      res[3] and { row, res[3] },
      res[4] and { row, res[4] }
  else
    assert(false, string.format('unknown domain %q', domain))
  end
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

function M:_search_line(line)
  local ret = {}
  local is, ie, oe
  local len = line:len()
  local os = 1
  while os == 1 and len == 0 or os <= len do
    os, is, ie, oe = self.seek_cb(line, os)
    if not os then
      return ret
    end
    table.insert(ret, { os, is, ie, oe })
    os = oe + 1
  end
  return ret
end

function M:search_upward(domain, init, _)
  local line = require('flies.objects.utils').get_row(init[1])
  local matches = self:_search_line(line)
  for _, match in ipairs(matches) do
    local os, _, _, oe = unpack(match)
    if os <= init[2] and init[2] <= oe then
      return M.format_result(domain, init[1], match)
    end
  end
end

function M:search_forward(domain, init, count)
  for row, line in require('flies.objects.utils').row_forward_iterator(init[1]) do
    local matches = self:_search_line(line)
    for _, match in ipairs(matches) do
      local os = match[1]
      if row > init[1] or os > init[2] then
        count = count - 1
        if count == 0 then
          return M.format_result(domain, row, match)
        end
      end
    end
  end
end

function M:search_all(domain, start, end_)
  local res = {}
  for row, line in require('flies.objects.utils').row_forward_iterator(start) do
    if row + 1 == end_ then
      break
    end
    local matches = self:_search_line(line)
    for _, match in ipairs(matches) do
      table.insert(res, { M.format_result(domain, row, match) })
    end
  end
  return res
end

function M:search_backward(domain, init, count)
  for row, line in require('flies.objects.utils').row_backward_iterator(init[1]) do
    local matches = self:_search_line(line)
    require('flies.utils').reverse(matches)
    for _, match in ipairs(matches) do
      local oe = match[4]
      if row < init[1] or oe < init[2] then
        count = count - 1
        if count == 0 then
          return M.format_result(domain, row, match)
        end
      end
    end
  end
end

function M.new(o)
  setmetatable(o, { __index = M })
  return o
end

-- TODO: change move to move char after separator

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
  local seek_cb = M.lua_pattern(
    string.format('(%s).-()(%s)', char_pat, char_pat)
  )
  local name = string.format('between %q', char_name)
  return M.new { name = name, seek_cb = seek_cb }
end

function M.word()
  return M.new {
    name = 'word',
    seek_cb = M.lua_pattern '()[%w_]+(%s*)',
    blank_text_object = true,
  }
end

function M.vimword()
  return M.new {
    name = 'vimword',
    seek_cb = M.any(
      M.lua_pattern '%S$',
      M.lua_pattern '()%S(%s+)',
      M.lua_pattern '()[%w_]+(%s*)'
    ),
    blank_text_object = true,
  }
end

function M.bigword()
  return M.new {
    name = 'bigword',
    seek_cb = M.lua_pattern '()%S+(%s*)',
    blank_text_object = true,
  }
end

local variable_segment_seek0_cb = M.any(
  M.lua_pattern '()%u+()$',
  M.lua_pattern '()%u+()(%W)',
  M.lua_pattern '()%u+()(%u%S)',
  M.lua_pattern '()%u?%l+(_?)'
)

local function variable_segment_seek_cb(line, init)
  local os, is, ie, oe = variable_segment_seek0_cb(line, init)
  if not os then
    return
  end
  local c = string.sub(line, os - 1, os - 1)
  local d = string.sub(line, oe + 1, oe + 1)
  if (c == '_') and (d == '' or string.find(d, '[%A]')) then
    os = os - 1
  end
  return os, is, ie, oe
end

function M.variable_segment()
  return M.new {
    name = 'variable_segment',
    seek_cb = variable_segment_seek_cb,
    blank_text_object = true,
  }
end

local function line_seek_cb(line, init)
  local len = line:len()
  if len == 0 then
    return 1, 1, nil, 1
  end
  local is = require('flies.objects.utils').line_inner_start(line) or len
  local ie = require('flies.objects.utils').line_inner_end(line)
  return 1, is, ie, len
end

local function line_search_count(self, domain, _, count)
  local line = utils.get_row(count)
  return M.format_result(domain, count, { line_seek_cb(line, count) })
end

function M.line()
  return M.new {
    name = 'line',
    seek_cb = line_seek_cb,
    blank_text_object = true,
    search_count = line_search_count,
  }
end

local function str_seek_cb(delims)
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

function M.string(...)
  local chars = { ... }
  -- local cb = any(unpack(map(chars, search_str)))
  local seek_cb = str_seek_cb(chars)
  local name = string.format('quoted string: %s', table.concat(chars, ', '))
  return M.new { name = name, seek_cb = seek_cb }
end

-- TODO: target style argument object

return M
