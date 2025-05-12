---@class Reference: _Fly
local M = require("flies.flies._fly"):new {}

M.around_char_pattern = false
M.around_line_pattern = false

local lists = require "flies.utils.lists"

---@param axis axis
local function iter_axis(axis)
	---@param self Diagnostic
	---@param bufnr integer
	---@param pos integer[][]
	---@param _ integer[][]
	return function(self, bufnr, pos, _)
		if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
		local raw_references =
			require("illuminate.reference").buf_get_references(bufnr)
		local references = vim.tbl_map(function(reference)
			local range = {
				{ reference[1][1] + 1, reference[1][2] + 1 },
				{ reference[2][1] + 1, reference[2][2] + 1 },
			}
			return { outer = range, inner = range }
		end, raw_references)
		local iterators = require "flies.utils.iterators"
		bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
		references = vim.tbl_filter(
			function(match) return lists.relative_pos(pos, match.outer) == axis end,
			references
		)
		table.sort(references, lists.sort_axis(axis))
		return iterators.from_list_single(references)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

return M
