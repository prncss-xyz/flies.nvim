local M = {}

function M:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:super(method, ...)
  local mt = getmetatable(self).__index
  return mt[method](self, ...)
end

return M
