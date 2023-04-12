local M = {}

local default_config = {
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

	vim.keymap.set(
		"n",
		"<plug>(flies-select)",
		":lua require'flies.operations.select'.exec()<cr>"
	)
	vim.keymap.set(
		"o",
		"<plug>(flies-select)",
		":<c-u>lua require'flies.operations.select'.exec()<cr>"
	)
	vim.keymap.set(
		"x",
		"<plug>(flies-select)",
		":lua require'flies.operations.select'.exec()<cr>"
	)
end

return M
