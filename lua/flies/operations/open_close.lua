local M = require("flies.operations._one_shot"):new {}

local buffers = require "flies.utils.buffers"

M.target = require("flies.flies._ts"):new {
	name = "open_close",
}

function M.target:map(match)
	if match.protect then return nil end
	return match
end

--TODO: use ts

function M:op_func(match_)
	if not match_ then return end
	if match_.tag_open then
		local row, col = unpack(match_.outer[2])
		local tag_name = buffers.get_range(0, match_.tag_open)
		buffers.edit(0, {
			{
				{ { row, col - 1 }, { row, col - 1 } },
				string.format("></%s", tag_name),
			},
		})
	elseif match_.tag_close then
		local row, col = unpack(match_.outer[2])
		local s = match_.element[2][2]
		buffers.edit(0, { { { { row, s }, { row, col - 1 } }, "/" } })
	elseif match_.arrow_open then
		buffers.substitute(
			0,
			match_.arrow_open,
			match_.arrow_open,
			"{\n  return ",
			";\n}"
		)
	elseif match_.arrow_close then
		buffers.substitute(0, match_.arrow_close, match_.outer, "", "")
	end
end

return M
