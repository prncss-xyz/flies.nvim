local M = require("flies2.operations._op"):new {}

local buffers = require "flies2.utils.buffers"
local editor = require "flies2.utils.editor"
local config = require("flies2").config

function M:pre()
	local char = vim.fn.nr2char(vim.fn.getchar())
	if char == editor.t "<esc>" then return end
	return char
end


function M:run(params)
	local range = params.range
	local left, right
	local char = params.pre
	local c = self:get_config("wrap", char, params.target)

	if c.snip then
		local lang = vim.api.nvim_buf_get_option(0, "filetype")
		local snip
		local langs = config.ts.extends[lang] or { lang }
		for _, lang_ in ipairs(langs) do
			snip = snip or c.snip[lang_]
		end
		snip = snip or c.snip["default"]
		if not snip then return end
		local contents = buffers.get_contents(0, range)
		buffers.snip_replace(snip, range, {
			contents = contents,
		})
		return
	elseif c.left then
		left = c.left
		right = c.right
	elseif char:match "%p" then
		left = char
		right = char
	else
		return
	end
	buffers.subs(0, range, range, params.wiseness, left, right, editor.indent())
end

function M.exec(mode)
	if mode == "n" then
		M:normal()
	elseif mode == "x" then
		M:visual()
	end
end

return M
