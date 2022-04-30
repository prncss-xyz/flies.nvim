local M = require('flies.objects.generic').new()

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

local inner_start = require('flies.objects.utils').line_inner_start
local inner_end = require('flies.objects.utils').line_inner_end

local cmp = require 'flies.objects.utils'.cmp

function M:search_forward(init, count)
  local l = {}
  local targ
  local os, is, ie, oe
  for row, line in require('flies.objects.utils').row_forward_iterator(init[1]) do
    local col_init
    if row == init[1] then
      col_init = init[2]
    else
      col_init = 1
    end
    local last_line = ''
    for col = col_init, line:len() do
      if is and not is[2] then
        is[2] = inner_start(line)
      end
      local char = line:sub(col, col)
      if self.l[char] then
        -- opening
        table.insert(l, self.l[char])
        count = count - 1
        if count == 0 then
          targ = #l
          os = { row, col }
          if col == inner_end(line) then
            is = { os[1] + 1, 1 } -- column will be figured out in next step
          else
            is = { os[1], os[2] + 1 }
          end
        end
      elseif char == l[#l] then
        -- closing
        if targ and #l == targ then
          oe = { row, col }
          if col == 1 then
            ie = { oe[1] - 1, string.len(last_line) }
          else
            ie = { oe[1], oe[2] - 1 }
          end
          if cmp(ie, is) == -1 then
            return os, nil, oe, oe
          end
          return os, is, ie, oe
        end
        table.remove(l)
      end
      last_line = line
    end
  end
end

function M:search_backward(init, count)
  local l = {}
  local targ
  local os, is, ie, oe
  for row, line in require('flies.objects.utils').row_backward_iterator(init[1]) do
    local col_init
    if row == init[1] then
      col_init = init[2]
    else
      col_init = line:len()
    end
    local last_line = ''
    for col = col_init, 1, -1 do
      if is and not is[2] then
        is[2] = inner_end(line)
      end
      local char = line:sub(col, col)
      local c = self.r[char]
      if c then
        -- opening
        table.insert(l, c)
        count = count - 1
        if count == 0 then
          targ = #l
          oe = { row, col }
          if col == 1 then
            ie = { oe[1] - 1, string.len(last_line) } -- column will be figured out in next step
          else
            ie = { oe[1], oe[2] - 1 }
          end
        end
      elseif char == l[#l] then
        -- closing
        if targ and #l == targ then
          os = { row, col }
          if col == string.len(line) then
            is = { os[1] + 1, 1 }
          else
            is = { os[1], os[2] + 1 }
          end
          if cmp(ie, is) == -1 then
            return os, nil, nil, oe
          end
          return os, is, ie, oe
        end
        table.remove(l)
      end
      last_line = line
    end
  end
end

-- TODO: index == len + 1 ??
-- TODO: match inside ts node (comment, string)
function M:search_upward(init, count)
  local l1 = {}
  local l2 = {}
  local os, is, ie, oe
  local last_line = ''
  local fc = true
  for row, line in require('flies.objects.utils').row_forward_iterator(init[1]) do
    local col_init
    if row == init[1] then
      col_init = init[2]
      if self.l[line:sub(col_init, col_init)] then
        col_init = col_init + 1
        fc = false
      end
    else
      col_init = 1
    end
    for col = col_init, line:len() do
      local char = line:sub(col, col)
      if self.l[char] then
        -- opening
        table.insert(l1, self.l[char])
      elseif char == l1[#l1] then
        -- closing
        table.remove(l1)
      elseif self.r[char] then
        table.insert(l2, self.r[char])
        count = count - 1
        if count == 0 then
          oe = { row, col }
          if col == 1 then
            ie = { oe[1] - 1, string.len(last_line) }
          else
            ie = { oe[1], oe[2] - 1 }
          end
          goto done
        end
      end
      last_line = line
    end
  end
  if true then
    return
  end
  ::done::
  require('flies.utils').reverse(l2)
  for row, line in require('flies.objects.utils').row_backward_iterator(init[1]) do
    local col_init
    if row == init[1] then
      col_init = init[2]
      if fc then
        col_init = col_init - 1
      end
    else
      col_init = line:len()
    end
    for col = col_init, 1, -1 do
      local char = line:sub(col, col)
      if self.r[char] then
        -- opening
        table.insert(l2, self.r[char])
      elseif char == l2[#l2] then
        table.remove(l2)
        -- closing
        if #l2 == 0 then
          os = { row, col }
          if col == string.len(line) then
            is = { os[1] + 1, 1 }
          else
            is = { os[1], os[2] + 1 }
          end
          if cmp(ie, is) == -1 then
            return os, nil, oe, oe
          end
          return os, is, ie, oe
        end -- ()
      end
      last_line = line
    end
  end
end

return M
