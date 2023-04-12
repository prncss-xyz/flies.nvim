local M = require("flies.flies._subline"):new {}

M.solid = true

local function check(char)
	if char == "_" then return true end
	if char:match "%p" then return false end
	if char:match "%s" then return false end
	return true
end

local function pattern(_, line, init)
	local s, e
	for i = init, #line do
		if check(line:sub(i, i)) then
			if not s then s = i end
			e = i
		else
			if s then return s, e end
		end
	end
	return s, e
end

function M:get_hints(pos, opts)
	local fly = self:super_new { patterns = { pattern } }
	return fly:get_hints(pos, opts)
end

M.patterns = { pattern }

return M
