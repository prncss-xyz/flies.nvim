local M = {}

local rep = {
  previous = function(_) end,
  next = function(_) end,
}

local function keys(keys)
  return function()
    vim.api.nvim_feedkeys(require('flies.utils').t(keys), 'n', true)
  end
end

function M.recompose(previous, next_)
  if type(previous) == 'string' then
    previous = keys(previous)
  end
  if type(next_) == 'string' then
    next_ = keys(next_)
  end
  local fp = function()
    M.register(previous, next_)
    previous()
  end
  local fn = function()
    M.register(previous, next_)
    next_()
  end
  return fp, fn
end

function M.register(previous, next_)
  rep.previous = previous
  rep.next = next_
end

function M.previous()
  if rep.previous then
    rep.previous()
  end
end

function M.next()
  if rep.next then
    rep.next()
  end
end

return M
