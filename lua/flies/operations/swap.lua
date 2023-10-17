---@class Swap: _Operator
local M = require("flies.operations._operator"):new {}

local buffers = require "flies.utils.buffers"
local editor = require "flies.utils.editor"
local lists = require "flies.utils.lists"

local opts_

function M:run(params)
	local domain = params.opts.domain
	local obj1 = params.target:find_best(0, params.pos, opts_)
	if not obj1 then return end
	local range1 = obj1[domain]
	local range2 = params.range
	if
		-- range1 equals range2
		lists.cmp(range1[1], range2[1]) == 0
		and lists.cmp(range1[2], range2[2]) == 0
	then
		return
	end
	if
		-- range2 inside range1
		lists.cmp(range1[1], range2[1]) <= 0
		and lists.cmp(range2[2], range1[2]) <= 0
	then
		local _, wiseness = params.target:get_wiseness(0, obj1, domain)
		buffers.subs(0, range1, range2, wiseness, "", "", editor.get_indent())
		return
	end
	if
		-- range1 inside range2
		lists.cmp(range2[1], range1[1]) <= 0
		and lists.cmp(range1[2], range2[2]) <= 0
	then
		local _, wiseness = params.target:get_wiseness(0, params.match, domain)
		buffers.subs(0, range2, range1, wiseness, "", "", editor.get_indent())
		return
	end

	buffers.swap(0, range1, range2)
end

function M.exec(mode, opts, override)
	if mode == "n" then
		opts_ =
			vim.tbl_extend("force", { domain = "outer", around = "never" }, opts or {})
		M:normal(opts_, override)
	end
end

M.default_opts = { domain = "outer", around = "never" }

return M
