local M = {}

local query = require "flies.utils.query"
local move_again = require "flies.operations.move_again"

local function move(opts) opts.target:move(opts) end

function M.exec(opts, override)
	opts = query.query_obj(opts, override)
	if not opts then return end
  opts.incl = true
	local n_opts = vim.tbl_extend("force", opts, { axis = "forward" })
	local p_opts = vim.tbl_extend("force", opts, { axis = "backward" })
	move_again.register(function() move(p_opts) end, function() move(n_opts) end)
	move(opts)
end

return M
