local M = {}

function M:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:super(method, ...)
  local mt = self
  mt = getmetatable(mt).__index
  mt = getmetatable(mt)
  if not mt then
    return
  end
  mt = mt.__index
  if not mt then
    return
  end
  return mt[method](self, ...)
end

return M
