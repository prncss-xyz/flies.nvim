local M = {}

function M:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function M:super(method, ...)
	local __index = getmetatable(self).__index
	return __index[method](self, ...)
end

return M
