local M = {}

local ts_utils = require "nvim-treesitter.ts_utils"
local parsers = require "nvim-treesitter.parsers"

local domain = "flies"

--- Get a compatible vim range (1 index based) from a TS node range.
--
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
local function get_vim_range(range, buf)
	local srow, scol, erow, ecol = unpack(range)
	srow = srow + 1
	scol = scol + 1
	erow = erow + 1

	if ecol == 0 then
		-- Use the value of the last col of the previous row instead.
		erow = erow - 1
		if not buf or buf == 0 then
			ecol = vim.fn.col { erow, "$" } - 1
		else
			ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
		end
	else
		local lcol
		if not buf or buf == 0 then
			lcol = vim.fn.col { erow, "$" } - 1
		else
			lcol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
		end
		if ecol > lcol then
			ecol = 1
			erow = erow + 1
		end
	end
	return srow, scol, erow, ecol
end

-- parse_query({lang}, {query})
-- Parse {query} as a string. (If the query is in a file, the caller should read the contents into a string before calling).
function M.query(bufnr, query_name)
	local parser = parsers.get_parser(bufnr)
	if not parser then return end
	local matches = {}
	parser:for_each_tree(function(tree, lang_tree)
		local lang = lang_tree:lang()
		local files = vim.treesitter.get_query_files(
			lang,
			table.concat({ domain, query_name }, "-")
		)
		local cquery = vim.treesitter.query.get_query(
			lang,
			table.concat({ domain, query_name }, "-")
		)
		if not cquery then return end
		for pattern, ts_match, metadata in cquery:iter_matches(tree:root(), bufnr) do
			local match = { pattern = pattern, metadata = metadata }
			for id, node in pairs(ts_match) do
				local name = cquery.captures[id]
				local sr, sc, er, ec = get_vim_range({ node:range() }, bufnr)
				match[name] = { { sr, sc }, { er, ec } }
			end
			table.insert(matches, match)
		end
	end)
	return matches
end

return M
