local M = {}

local buffers = require "flies2.utils.buffers"
local tos = require "flies2.utils.tos"
local move_again = require "flies2.operations.move_again"

function M.exec()
	local opts, mv = tos.prepare(
		{},
		function(match) buffers.move(match.range, true) end
	)
	if not mv then return end
	local n_opts = vim.tbl_extend("force", opts, { axis = "forward" })
	local p_opts = vim.tbl_extend("force", opts, { axis = "backward" })
	move_again.register(function() mv(p_opts) end, function() mv(n_opts) end)
	mv(opts)
end

return M
