local name = require('flies.utils').name
local function t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local M = require('flies.objects.base').new()

function M.new(keys)
  local o = {}
  for k, v in pairs(keys) do
    o[k] = t(v)
  end
  return setmetatable(o, { __index = M })
end

function M:select_outer(qualifier, mode)
  print('select', qualifier)
  local acc = ''
  if mode == 'x' then
    acc = acc .. t '<esc>'
  end
  if qualifier == 'next' then
    acc = acc .. self.next
  end
  if qualifier == 'previous' then
    acc = acc .. self.previous .. self.previous
  end
  acc = acc .. 'va' .. self.tobj
  vim.fn.feedkeys(acc, 'n')
end

for _, domain in ipairs { 'inner', 'outer' } do
  M[name('move', domain, 'next')] = function(self, _, _)
    vim.fn.feedkeys(self.next, 'n')
  end
  M[name('move', domain, 'previous')] = function(self, _, _)
    vim.fn.feedkeys(self.previous, 'n')
  end
  for _, qualifier in ipairs { 'plain', 'next', 'previous' } do
    M[name('textobject', domain, qualifier)] = function(self, mode)
      local acc = ''
      if mode == 'x' then
        acc = acc .. t '<esc>'
      end
      if qualifier == 'next' then
        acc = acc .. self.next
      end
      if qualifier == 'previous' then
        acc = acc .. self.previous .. self.previous
      end
      acc = acc .. 'v'
      acc = acc .. (domain == 'inner' and 'i' or 'a')
      acc = acc .. self.tobj
      vim.fn.feedkeys(acc, 'n')
    end
  end
end

M.bigword = M.new {
  next = 'W',
  previous = 'B',
  tobj = 'W',
}

M.paragraph = M.new {
  next = '}',
  previous = '{',
  tobj = 'p',
}

M.sentence = M.new {
  next = ')',
  previous = '(',
  tobj = 's',
}

return M
