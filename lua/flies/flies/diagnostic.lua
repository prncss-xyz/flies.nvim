---@class Diagnostic: _Fly
---@field severity number?
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
		local raw_diagnostics =
			vim.diagnostic.get(bufnr, { severity = self.severity })
		local diagnostics = vim.tbl_map(function(diagnostic)
			local range = {
				{ diagnostic.lnum + 1, diagnostic.col + 1 },
				{ diagnostic.end_lnum + 1, diagnostic.end_col },
			}
			return { outer = range, inner = range }
		end, raw_diagnostics)
		local iterators = require "flies.utils.iterators"
		bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
		diagnostics = vim.tbl_filter(
			function(match) return lists.relative_pos(pos, match.outer) == axis end,
			diagnostics
		)
		table.sort(diagnostics, lists.sort_axis(axis))
		return iterators.from_list_single(diagnostics)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

function M:post_move(opts)
	vim.defer_fn(function() vim.diagnostic.open_float() end, 0)
end

return M
