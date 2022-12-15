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
	local __index = getmetatable(self).__index
	return __index[method](self, ...)
end

function M:is_instance(o)
	while o do
		if o == self then return true end
		o = getmetatable(self).__index
	end
	return false
end

return M
