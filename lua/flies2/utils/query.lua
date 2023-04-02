local M = {}

local tables = require "flies2.utils.tables"
local editor = require "flies2.utils.editor"
local config = require("flies2").config

local defaults = {
	domain = "inner",
	around = "solid",
	axis = "best",
}

-- TODO: multiple char keys
function M.query_obj(opts, override)
	local opts_ = {}
	opts = opts or {}
	override = override or {}
	tables.deep_merge(opts_, opts)
	local count_str = ""
	local cumul = ""
	while true do
		if opts_.target then
			opts_.count = tonumber(count_str)
			opts_ = vim.tbl_extend("keep", opts_, defaults)
			return opts_
		end
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == editor.t "<esc>" then return end
		cumul = cumul .. char
		if override[cumul] then
			opts_.count = tonumber(count_str)
			opts_ = vim.tbl_extend("keep", opts_, defaults)
			override[cumul](opts_)
			return
		end
		if char:find "%d" then count_str = count_str .. char end
		if not opts_.axis then
			for key, axis in pairs(config.axis) do
				if char == editor.t(key) then opts_.axis = axis end
			end
		end
		for key, domain in pairs(config.domains) do
			if char == editor.t(key) then opts_.domain = domain end
		end
		for key, target in pairs(config.queries) do
			if char == editor.t(key) then opts_.target = target end
		end
	end
end

return M
