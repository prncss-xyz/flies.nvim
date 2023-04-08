local M = require("flies.flies._char_to"):new {}

M.patterns = { "." }

local function query()
	local esc = require("flies.utils.editor").t "<esc>"
	local res = ""
	while true do
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == esc then return end
		res = res .. char
		if char == "\n" or res:len() == 2 then return res end
	end
end

function M:hop_targets_generator(pos, opts)
	local chars = query()
	if not chars then return end
	local pattern = require("flies.utils").pattern_escape(chars, true)
	local fly = self:super_new { patterns = { pattern } }
	return fly:hop_targets_generator(pos, opts)
end

return M
