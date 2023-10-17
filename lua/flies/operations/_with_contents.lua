---@class _WithContents: _Operator
local M = require("flies.operations._operator"):new {}

function M:run(params)
	local buffers = require "flies.utils.buffers"
	local cb = params.opts.cb
	local contents = buffers.get_contents(0, params.range)
	-- cb(contents)
	require("flies.utils.ts").get_ts_lang(0, params.range)
end

return M
