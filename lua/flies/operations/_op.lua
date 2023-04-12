local M = require("flies.utils.objects"):new {}

local buffers = require "flies.utils.buffers"
local query = require "flies.utils.query"
local selection = require "flies.flies.selection"

function M:get_config(name, char, target)
	local config = require("flies").config
	local c = config.op[name] or {}
	local d = c.chars and c.chars[char] or {}
	local e = target and target.op and target.op[name] or {}
	return vim.tbl_extend("force", c, d, e)
end

function M:pre() return true end

local function op(self, mode, pre)
	local params = require("flies")._params
	if not params then return end
	if not params.range then
		local s, e, wiseness = buffers.get_marks(0, mode)
		local range = { s, e }
		params.range = range
		params.wiseness = wiseness
		params.match = params.match or {
			outer = range,
			inner = range,
		}
	end
	params.pre = pre
	self:run(params)
end

function M:normal(opts, override)
	opts = query.query_obj(opts, override)
	if not opts then return end
	local pre = self:pre()
	if not pre then return end
	require("flies")._select = function() opts.target:select(opts) end
	local count = vim.v.count
	if count == 0 then count = nil end
	if opts.op_func then
		buffers.feed_keys(opts.op_func .. ':<c-u>lua require "flies"._select()<cr>')
	else
		require("flies")._op_func = function() op(self, "o", pre) end
		vim.o.operatorfunc = "v:lua.package.loaded.flies._op_func"
		buffers.feed_keys 'g@:<c-u>lua require "flies"._select()<cr>'
	end
end

function M:visual(opts)
	local pre = self:pre()
	if not pre then return end
	local count = vim.v.count
	if count == 0 then count = nil end
	opts = vim.tbl_extend("force", opts or {}, { target = selection })
	buffers.with_x(function()
		require("flies")._params = {
			pos = buffers.get_cursor(),
			target = selection,
		}
		op(self, "x", pre)
	end)
end

return M
