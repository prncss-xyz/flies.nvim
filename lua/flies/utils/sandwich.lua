local M = {}

local buffers = require "flies.utils.buffers"
local config = require("flies").config
local editor = require "flies.utils.editor"

function M.sandwich(self, params, add, substitute)
	local match = params.match
	local range = substitute and match.outer or params.range
	local left, right

	if add then
		local char = params.pre
		local c = self:get_config("wrap", char, params.target)
		if c.snip then
			local lang = vim.api.nvim_buf_get_option(0, "filetype") -- FIXME: detect language with treesitter
			local langs = config.ts.extends[lang] or { lang }
			local snip
			for _, lang_ in ipairs(langs) do
				snip = snip or c.snip[lang_]
			end
			snip = snip or c.snip["default"]
			if not snip then return end
			local contents =
				buffers.get_contents(0, substitute and match.inner or params.range)
			buffers.snip_replace(snip, range, {
				contents = contents,
			})
			return
		end
		if c.left then
			left = c.left
			right = c.right
		elseif char:match "%p" then
			left = char
			right = char
		else
			return
		end
	else
		left, right = "", ""
	end

	local outer, inner, wiseness
	if add and not substitute then
		wiseness = params.wiseness
		outer, inner = range, range
	else
		outer, inner = match.outer, match.inner
		wiseness = params.target:get_wiseness(0, match, "outer")
	end
	buffers.subs(0, outer, inner, wiseness, left, right, editor.indent())
end

return M
