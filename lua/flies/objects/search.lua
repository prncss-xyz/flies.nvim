local M = require('flies.objects.base').new()

local t = require('flies.utils').t

function M.new()
  return setmetatable({}, { __index = M })
end

M.name = 'search'

local search_forward

function M.search(expr, noremap, forward)
  search_forward = forward
  require('flies.move_again').register(function(mode)
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

function M.set_search(fwd)
  search_forward = fwd
  require('flies.move_again').register(function()
    M.n(false, 'n')
  end, function()
    M.n(true, 'n')
  end)
end

function M:textobject_outer_np(qualifier, _)
  if qualifier == 'previous' then
    vim.cmd 'normal! gN'
    return
  end
  if qualifier == 'next' then
    vim.cmd 'normal! gn'
    return
  end
end

function M:textobject_outer_plain(_)
  vim.cmd 'normal! gn'
end

function M:move(_, qualifier, mode)
  if qualifier == 'hint' then
    local pattern = vim.fn.getreg '/'
    require('hop').hint_patterns({}, pattern)
  elseif qualifier == 'previous' then
    M.n(false, mode)
  elseif qualifier == 'next' then
    M.n(true, mode)
  end
end

return M
