local M = require('flies.objects.base').new()

local name = require('flies.utils').name

function M.new(previous, next)
  M.previous = previous
  M.next = next
  return setmetatable({}, { __index = M })
end

function M:name()
  return 'search'
end

local t = require('flies.utils').t

local search_forward

function M.search(expr, noremap, forward)
  search_forward = forward
  require('flies').repeat_register(function(mode)
    M.n(false, mode)
  end, function(mode)
    M.n(true, mode)
  end)
  vim.api.nvim_feedkeys(t(expr), noremap and 'n' or 'm', false)
  require('hlslens').start()
end

function M.n(forward, mode)
  if mode == 'o' then
    if forward then
      vim.cmd 'normal! gn'
    else
      vim.cmd 'normal! gN'
    end
    return
  end
  if forward == search_forward then
    vim.fn.feedkeys(vim.v.count1 .. 'n', 'n')
  else
    vim.fn.feedkeys(vim.v.count1 .. 'N', 'n')
  end
  require('hlslens').start()
end

for _, domain in ipairs { 'inner', 'outer' } do
  M[name('move', domain, 'hint')] = function(self, start, mode)
    local pattern = vim.fn.getreg('/')
    require'hop'.hint_patterns({}, pattern)
  end
  for _, qualifier in ipairs { 'plain', 'next', 'previous' } do
    M[name('textobject', domain, qualifier)] = function(_, _)
      if qualifier == 'previous' then
        vim.cmd 'normal! gN'
        return
      end
      if qualifier == 'next' then
        vim.cmd 'normal! gN'
        return
      end
      vim.cmd 'normal! Ngn'
    end
    M[name('init_move', domain, qualifier)] = function(self, start, mode)
      if qualifier == 'previous' then
        self.next()
      else
        self.previous()
      end
      require('hlslens').start()
    end
    M[name('move', domain, qualifier)] = function(self, start, mode)
      if qualifier == 'previous' then
        M.n(false, mode)
      else
        M.n(true, mode)
      end
    end
  end
end

M.asterisk_z = M.new(function()
  vim.fn.feedkeys(t '<plug>(asterisk-z*)')
end, function()
  vim.fn.feedkeys(t '<plug>(asterisk-gz*)')
  require('hlslens').start()
end)

return M
