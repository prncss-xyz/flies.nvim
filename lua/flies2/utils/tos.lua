local M = {}

local buffers = require "flies2.utils.buffers"
local tables = require "flies2.utils.tables"
local config = require("flies2").config

--TODO: left, right

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
	cb(range, wiseness)
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

function M.t(str) return vim.api.nvim_replace_termcodes(str, true, true, true) end

local defaults = {
	domain = "inner",
	around = "solid",
	axis = "best",
}

-- TODO: multiple char keys
local function query_object(cb, user_opts, override)
	local opts = {}
	override = override or {}
	tables.deep_merge(opts, user_opts or {})
	local count_str = ""
	local cumul = ""
	while true do
		if opts.target then
			opts.count = tonumber(count_str)
			return cb(vim.tbl_extend("keep", opts, defaults))
		end
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == M.t "<esc>" then return end
		cumul = cumul .. char
		if override[cumul] then override[cumul](cb) end
		if char:find "%d" then count_str = count_str .. char end
		if not opts.axis then
			for key, axis in pairs(config.axis) do
				if char == M.t(key) then opts.axis = axis end
			end
		end
		if not opts.domain then
			for key, domain in pairs(config.domains) do
				if char == M.t(key) then opts.domain = domain end
			end
		end
		for key, target in pairs(config.queries) do
			if char == M.t(key) then opts.target = target end
		end
	end
end

function M.exec(opts, cb, override)
	query_object(function(opts_) with_to_(opts_, cb) end, opts, override)
end

return M
