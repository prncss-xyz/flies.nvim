local M = {}

local windows = require "flies.utils.windows"
local buffers = require "flies.utils.buffers"
local editor = require "flies.utils.editor"

local function get_config()
	local config = require("flies").config
	return config.op.wrap.chars or {}
end

--- find mapping matching the end of line
---@param line string
---@param col integer
local function find_mapping(line, col)
	local post_char = line:sub(col, col)
	if post_char:find "%S" then return nil end
	line = line:sub(1, col - 1)
	for mapping, opts in pairs(get_config()) do
		if vim.endswith(line, mapping) then
			local pre_col = col - 1 - mapping:len()
			if pre_col < 1 then return opts end
			local c = line:sub(pre_col, pre_col)
			if c:find("^%s", pre_col) then return opts end
		end
	end
	return nil
end

local contents = { "" }

local function get_snippet(langs, snip)
	for _, lang in ipairs(langs) do
		local s = snip[lang]
		if s then return s end
	end
end

function M.exec()
	local row, col = unpack(windows.get_cursor())
	local line = buffers.get_line(0, row)
	local opts = find_mapping(line, col)
	if not opts then return false end
	local snip = opts.snip
	if not snip then return false end
	local expand_pos = { row, col - 1 }
	local range = { expand_pos, expand_pos }
  local s = buffers.snip_find(snip, range)
	if not s then return false end
	buffers.snip_replace(s, range, {
		contents = contents,
	})
	return true
end

return M
