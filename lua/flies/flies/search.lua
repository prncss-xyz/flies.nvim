---@class Search: _Fly
local M = require("flies.flies._fly"):new {}

local editor = require "flies.utils.editor"
local move_again = require "flies.actions.move_again"

M.solid = true

function M:select(opts)
	require("flies")._params = {
		opts = opts,
		target = self,
	}
	if opts.axis == "hint" then
		local pattern = vim.fn.getreg("/", nil, nil)
		require("hop").hint_patterns({}, pattern)
		vim.defer_fn(function() vim.cmd "normal! gn" end, 0)
	elseif
		opts.axis == "best"
		or opts.axis == "upward"
		or opts.axis == "forward"
	then
		vim.cmd "normal! gn"
	elseif opts.axis == "backward" then
		vim.cmd "normal! gN"
	end
end

function M:move(opts)
	require("flies")._params = {
		opts = opts,
		target = self,
	}
	if opts.axis == "hint" then
	elseif
		opts.axis == "best"
		or opts.axis == "upward"
		or opts.axis == "forward"
	then
    M.search(true)
	elseif opts.axis == "backward" then
    M.search(false)
	end
end

local search_forward

local function search_n(forward)
	if forward == search_forward then
		vim.cmd "normal! n"
	else
		vim.cmd "normal! N"
	end
	if require("flies").config.hlslens then require("hlslens").start() end
end

function M.set_search(fwd)
	search_forward = fwd
	move_again.register(
		function() search_n(false) end,
		function() search_n(true) end
	)
end

function M.search(fwd)
	M.set_search(fwd)
	vim.api.nvim_feedkeys(editor.t(fwd and "/" or "?"), "n", false)
end

return M
