local M = {}

local buffers = require "flies2.utils.buffers"
local tables = require "flies2.utils.tables"
local editor = require "flies2.utils.editor"
local config = require("flies2").config

local function with_to(opts, target, pos, match, cb)
	local wiseness
	local range
	if opts.domain == "inner" then
		range = match.inner
		wiseness = target:get_wiseness(0, range)
	elseif opts.domain == "left" then
		range = match.inner
		wiseness = target:get_wiseness(0, range)
		range = target:left(0, pos, range, wiseness)
	elseif opts.domain == "right" then
		range = match.inner
		wiseness = target:get_wiseness(0, range)
		range = target:right(0, pos, range, wiseness)
	elseif opts.domain == "outer" then
		range = match.outer
		wiseness = target:get_wiseness(0, range)
		local wants_around
		if opts.around == "always" then
			wants_around = true
		elseif opts.around == "never" then
			wants_around = false
		elseif opts.around == "solid" then
			wants_around = target.solid
		else
			error(string.format("unknown around option: %s", opts.around))
		end
		if wants_around then
			range = match.around or target:around(0, range, wiseness)
		end
	else
		error(string.format("unknown domain: %s", opts.domain))
	end
	cb {
		range = range,
		wiseness = wiseness,
		opts = opts,
		target = target,
		pos = pos,
		match = match,
	}
end

local function with_to_(opts, cb)
	local pos = buffers.get_cursor(0)
	local match
	local target = opts.target
	if opts.axis == "best" then
		match = target:find_best(0, pos)
	elseif opts.axis == "upward" then
		match = target:find_upwards(0, opts.count or 1, pos)
	elseif opts.axis == "forward" then
		match = target:find_forwards(0, opts.count or 1, pos)
	elseif opts.axis == "backward" then
		match = target:find_backwards(0, opts.count or 1, pos)
	elseif opts.axis == "hop" then
		require("hop").hint_with_callback(
			function() return target:hop_targets_generator(opts) end,
			require("hop").opts,
			function(res) with_to(opts, target, pos, res.object, cb) end
		)
	else
		error(string.format("unknown axis: %s", opts.axis))
	end
	if not match then return end
	with_to(opts, target, pos, match, cb)
end

local defaults = {
	domain = "inner",
	around = "solid",
	axis = "best",
}

-- TODO: multiple char keys
function M.prepare(opts, cb, override)
	local opts_ = {}
	override = override or {}
	tables.deep_merge(opts_, opts or {})
	local count_str = ""
	local cumul = ""
	while true do
		if opts_.target then
			opts_.count = tonumber(count_str)
			opts_ = vim.tbl_extend("keep", opts_, defaults)
			return function() with_to_(opts_, cb) end
		end
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == editor.t "<esc>" then return end
		cumul = cumul .. char
		if override[cumul] then
			opts_.count = tonumber(count_str)
			opts_ = vim.tbl_extend("keep", opts_, defaults)
			return function() override[cumul](opts_) end
		end
		if char:find "%d" then count_str = count_str .. char end
		if not opts_.axis then
			for key, axis in pairs(config.axis) do
				if char == editor.t(key) then opts_.axis = axis end
			end
		end
		if not opts_.domain then
			for key, domain in pairs(config.domains) do
				if char == editor.t(key) then opts_.domain = domain end
			end
		end
		for key, target in pairs(config.queries) do
			if char == editor.t(key) then opts_.target = target end
		end
	end
end

function M.exec(opts, cb, override) M.prepare(opts, cb, override)() end

return M
