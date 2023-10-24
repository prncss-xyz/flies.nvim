---@class Hunk: _Fly
local M = require("flies.flies._fly"):new {}

M.solid = true
M.nested = false
M.lonely_wiseness_inner = "V"
M.lonely_wiseness_outer = "V"

local buffers = require "flies.utils.buffers"

local function get_hunk_match(bufnr, hunk)
	local srow = hunk.added.start
	local erow = srow + hunk.added.count - 1
	local ecol = math.max(1, buffers.get_line(bufnr, erow):len())
	local range = { { srow, 1 }, { erow, ecol } }
	return { outer = range, inner = range }
end

local function get_filter_hunks(fwd, incl, pos)
	return function(match)
		local axis = require("flies.utils.lists").relative_pos(pos, match.outer)
		if incl and axis == "upward" then return true end
		if fwd and axis == "forward" then return true end
		if not fwd and axis == "backward" then return true end
		return false
	end
end

local function iter(bufnr, fwd, incl, pos)
  -- TODO: nice error message if no gitsigns
	local iterators = require "flies.utils.iterators"
	bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
	local hunks = require("gitsigns.actions").get_hunks(bufnr) or {}
	local map_hunks = function(_, hunk) return get_hunk_match(bufnr, hunk) end
	local filter_hunks = get_filter_hunks(fwd, incl, pos)
	-- FIX: are hunks always sorted by asc row?
	-- --REFACT: whould better use takeWhile than filter1G
	return iterators.filter(filter_hunks)(
		iterators.map(map_hunks)(require("flies.utils.lists").bipairs(fwd, hunks))
	)
end

function M:iterate_upwards(bufnr, pos) return iter(bufnr, true, true, pos) end

function M:iterate_forwards(bufnr, pos) return iter(bufnr, true, false, pos) end

function M:iterate_backwards(bufnr, pos) return iter(bufnr, false, false, pos) end

return M
