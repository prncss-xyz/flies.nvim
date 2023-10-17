---@class Act: _Operator
local M = require("flies.operations._operator"):new {}

local _keys

function M:run()
  vim.defer_fn(_keys, 0)
	-- _keys()
end

function M.exec(opts, override, keys)
	if type(keys) == "string" then opts.op_func = keys end
	_keys = keys
	M:normal(opts, override)
end

return M
