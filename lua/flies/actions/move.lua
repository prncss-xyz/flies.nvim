local M = {}

local ask = require "flies.utils.ask"

function M.move(mode, opts, override)
	opts = vim.tbl_extend("force", {
		around = "never",
	}, opts or {})
	local v_count = vim.v.count
	if v_count > 0 then opts.count = v_count end
	ask.ask(opts, override, true, function(opts)
		if not opts then return end
		local target = opts.target
		if mode == "x" then
			if opts.axis == "best" then opts.axis = "forward" end
			opts.move = "opposite"
		end
		if
			target:is_instance(require "flies.flies._char_to")
			or target:is_instance(require "flies.flies.char_to_any")
		then
			opts.move = "opposite"
		end
		target:register(opts)
		target:move(opts)
	end)
end

return M
