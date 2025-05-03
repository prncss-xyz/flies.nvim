local M = {}

local function has_contents(tbl)
	for _ in pairs(tbl) do
		return true
	end
	return false
end

local function try_mapping(conf, char)
	if conf[char] ~= nil then return "success", conf[char] end
	local next = {}
	for k, v in pairs(conf) do
		if k:sub(1, 1) == char then next[k:sub(2)] = v end
	end
	return "pending", next
end

local function find_mapping()
	local chars = require("flies").config.op.wrap.chars
	while has_contents(chars) do
		local char = vim.fn.nr2char(vim.fn.getchar())
		local status, res = try_mapping(chars, char)
		if status == "success" then return res end
		chars = res
	end
	return nil
end

function M.exec()
	local res = find_mapping()
	if res == nil then return end
	local snip = res.snip.all
	if snip then
		local luasnip = require "luasnip"
		luasnip.snip_expand(luasnip.snippet("", snip))
	end
end

return M
