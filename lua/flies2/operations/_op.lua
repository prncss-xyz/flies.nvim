local M = require("flies2.utils.objects"):new {}

local buffers = require "flies2.utils.buffers"
local config = require("flies2").config
local tos = require "flies2.utils.tos"

function M:get_config(name, char, target)
	local c = config.op[name] or {}
	local d = c.chars and c.chars[char] or {}
	local e = target.op and target.op[name] or {}
	return vim.tbl_extend("force", c, d, e)
end

function M:pre() return true end

local params

local function select_(params_)
	params = params_
	buffers.select(params.range, params.wiseness)
end

function M:normal()
	local select = tos.prepare({}, select_, {})
	local pre_ = self:pre()
	if not pre_ then return end
	require("flies2")._select = select
	local count = vim.v.count
	if count == 0 then count = nil end
	params = nil
	require("flies2")._op_func = function()
		if params then
			params.pre = pre_
			self:run(params)
		end
	end
	vim.o.operatorfunc = "v:lua.package.loaded.flies2._op_func"
	buffers.feed_keys 'g@:<c-u>lua require "flies2"._select()<cr>'
end

return M
