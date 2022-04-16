local M = {}

function M.new(pattern, name)
  return setmetatable(
    { pattern = pattern, name = name or 'regex' },
    { __index = M }
  )
end

local function search_forward(pattern, domain, in_place, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  for row, line in
    require('flies.objects.utils').row_forward_iterator(cursor[1])
  do
    local s = 1
    while true do
      local e, cs, ce
      s, e, cs, ce = string.find(line, pattern, s + 1)
      if not s then
        break
      end
      local rs, re = s, e
      if domain == 'inner' then
        if type(cs) == 'string' then
          rs = rs + cs:len()
        end
        if type(ce) == 'string' then
          re = re - ce:len()
        end
      end
      if
        row > cursor[1]
        or in_place and rs == cursor[2] + 1
        or rs > cursor[2] + 1
      then
        if count == 1 then
          return row, rs, re
        end
        count = count - 1
      end
    end
  end
end

local function search_backward(pattern, domain, in_place, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  for row, line in
    require('flies.objects.utils').row_backward_iterator(cursor[1])
  do
    local s = 1
    local res = {}
    while true do
      local e, cs, ce
      s, e, cs, ce = string.find(line, pattern, s + 1)
      local rs, re = s, e
      if s then
        if domain == 'inner' then
          if type(cs) == 'string' then
            rs = rs + cs:len()
          end
          if type(ce) == 'string' then
            re = re - ce:len()
          end
        end
      end
      if
        s
        and (
          row < cursor[1]
          or in_place and rs == cursor[2] + 1
          or rs < cursor[2] + 1
        )
      then
        table.insert(res, { rs, re })
      else
        local i = 1 + #res - count
        local r = res[i]
        if r then
          return row, r[1], r[2]
        end
        count = count - #res
        break
      end
    end
  end
end

function M:move(domain, qualifier, start, _)
  local row, s, e
  domain = 'inner'
  if qualifier == 'next' then
    row, s, e = search_forward(self.pattern, domain, false, vim.v.count1)
  else
    row, s, e = search_backward(self.pattern, domain, false, vim.v.count1)
  end
  local col = start and s or e
  if not row then
    return
  end
  vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

function M:textobject_outer_plain(_)
  local row, s, e = search_forward(self.pattern, 'outer', true, vim.v.count1)
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

function M:textobject_inner_plain(_)
  local row, s, e = search_forward(self.pattern, 'inner', true, vim.v.count1)
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

function M:textobject_outer_np(qualifier, _)
  local row, s, e
  if qualifier == 'next' then
    row, s, e = search_forward(self.pattern, 'outer', false, vim.v.count1)
  else
    row, s, e = search_backward(self.pattern, 'outer', false, vim.v.count1)
  end
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

function M:textobject_inner_np(qualifier, _)
  local row, s, e
  if qualifier == 'next' then
    row, s, e = search_forward(self.pattern, 'inner', false, vim.v.count1)
  else
    row, s, e = search_backward(self.pattern, 'inner', false, vim.v.count1)
  end
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

return M
