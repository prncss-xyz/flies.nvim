local buffers = require "flies2.utils.buffers"

local M = require("flies2.operations._one_shot_subline"):new {
	{
		"^#+ .*$",
		function(match)
			local str = ""
			for _ = 1, match.count or 1 do
				str = str .. "#"
			end
			local row = match.outer[1][1]
			buffers.edit(0, { { { { row, 1 }, { row, 0 } }, str } })
		end,
		ft = "markdown", -- TODO: markdown only
	},
	{
		"(%d+)",
		function(match)
			buffers.edit(
				0,
				{ { match.outer, tostring(tonumber(match.capture) + (match.count or 1)) } }
			)
		end,
	},
	{
		"%f[%w]true%f[%W]",
		function(match) buffers.edit(0, { { match.outer, "false" } }) end,
	},
	{
		"%f[%w]false%f[%W]",
		function(match) buffers.edit(0, { { match.outer, "true" } }) end,
	},
}

return M
