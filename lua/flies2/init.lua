local M = {}

local tables = require "flies2.utils.tables"

M.config = {
	lookahead = 200,
	queries = {},
	extends = {
		tsx = { "javascript", "typescript" },
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

function M.setup(user_config) tables.deep_merge(M.config, user_config or {}) end

return M
