---@class _IOperation : Object
---@field target _Fly
---@field op_func fun(self: _IOperation, match: Object)
local M = require("flies.utils.objects"):new {}

local buffers = require "flies.utils.buffers"
local windows = require "flies.utils.windows"

local match
local count

function M:select()
	local pos = windows.get_cursor()
	match = self.target:find_best(0, pos, {})
	if not match then return end
	buffers.select(self.target:get_wiseness(0, match, "outer"))
end

function M:exec()
	count = vim.v.count
	if count == 0 then count = nil end
	require("flies")._op_func = function()
		if match then
			match.count = count
			self:op_func(match)
		end
	end
	require("flies")._select = function() self:select() end
	vim.o.operatorfunc = "v:lua.package.loaded.flies._op_func"
	buffers.feed_keys 'g@:<c-u>lua require "flies"._select()<cr>'
end

return M
