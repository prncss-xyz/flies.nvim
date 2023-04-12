local M = {}

local query = require "flies.utils.query"

function M.exec(mode, opts, override)
	opts = vim.tbl_extend("force", {
		around = "never",
	}, opts or {})
	local v_count = vim.v.count
	if v_count > 0 then opts.count = v_count end
	opts = query.query_obj(opts, override, true)
	if not opts then return end
	if mode == "x" then
		if opts.move == "right" then
			opts.axis = "forward"
		elseif opts.move == "left" then
			opts.axis = "backward"
		elseif opts.axis == "best" then
			opts.axis = "forward"
		end
	end
	opts.target:move(opts)
end

return M
