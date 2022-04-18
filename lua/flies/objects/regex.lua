local M = {}

function M.new(patterns, name)
  if type(patterns) == 'string' then
    patterns = { patterns }
  end
  return setmetatable(
    { patterns = patterns, name = name or 'regex' },
    { __index = M }
  )
end

local function find_patterns(patterns, line, init)
  local res = {}
  for _, pattern in ipairs(patterns) do
    local res0 = { string.find(line, pattern, init) }
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

local function search_forward(patterns, domain, in_place, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  for row, line in
    require('flies.objects.utils').row_forward_iterator(cursor[1])
  do
    local s = 0
    while true do
      local e, cs, ce, cd
      s, e, cs, ce, cd = find_patterns(patterns, line, s + 1)
      if not s then
        break
      end
      local rs, re = s, e
      local ore = re
      if domain == 'inner' then
        if type(cs) == 'string' then
          rs = rs + cs:len()
        end
        if type(ce) == 'string' then
          re = re - ce:len()
        end
      end
      if type(cd) == 'string' then
        re = re - cd:len()
        ore = ore - cd:len()
      end
      if
        row > cursor[1]
        or in_place and (re >= cursor[2] + 1 and cursor[2] + 1 >= rs)
        or rs > cursor[2] + 1
      then
        if count == 1 then
          return row, rs, re
        end
        count = count - 1
      end
      s = ore
    end
  end
end

local function search_backward(patterns, domain, in_place, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  for row, line in
    require('flies.objects.utils').row_backward_iterator(cursor[1])
  do
    local s = 0
    local res = {}
    while true do
      local e, cs, ce, cd
      s, e, cs, ce, cd = find_patterns(patterns, line, s + 1)
      local rs, re = s, e
      local ore = re
      if s then
        if domain == 'inner' then
          if type(cs) == 'string' then
            rs = rs + cs:len()
          end
          if type(ce) == 'string' then
            re = re - ce:len()
          end
        end
        if type(cd) == 'string' then
          re = re - cd:len()
          ore = ore - cd:len()
        end
      end
      if
        s
        and (
          row < cursor[1]
          or in_place and (re >= cursor[2] + 1 and cursor[2] + 1 >= rs)
          or rs < cursor[2] + 1
        )
      then
        table.insert(res, { rs, re })
        s = ore
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
    row, s, e = search_forward(self.patterns, domain, false, vim.v.count1)
  else
    row, s, e = search_backward(self.patterns, domain, false, vim.v.count1)
  end
  local col = start and s or e
  if not row then
    return
  end
  vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

function M:textobject_outer_plain(_)
  local row, s, e = search_forward(self.patterns, 'outer', true, vim.v.count1)
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

function M:textobject_inner_plain(_)
  local row, s, e = search_forward(self.patterns, 'inner', true, vim.v.count1)
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

function M:textobject_outer_np(qualifier, _)
  local row, s, e
  if qualifier == 'next' then
    row, s, e = search_forward(self.patterns, 'outer', false, vim.v.count1)
  else
    row, s, e = search_backward(self.patterns, 'outer', false, vim.v.count1)
  end
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

function M:textobject_inner_np(qualifier, _)
  local row, s, e
  if qualifier == 'next' then
    row, s, e = search_forward(self.patterns, 'inner', false, vim.v.count1)
  else
    row, s, e = search_backward(self.patterns, 'inner', false, vim.v.count1)
  end
  if not row then
    return
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

-- TODO: change move to move char after separator

M.separator = setmetatable({}, { __index = M })

function M.separator.new(char)
  local char_name = char
  if char == '%' then
    char = '%%'
  elseif char == '^' then
    char = '%^'
  end
  char = string.format('[%s]', char)

  return setmetatable({
    patterns = { string.format('(%s).-()(%s)', char, char) },
    move_patterns = {
      string.format('%s', char),
    },
    name = string.format('between %q', char_name),
  }, { __index = M.separator })
end

function M.separator:move(domain, qualifier, start, _)
  local row, s, e
  domain = 'inner'
  if qualifier == 'next' then
    row, s, e = search_forward(self.move_patterns, domain, false, vim.v.count1)
  else
    row, s, e = search_backward(self.move_patterns, domain, false, vim.v.count1)
  end
  local col = start and s or e
  if not row then
    return
  end
  vim.api.nvim_win_set_cursor(0, { row, col - 1 })
end

-- TODO: use vim.regex instead of lua patters

M.word = M.new('()[%w_]+(%s*)', 'word')
M.vimword = M.new({ '%S$', '()%S(%s+)', '()[%w_]+(%s*)' }, 'vimword')
M.bigword = M.new('()%S+(%s*)', 'bigword')

M.variable_segment = M.new {
  '()%u+()$',
  '()%u+()(%s)',
  '()%u+()(%u%S)',
  '()%u?%l+(_?)',
}

function M.variable_segment:textobject_outer_plain(_)
  local row, s, e = search_forward(self.patterns, 'outer', true, vim.v.count1)
  if not row then
    return
  end
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  local c = string.sub(line, s - 1, s - 1)
  local d = string.sub(line, e + 1, e + 1)
  if (c == '_') and (not d or string.find(d, '[%A]')) then
    s = s - 1
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end

function M.variable_segment:textobject_outer_np(qualifier, _)
  local row, s, e
  if qualifier == 'next' then
    row, s, e = search_forward(self.patterns, 'outer', false, vim.v.count1)
  else
    row, s, e = search_backward(self.patterns, 'outer', false, vim.v.count1)
  end
  if not row then
    return
  end
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  local c = string.sub(line, s - 1, s - 1)
  local d = string.sub(line, e + 1, e + 1)
  if (c == '_') and (not d or string.find(d, '[%A]')) then
    s = s - 1
  end
  require('flies.objects.utils').update_selection(0, row, s, row, e, 'charwise')
end
-- TODO: target style argument

return M
