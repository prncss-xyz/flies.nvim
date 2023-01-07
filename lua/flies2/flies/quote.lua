local M = require("flies2.flies._subline"):new {}

M.solid = false

local function quote_finder(self, line, init)
	local delims = self.delims
	local restrict = self.restrict or delims
	local s
	local delim
	local esc = false
	for i = init, line:len() do
		local char = string.sub(line, i, i)
		if esc then
			esc = false
		elseif char == "\\" then
			esc = true
		elseif char == delim then
			if restrict:find(char, 1, true) then
				return s, i
			else
				delim = nil
			end
		elseif not delim and delims:find(char, 1, true) then
			s = i
			delim = char
		end
	end
end

M.delims = [["'`]]
M.patterns = { quote_finder }

function M:map(_, _, s, e) return s + 1, e - 1 end

return M
