local M = {}

local function reducer(conf, char)
	if conf[char] ~= nil then return "success", conf[char] end
	local next = {}
	local contents = false
	for k, v in pairs(conf) do
		if k:sub(1, 1) == char then
			contents = true
			next[k:sub(2)] = v
		end
	end
	if contents then return "pending", next end
	return "failure"
end

function M.exec()
	local res = require("flies.utils.asker").process(
		require("flies").config.op.wrap.chars,
		reducer
	)
	if res == nil then return end
	local snip = res.snip.all
	if snip then
		local luasnip = require "luasnip"
		luasnip.snip_expand(luasnip.snippet("", snip))
	end
end

return M
