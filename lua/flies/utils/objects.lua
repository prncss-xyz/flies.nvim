local M = {}

---creates a new object, optionaly using provided table
function M:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

---calls method from object's prototype
function M:super(method, ...)
	local meta = self
	meta = getmetatable(meta).__index
	if rawget(self, method) == nil then meta = getmetatable(meta).__index end
	return meta[method](self, ...)
end

function M:super_new(...)
	local meta = self
	meta = getmetatable(meta).__index
	return meta.new(meta, ...)
end

function M:is_instance(o)
	while self do
		if self == o then return true end
		self = getmetatable(self).__index
	end
	return false
end

return M
