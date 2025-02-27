local M = {}

local buffers = require "flies.utils.buffers"
local editor = require "flies.utils.editor"

function M.sandwich(self, params, add, remove)
	local match = params.match
	local range = remove and (match.context or match.outer) or params.range
	local left, right

	if add then
		local char = params.pre
		local fly_config = self:get_config("wrap", char, params.target)
		if fly_config.snip then
			local lang = vim.bo.filetype
			local langs = require("flies").config.ts.extends[lang] or { lang }
			local snip
			for _, lang_ in ipairs(langs) do
				snip = snip or fly_config.snip[lang_]
			end
			snip = snip or fly_config.snip["default"]
			if not snip then return end
			local contents =
				buffers.get_contents(0, remove and match.inner or params.range)
			buffers.snip_replace(snip, range, {
				contents = contents,
			})
			return
		end
		if fly_config.left then
			left = fly_config.left
			right = fly_config.right
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
	if add and not remove then
		wiseness = params.wiseness
		outer, inner = range, range
	else
		inner = match.inner
		outer, wiseness =
			params.target:get_wiseness(0, match, match.context and "context" or "outer")
	end
	buffers.subs(0, outer, inner, wiseness, left, right, editor.get_indent())
end

return M
