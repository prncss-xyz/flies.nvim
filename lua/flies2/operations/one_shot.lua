local M = require("flies2.utils.objects"):new {}

local buffers = require "flies2.utils.buffers"

M.target = require("flies2.flies.ts"):new {
	name = "open_close",
}

function M.target:map(match)
	if match.protect then return nil end
	return match
end

-- TODO: prioritise low-ranking pattern
function M:exec()
	local pos = buffers.get_cursor(0)
	local match = self.target:find_best(0, pos)
	print(" match:", vim.inspect(match)) -- __AUTO_GENERATED_PRINT_VAR__
	if match then
		if match.tag_open then
			local row, col = unpack(match.outer[2])
			local tag_name = buffers.get_range(0, match.tag_open)
			buffers.edit(0, {
				{
					{ { row, col - 1 }, { row, col - 1 } },
					string.format("></%s", tag_name),
				},
			})
		elseif match.tag_close then
			local row, col = unpack(match.outer[2])
			local s = match.element[2][2]
			buffers.edit(0, { { { { row, s }, { row, col - 1 } }, "/" } })
		elseif match.arrow_open then
			-- buffers.surround(0, match.arrow_open, "{\n  return ", ";\n}")
			buffers.substitute(
				0,
				match.arrow_open,
				match.arrow_open,
				"{\n  return ",
				";\n}"
			)
		elseif match.arrow_close then
			buffers.substitute(0, match.arrow_close, match.outer, "", "")
		end
	end
end

return M
