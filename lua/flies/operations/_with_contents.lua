---@class _WithContents: _Operator
---@field cb fun(lang: string, contents: string[])
local M = require("flies.operations._operator"):new {}

M.allowed_modes = "nx"
M.indent = "\t"

function M:run(params)
	local lang = require("flies.utils.editor").get_vim_lang(0, params.range)
	local contents = require("flies.utils.buffers").get_contents(0, params.range)
	contents = require("flies.utils").correct_indent(self.indent, contents)
	self.cb(lang, contents)
end

return M
