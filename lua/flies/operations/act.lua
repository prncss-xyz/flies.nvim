---@class Act: _Operator
local M = require("flies.operations._operator"):new {}

local _keys

function M:run()
	if _keys then vim.defer_fn(_keys, 0) end
end

function M.exec(opts, override, keys)
	if type(keys) == "string" then
		opts.op_func = keys
	else
		_keys = keys
	end
	M:normal(opts, override)
end

return M
