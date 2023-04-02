local M = require("flies.flies._subline"):new {}

M.solid = true

M.around_char_pattern = "_+"

local function uul(self, line, init)
	local s, e = line:find("%u+%u%l", init)
	if not s then return end
	return s, e - 2
end

M.patterns = {
	"%w+%f[_]",
	"%f[^_]%w+",
	"%l+%f[%u]",
	"%u%l+$",
	"%u%l+%f[%u]",
	"%f[%u]%u+",
	uul,
}

return M
