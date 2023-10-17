---@class VimWord: Word
local M = require("flies.flies.word"):new {}

local patterns = vim.tbl_extend("force", M.patterns, {})
table.insert(patterns, "%p+")

function M:get_hints(pos, opts)
	local fly = require "flies.flies.word"
	return fly:get_hints(pos, opts)
end

M.patterns = patterns

return M
