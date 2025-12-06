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
	local editor = require "flies.utils.editor"
	local buffers = require "flies.utils.buffers"
	local windows = require "flies.utils.windows"
	local res = require("flies.utils.asker").process(
		require("flies").config.op.wrap.chars,
		reducer
	)
	if not res then return end
	local snip = editor.get_lang_snip(res)
	if snip then
    buffers.snip_replace(snip)
		return
	end
	if res.left or res.right then
		local left, right = res.left or "", res.right or ""
		local cursor = windows.get_cursor()
		local range = { cursor, { cursor[1], cursor[2] - 1 } }
		local wiseness = "v"
		local outer, inner = range, range
		buffers.subs(0, outer, inner, wiseness, left, right, editor.get_indent())
		windows.set_cursor { cursor[1], cursor[2] + #left }
		return
	end
end

return M
