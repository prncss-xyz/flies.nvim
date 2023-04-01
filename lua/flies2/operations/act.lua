local M = require("flies2.operations._op"):new {}

local _keys

function M:run()
	_keys()
end

function M.exec(opts, _, keys)
	if type(keys) == "string" then opts.op_func = keys end
	_keys = keys
	M:normal(opts)
end

return M
