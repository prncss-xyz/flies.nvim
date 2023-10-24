---@class Inspect: _Operator
local M = require("flies.operations._operator"):new {}

M.allowed_modes = "n"

function M:run(params)
	print(require("flies.utils.ts").get_ts_lang(0, params.range))
	print(vim.inspect(params.match))
end

return M
