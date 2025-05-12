---@class OpenClose: _IOperation
local M = require("flies.ioperations._ioperation"):new {}

---@param match table
local function filter(match)
	if match.protect then return nil end
	return match
end

M.target = require("flies.flies._ts"):new {
	names = { "open_close" },
	map = filter,
}

---@param match_ table
function M:op_func(match_)
	local buffers = require "flies.utils.buffers"
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
