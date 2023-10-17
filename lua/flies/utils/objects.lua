--- universal base class
---@class Object
local M = {}

--- creates a new object, optionaly using provided table
---@param o table?
---@return Object
---@nodiscard
function M:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- calls method from object's prototype
---@param method string
function M:super(method, ...)
	local meta = self
	meta = getmetatable(meta).__index
	if rawget(self, method) == nil then meta = getmetatable(meta).__index end
	return meta[method](self, ...)
end

--- calls constructor from object's prototype
function M:super_new(...)
	local meta = self
	meta = getmetatable(meta).__index
	return meta.new(meta, ...)
end

--- is self an instance of o
---@param o Object
---@return boolean
---@nodiscard
function M:is_instance(o)
	while self do
		if self == o then return true end
		local mt = getmetatable(self)
		if not mt then return false end
		self = mt.__index
	end
	return false
end

return M
