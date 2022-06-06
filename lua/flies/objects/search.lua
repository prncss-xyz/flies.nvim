local M = {}

local t = require('flies.utils').t

function M:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

M.name = 'search'

local search_forward

function M.search(expr, noremap, forward)
  search_forward = forward
  require('flies.move_again').register(function()
    M.n(false)
  end, function()
    M.n(true)
  end)
  vim.api.nvim_feedkeys(t(expr), noremap and 'n' or 'm', false)
  require('hlslens').start()
end

function M.n(forward)
  if forward == search_forward then
    vim.fn.feedkeys(vim.v.count1 .. 'n', 'n')
  else
    vim.fn.feedkeys(vim.v.count1 .. 'N', 'n')
  end
  require('hlslens').start()
end

function M.set_search(fwd)
  search_forward = fwd
  require('flies.move_again').register(function()
    M.n(false)
  end, function()
    M.n(true)
  end)
end

function M:textobject(_, qualifier, _)
  if qualifier == 'plain' then
    vim.cmd 'normal! gn'
  elseif qualifier == 'previous' then
    vim.cmd 'normal! gN'
    return
  end
  if qualifier == 'next' then
    vim.cmd 'normal! gn'
    return
  end
end

function M:motion(_, qualifier, _)
  if qualifier == 'hint' then
    local pattern = vim.fn.getreg '/'
    require('hop').hint_patterns({}, pattern)
  elseif qualifier == 'previous' then
    M.n(false)
  elseif qualifier == 'next' then
    M.n(true)
  end
end

return M
