local M = {}

local default_config = {
	hints = {
		max = 100,
		keys = "asdghklqwertyuiopzxcvbnmfj",
		jump_on_sole_occurrence = true,
	},
	hlslens = false,
	lookahead = 200,
	queries = {},
	ts = {
		extends = {
			tsx = { "typescriptreact", "typescript", "javascriptreact", "javascript" },
			javascript = { "javascriptreact", "javascript" },
			javascriptreact = { "javascriptreact", "javascript" },
			typescript = { "typescript", "javascript" },
		},
		queries = require "flies.ts_queries",
	},
	op = {
		wrap = {
			chars = {
				["("] = { left = "(", right = ")" },
				[")"] = { left = ")", right = "(" },
				["["] = { left = "[", right = "]" },
				["]"] = { left = "]", right = "[" },
				["{"] = { left = "{", right = "}" },
				["}"] = { left = "}", right = "{" },
				["<"] = { left = "<", right = ">" },
				[">"] = { left = ">", right = "<" },
			},
		},
	},
}

M.config = nil

function M.setup(config)
	M.config = vim.tbl_deep_extend("force", default_config, config or {})
	local hint = require "flies.utils.hint"
	hint.set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("FliesHint", {}),
		callback = hint.set_highlights,
	})
end

return M
