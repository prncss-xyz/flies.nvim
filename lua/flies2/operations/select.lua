local M = {}

local buffers = require "flies2.utils.buffers"
local tos = require "flies2.utils.tos"

function M.exec()
	tos.exec(
		{},
		function(params) buffers.select(params.range, params.wiseness) end
	)
end

return M
