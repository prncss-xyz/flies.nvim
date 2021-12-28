local move_cursor = require("flies.utils").move_cursor
local name = require("flies.utils").name
local to_pos = require("flies.utils").to_pos
local line_ending_pos = require("flies.utils").line_ending_pos
local select_line_range = require("flies.utils").select_line_range

local M = require("flies.objects.base").new()

-- FIXME: previous object when already on valid object

function M.new(query)
	return setmetatable({ query = query }, { __index = M })
end

local function query_string(query, domain)
	return string.format("@%s.%s", query, domain)
end

for _, domain in ipairs({ "inner", "outer" }) do
	M[name("textobject", domain, "plain")] = function(self, mode)
		require("nvim-treesitter.textobjects.select").select_textobject(query_string(self.query, domain), mode)
	end
	M[name("move", domain, "hint")] = function(self, _, _)
		require("nvim-treesitter.textobjects.select")
		require("hop-extensions").hint_textobjects(string.format("%s.%s", self.query, domain))
		-- TODO: start = false
	end
	for _, qualifier in ipairs({ "next", "previous" }) do
		M[name("move", domain, qualifier)] = function(self, start, _)
			local method = require("nvim-treesitter.textobjects.move")[name(
				"goto",
				qualifier,
				start and "start" or "end"
			)]
			for _ = 1, vim.v.count1 do
				method(query_string(self.query, domain))
			end
		end
	end
	for _, qualifier in ipairs({ "hint", "next", "previous" }) do
		M[name("textobject", domain, qualifier)] = function(self, mode)
			M[name("move", domain, qualifier)](self, true, mode)
			M[name("textobject", domain, "plain")](self, mode)
		end
	end
end

return M
