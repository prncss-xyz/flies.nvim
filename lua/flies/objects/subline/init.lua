local M = require('flies.objects.base'):new()
local utils = require 'flies.objects.utils'
local f = require 'flies.util.iterator'

function M.format_result(domain, row, res)
  if domain == 'outer' then
    return res[1] and { row, res[1] }, res[4] and { row, res[4] }
  elseif domain == 'inner' then
    return res[2] and { row, res[2] }, res[3] and { row, res[3] }
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

function M:_search_iter(line)
  local function iter(_, oe)
    oe = oe + 1
    local os, is, ie
    os, is, ie, oe = self.seek_cb(line, oe)
    return oe, os, ie, is
  end
  return iter, nil, 0
end

function M:up_iterator(domain, init)
  local line = require('flies.objects.utils').get_row(init[1])
  -- TODO: use filter
  local matches = self:_search_line(line)
  for _, match in ipairs(matches) do
    local os, _, _, oe = unpack(match)
    if os <= init[2] and init[2] <= oe then
      return f.once(M.format_result(domain, init[1], match))
    end
  end
  return f.null
end

function M:np_iterator(domain, init, forward, start, extremum)
  local ndx
  if domain == 'outer' then
    if start then
      ndx = 1
    else
      ndx = 4
    end
  else
    if start then
      ndx = 2
    else
      ndx = 3
    end
  end
  local row_iterator = forward and utils.row_forward_iterator
    or utils.row_backward_iterator
  local match_iterator = forward and pairs or require('flies.utils').ripairs
  local function cond(row, match)
    if forward then
      return row > init[1] or match[ndx] > init[2]
    else
      return row < init[1] or match[ndx] < init[2]
    end
  end
  return coroutine.wrap(function()
    local i = 0
    for row, line in row_iterator(init[1], extremum) do
      local matches = self:_search_line(line)
      for _, match in match_iterator(matches) do
        if cond(row, match) then
          i = i + 1
          coroutine.yield(M.format_result(domain, row, match))
        end
      end
    end
  end)
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

M.separator = M:new()

function M.separator:new(char_name)
  local char_pat = lua_regex_escape_char(char_name)
  local seek_cb = M.lua_pattern(
    string.format('(%s).-()(%s)', char_pat, char_pat)
  )
  local name = string.format('between %q', char_name)
  return self:super('new', { name = name, seek_cb = seek_cb })
end

-- M.separator = M:new()
--
-- function M.separator(char_name)
--   local char_pat = lua_regex_escape_char(char_name)
--   local seek_cb = M.lua_pattern(
--     string.format('(%s).-()(%s)', char_pat, char_pat)
--   )
--   local name = string.format('between %q', char_name)
--   return M:new { name = name, seek_cb = seek_cb }
-- end

-- %f[set] matches an empty string such that next char belongs to set and previous does not

local magic = '().%+-*?[]^$'
local exclude = '_'
local function ascii_range(acc, from, to_)
  for j = from, to_ do
    local char = string.char(j)
    if not string.find(exclude, char, 1, true) then
      if string.find(magic, char, 1, true) then
        char = '%' .. char
      end
      acc = acc .. char
    end
  end
  return acc
end
local punctuation_chars = ''
punctuation_chars = ascii_range(punctuation_chars, 33, 47)
punctuation_chars = ascii_range(punctuation_chars, 58, 64)
punctuation_chars = ascii_range(punctuation_chars, 91, 96)
punctuation_chars = ascii_range(punctuation_chars, 123, 126)

M.word = M:new {
  name = 'word',
  seek_cb = M.lua_pattern('()[^%s' .. punctuation_chars .. ']+(%s*)'),
  blank_text_object = true,
}

M.vimword = M:new {
  name = 'vimword',
  seek_cb = M.any(
    M.lua_pattern('()[' .. punctuation_chars .. ']+(%s*)'),
    M.lua_pattern('()[^%s' .. punctuation_chars .. ']+(%s*)')
  ),
  blank_text_object = true,
}

M.bigword = M:new {
  name = 'bigword',
  seek_cb = M.lua_pattern '()%S+(%s*)',
  blank_text_object = true,
}

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

M.string = M:new()

function M.string:new(o)
  local chars = o
  -- local cb = any(unpack(map(chars, search_str)))
  local seek_cb = str_seek_cb(chars)
  local name = string.format('quoted string: %s', table.concat(chars, ', '))
  return self:super('new', { name = name, seek_cb = seek_cb })
end

return M
