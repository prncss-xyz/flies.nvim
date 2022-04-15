local M = {}

local rep = {
  previous = function(_) end,
  next = function(_) end,
}

function M.recompose(previous, next)
  local fp = function()
    M.repeat_register(previous, next)
    previous()
  end
  local fn = function()
    M.repeat_register(previous, next)
    next()
  end
  return fp, fn
end

function M.register(previous, next)
  rep.previous = previous
  rep.next = next
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
