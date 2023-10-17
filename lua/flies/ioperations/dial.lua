local buffers = require "flies.utils.buffers"

local M = {}

M.ascend, M.descend = require("flies.ioperations._dial").from_rules {
	{
		"^(#+) .*$",
		function(fwd, match)
			local row = match.outer[1][1]
			local count = match.count or 1
			local len = match.capture:len()
			local new_len
			if fwd then
				new_len = math.min(len + count, 6)
			else
				new_len = math.max(len - count, 1)
			end
			local str = ""
			for _ = 1, new_len do
				str = str .. "#"
			end
			buffers.edit(0, { { { { row, 1 }, { row, len } }, str } })
		end,
		ft = "markdown", -- TODO: markdown only
	},
	{
		"(%-?%d+)",
		function(fwd, match)
			local sgn = fwd and 1 or -1
			buffers.edit(0, {
				{
					match.outer,
					tostring(tonumber(match.capture) + sgn * (match.count or 1)),
				},
			})
		end,
	},
	{
		"%f[%w]true%f[%W]",
		function(_, match)
			if (match.count or 1) % 2 == 0 then return end
			buffers.edit(0, { { match.outer, "false" } })
		end,
	},
	{
		"%f[%w]false%f[%W]",
		function(_, match)
			if (match.count or 1) % 2 == 0 then return end
			buffers.edit(0, { { match.outer, "true" } })
		end,
	},
	{
		"%f[%w]True%f[%W]",
		function(_, match)
			if (match.count or 1) % 2 == 0 then return end
			buffers.edit(0, { { match.outer, "False" } })
		end,
	},
	{
		"%f[%w]False%f[%W]",
		function(_, match)
			if (match.count or 1) % 2 == 0 then return end
			buffers.edit(0, { { match.outer, "True" } })
		end,
	},
}

return M
