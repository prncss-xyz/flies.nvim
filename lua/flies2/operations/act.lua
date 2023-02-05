local M = require("flies2.operations._op"):new {}

local editor = require "flies2.utils.editor"

local _keys, _remap

function M:run()
	if type(_keys == "string") then
		editor.feedkeys(_keys, _remap)
	elseif type(_keys) == "function" then
		_keys()
	end
end

function M.exec(opts, _, keys, remap)
	_keys = keys
	_remap = remap
	M:normal(opts)
end

return M
