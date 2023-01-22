local M = {}

local query = require "flies2.utils.query"
local editor = require "flies2.utils.editor"

local function select(opts) opts.target:select(opts) end

function M.exec(opts, override, keys, remap)
	opts = query.query_obj(opts, override)
	if not opts then return end
	if type(keys == "string") then
		editor.feedkeys(keys, remap)
	elseif type(keys) == "function" then
		keys()
	end
	vim.defer_fn(function() select(opts) end, 0)
end

return M
