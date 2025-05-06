---@class CharTo2: _Fly
local M = require("flies.flies._subline"):new {}

M.name = "CharTo2"
M.around_char_pattern = false

---type string?
local pattern

local function match(self, line, init) return line:find(pattern, init) end

M.patterns = { match }

local function reducer(acc, char)
	if char == "\r" then return "success", acc end
	acc = acc .. char
	if acc:len() == 2 then return "success", acc end
	return "pending", acc
end

function M:ask(cb)
	local res = require("flies.utils.asker").process("", reducer)
	if res then
		pattern = require("flies.utils").pattern_escape(res, true)
		return cb()
	end
end

return M
