---@class CharToAny: _Fly
local M = require("flies.flies._subline"):new {}

M.patterns = { "%S" }
M.around_char_pattern = false

local function query()
	local esc = require("flies.utils.editor").t "<esc>"
	local res = ""
	while true do
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == esc then return end
		res = res .. char
		if char == "\r" or res:len() == 2 then return res end
	end
end

function M:get_hints(pos, opts)
	local chars = query()
	if not chars then return end
	local pattern = require("flies.utils").pattern_escape(chars, true)
	---@class _CharToHint: _CharTo
	local fly = require("flies.flies._char_to"):new {
		patterns = { pattern },
		around_char_pattern = false,
	}
	opts.hint_keep_first = true
	fly:register(opts)
	return fly:get_hints(pos, opts)
end

return M
