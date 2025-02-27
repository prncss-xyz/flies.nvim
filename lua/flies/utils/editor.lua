local M = {}

--- replace vim-style escape characters with internal representation
---@param str string
function M.t(str) return vim.api.nvim_replace_termcodes(str, true, true, true) end

--- feed vim-style espace character sequence
---@param keys string
---@param remap boolean
function M.feedkeys(keys, remap)
	return function() vim.api.nvim_feedkeys(M.t(keys), remap and "m" or "n", true) end
end

-- local tab = vim.api.nvim_buf_get_option(bufnr, "shiftwidth")
--- get current indentation string
function M.get_indent()
	-- TODO:
	return "\t"
end

local conv = {
	tsx = "typescriptreact",
}

---@param bufnr integer
---@param range integer[][]
function M.get_vim_lang(bufnr, range)
	local lang = require("flies.utils.ts").get_ts_lang(bufnr, range)
	if lang then return conv[lang] or lang end
	return vim.api.nvim_buf_get_option(bufnr, "filetype")
end

function M.get_vim_langs(bufnr, range)
	local lang = M.get_vim_lang(bufnr, range)
	if lang then
		local langs = require("flies").config.ts.extends[lang] or { lang }
		local res = { unpack(langs) }
		table.insert(res, "default")
		return res
	end
	return { "default" }
end

function M.get_lang_at_cursor()
	local cursor = require("flies.utils.windows").get_cursor()
	return M.get_vim_lang(0, { cursor, cursor })
end

return M
