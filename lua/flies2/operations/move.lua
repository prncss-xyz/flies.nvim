local M = {}

local buffers = require "flies2.utils.buffers"
local tos = require "flies2.utils.tos"

function M.exec()
	tos.exec({}, function(range) buffers.move(range, true) end)
end

return M
