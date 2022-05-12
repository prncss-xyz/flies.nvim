local M = require('flies.objects.base').new()
local util = require 'flies.objects.utils'
local cmp = util.cmp
local fun = require 'flies.util.fun'

-- new
-- local function search_forward(cb, in_place, count) end
-- local function search_backward(cb, in_place, count) end
-- local function search_upward(cb, in_place, count) end
-- selection_mode, os, is, ie, oe

-- TODO: zero length range

function M.new(p)
  local l = {}
  local r = {}
  local name = ''
  for _, v in ipairs(p) do
    l[v[1]] = v[2]
    r[v[2]] = v[1]
    name = name .. v[1] .. v[2]
  end
  return setmetatable({
    l = l,
    r = r,
    name = name,
  }, { __index = M })
end

function M:innerize(os, oe)
  local is, ie
  if os[1] == oe[1] then
    is = { os[1], os[2] + 1 }
    ie = { oe[1], oe[2] - 1 }
  else
    local is_row = os[1] + 1
    local line = util.get_row(is_row)
    local is_col = util.line_inner_start(line) or 1
    is = { is_row, is_col }

    local ie_row = oe[1] - 1
    line = util.get_row(is_row)
    local ie_col = util.line_inner_end(line) or 1
    ie = { ie_row, ie_col }
  end
  if cmp(is, ie) < 1 then
    return is, ie
  else
    return ie
  end
end

function M:np_iterator(domain, init, forward, start, extremum)
  local l = {}
  local res = {}
  local res_s = {}
  local i = 0
  local openers = forward and self.l or self.r
  local char_iter = forward and util.char_forward_iterator
    or util.char_backward_iterator
  local iter = char_iter(init, extremum)

  return function()
    while true do
      if #l == 0 then
        if #res > 0 then
          i = i + 1
          return i, unpack(table.remove(res))
        end
      end
      local row, col, char = iter()
      if not row then
        return
      end
      if row == init[1] and col == init[2] then
      else
        -- closing
        if char == l[#l] then
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
          else
            i = i + 1
            return i, s, e
          end
        elseif openers[char] then
          -- opening
          table.insert(l, openers[char])
          table.insert(res_s, { row, col })
        end
      end
    end
  end
end

function M:up_iterator(domain, init)
  local skip_first_rev = true
  local reverse = coroutine.create(function(target, e)
    local openers = self.r
    local l = {}
    local i = 0
    local s
    for row, col, char in util.char_backward_iterator(init) do
      if row == init[1] and col == init[2] and skip_first_rev then
      elseif char == l[#l] then
        table.remove(l)
      elseif openers[char] then
        -- opening
        table.insert(l, openers[char])
      elseif #l == 0 and char == target then
        if domain == 'inner' then
          s, e = self:innerize({ row, col }, e)
        end
        i = i + 1
        target, e = coroutine.yield(i, s, e)
      end
    end
  end)
  local openers = self.l
  local closers = self.r
  local function main(row, col, char)
    local l = {}
    if row == init[1] and col == init[2] and openers[char] then
      skip_first_rev = false
    elseif char == l[#l] then
      -- closing
      table.remove(l)
    elseif openers[char] then
      -- opening
      table.insert(l, openers[char])
    elseif #l == 0 and closers[char] then
      local _, i, s, e = coroutine.resume(reverse, closers[char], { row, col })
      return i, s, e
    end
  end
  return require 'flies.util.iter'.transform(main)(util.char_forward_iterator(init))
end

return M
