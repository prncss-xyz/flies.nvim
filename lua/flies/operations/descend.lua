local buffers = require "flies.utils.buffers"

local M = require("flies.operations._one_shot_subline"):new {
	{
		"^#(#+) .*$",
		function(match)
			local row = match.outer[1][1]
			local n = math.min(match.count or 1, match.capture:len())
			buffers.edit(0, { { { { row, 1 }, { row, n } }, "" } })
		end,
		ft = "markdown", -- TODO: markdown only
	},
	{
		"(-%d+)",
		function(match)
			buffers.edit(
				0,
				{ { match.outer, tostring(tonumber(match.capture) - (match.count or 1)) } }
			)
		end,
	},
	{
		"(%d+)",
		function(match)
			buffers.edit(
				0,
				{ { match.outer, tostring(tonumber(match.capture) - (match.count or 1)) } }
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
