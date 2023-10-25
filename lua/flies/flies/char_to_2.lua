---@class CharTo2: _Fly
local M = require("flies.flies._subline"):new {}

M.name = "CharTo2"
M.around_char_pattern = false

---type string?
local pattern

local function match(self, line, init)
	return line:find(pattern, init)
end

M.patterns = { match }

function M:ask(cb)
	local esc = require("flies.utils.editor").t "<esc>"
	local res = ""
	while true do
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == esc then return end
		res = res .. char
		if char == "\r" or res:len() == 2 then
			pattern = require("flies.utils").pattern_escape(res, true)
			return cb()
		end
	end
end

return M
