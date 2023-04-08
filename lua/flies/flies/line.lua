local M = require("flies.flies._subline"):new {}
local buffers = require "flies.utils.buffers"

M.solid = true

M.lonely_wiseness_inner = "v"
M.lonely_wiseness_outer = "V"
M.around_line_pattern = false

local function pattern(_, line, init)
	local s = line:find "%S"
	if not s then
		if init > 1 then return end
		if line == "" then return 1, 1 end
		return 1, line:len()
	end
	if init > s then return end
	local e = line:find "%S%s*$"
	return s, e
end

M.patterns = { pattern }

return M
