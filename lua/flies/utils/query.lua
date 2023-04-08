local M = {}

local tables = require "flies.utils.tables"
local editor = require "flies.utils.editor"
local config = require("flies").config

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
  local default_domain = opts_.domain
	local count_str = ""
	local cumul = ""
	while true do
		if opts_.target then
			opts_.count = tonumber(count_str)
			opts_ = vim.tbl_extend("keep", opts_, defaults)
			if opts_.domain == "toggle" then
        print(vim.inspect(defaults))
				opts_.domain = default_domain == "inner" and "outer" or "inner"
			end
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
		if char:match "%d" then count_str = count_str .. char end
		if char:match "%p" then
			opts_.target = require("flies.flies._char_to"):new {
				patterns = { require("flies.utils").pattern_escape(char, false) },
			}
		end
	end
end

return M
