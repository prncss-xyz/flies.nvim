local M = require("flies2.flies._subline"):new {}

M.solid = true

-- --FIX: 
M.lonely_wiseness = "v"

function pattern(self, line, init)
	if init > 1 then return end
	local len = line:len()
	if len == 0 then len = 1 end
	return 1, len, line
end

function M:map(_, _, _, s, e, capture)
	if capture == "" then return s, e end
	local s_ = capture:find "%S"
	if s_ == nil then return s, e end
	local e_ = e
	while capture:sub(e_, e_):find "%s" do
		e_ = e_ - 1
	end
	return s_, e_
end

M.patterns = { pattern }

return M
