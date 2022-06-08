local M = require('flies.objects.base'):new()
local util = require 'flies.objects.utils'
local f = require 'flies.util.iterator'
local cmp = util.cmp

-- TODO: zero length range

function M:new(o)
  local l = {}
  local r = {}
  local wrap_l, wrap_r = unpack(o[1])
  if wrap_l == wrap_r then
    wrap_r = ''
  end
  o.wrap_l = wrap_l
  o.wrap_r = wrap_r
  local name = ''
  for _, v in ipairs(o) do
    l[v[1]] = v[2]
    r[v[2]] = v[1]
    name = name .. v[1] .. v[2]
  end
  o.l = l
  o.r = r
  o.name = name
  return self:super('new', o)
end

M.lookup_lines = 200

function M:innerize(os, oe)
  local is, ie
  if os[1] == oe[1] then
    is = { os[1], os[2] + 1 }
    ie = { oe[1], oe[2] - 1 }
  else
    local line = util.get_row(os[1])
    if util.line_inner_end(line) > os[2] then
      is = { os[1], os[2] + 1 }
    else
      local is_row = os[1] + 1
      line = util.get_row(is_row)
      local is_col = util.line_inner_start(line) or 1
      is = { is_row, is_col }
    end

    line = util.get_row(oe[1])
    if util.line_inner_start(line) < oe[2] then
      ie = { oe[1], oe[2] - 1 }
    else
      local ie_row = oe[1] - 1
      line = util.get_row(ie_row)
      local ie_col = util.line_inner_end(line) or 1
      ie = { ie_row, ie_col }
    end
  end
  if cmp(is, ie) < 1 then
    return is, ie
  else
    return ie
  end
end

function M:np_iterator(domain, init, forward, start, extremum)
  local limit_reverse
  local limit_direct
  if forward then
    limit_direct = init[1] + M.lookup_lines
    limit_reverse = init[1] - M.lookup_lines
  else
    limit_direct = init[1] - M.lookup_lines
    limit_reverse = init[1] + M.lookup_lines
  end
  local res = {}
  local res_s = {}
  local skip_first_rev = true
  local openers = forward and self.l or self.r
  local closers = forward and self.r or self.l
  local char_reverse_iterator = forward and util.char_backward_iterator
    or util.char_forward_iterator
  local char_direct_iterator = forward and util.char_forward_iterator
    or util.char_backward_iterator
  local gen = char_reverse_iterator(init, limit_reverse)
  local function reverse(target)
    local l = {}
    return f.head(f.chain(function(row, col, char)
      if row == init[1] and col == init[2] and skip_first_rev then
        return f.null
      end
      if char == l[#l] then
        table.remove(l)
        return f.null
      end
      if closers[char] then
        -- opening
        table.insert(l, closers[char])
        return f.null
      end
      if #l == 0 and char == target then
        return f.once { row, col }
      end
      return f.null
    end)(gen))
  end
  local l = {}
  local function main(row, col, char)
    if forward and extremum and row > extremum then
      return
    end
    if not forward and extremum and row < extremum then
      return
    end
    if row == init[1] and col == init[2] and openers[char] then
      skip_first_rev = false
      return f.null
    end
    if char == l[#l] then
      -- closing
      table.remove(l)
      local s = table.remove(res_s)
      local e = { row, col }
      if not forward then
        s, e = e, s
      end
      if domain == 'inner' then
        s, e = self:innerize(s, e)
      end
      if forward == start then
        table.insert(res, { s, e })
        if #l == 0 then
          return f.map(function(_, t)
            return unpack(t)
          end)(require('flies.utils').ripairs(res))
        else
          return f.null
        end
      else
        return f.once(s, e)
      end
    end
    if openers[char] then
      -- opening
      table.insert(l, openers[char])
      table.insert(res_s, { row, col })
      return f.null
    end
    if not start and #l == 0 and closers[char] then
      local s = reverse(closers[char])
      local e = { row, col }
      if not forward then
        s, e = e, s
      end
      if domain == 'inner' then
        s, e = self:innerize(s, e)
      end
      return f.once(s, e)
    end
    return f.null
  end
  return f.chain(main)(char_direct_iterator(init, limit_direct))
end

-- TODO: make it work with identical left and right symbols
function M:up_iterator(domain, init)
  local limit_reverse
  local limit_direct
  limit_direct = init[1] + M.lookup_lines
  limit_reverse = init[1] - M.lookup_lines
  local skip_first_rev = true
  local openers = self.l
  local closers = self.r
  local gen = util.char_backward_iterator(init, limit_reverse)
  local function reverse(target)
    local l = {}
    return f.head(f.chain(function(row, col, char)
      if row == init[1] and col == init[2] and skip_first_rev then
        return f.null
      end
      if char == l[#l] then
        table.remove(l)
        return f.null
      end
      if #l == 0 and char == target then
        return f.once { row, col }
      end
      if closers[char] then
        -- opening
        table.insert(l, closers[char])
        return f.null
      end
      return f.null
    end)(gen))
  end
  local l = {}
  local lrow, lcol
  local function main(row, col, char)
    if row == init[1] and col == init[2] and openers[char] then
      skip_first_rev = false
      lrow, lcol = row, col
      return f.null
    end
    if char == l[#l] then
      -- closing
      table.remove(l)
      lrow, lcol = row, col
      return f.null
    end
    if #l == 0 and closers[char] then
      local s = reverse(closers[char])
      local e
      if char == closers[char] then
        if lrow then
          e = { lrow, lcol }
        else
          e = s
        end
      else
        e = { row, col }
      end
      if domain == 'inner' then
        s, e = self:innerize(s, e)
      end
      return f.once(s, e)
    end
    if openers[char] then
      -- opening
      table.insert(l, openers[char])
      lrow, lcol = row, col
      return f.null
    end
    lrow, lcol = row, col
    return f.null
  end
  return f.chain(main)(util.char_forward_iterator(init, limit_direct))
end

function M:wrap(s, e, w, reversed)
  local l, r = self.wrap_l, self.wrap_r
  if not self.reversed ~= not reversed then
    l, r = r, l
  end
  require('flies.utils').strip(s, s, e, e, l, r)
end

function M:substitute(os, is, ie, oe, w, reversed)
  local l, r = self.wrap_l, self.wrap_r
  if not self.reversed ~= not reversed then
    l, r = r, l
  end
  require('flies.utils').strip(os, is, ie, oe, l, r)
end

return M
