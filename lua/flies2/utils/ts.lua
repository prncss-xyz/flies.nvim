local M = {}

local ts_utils = require "nvim-treesitter.ts_utils"
local parsers = require "nvim-treesitter.parsers"

local domain = "flies"

--- Get a compatible vim range (1 index based) from a TS node range.
--
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
local function get_vim_range(buf, node)
	local srow, scol, erow, ecol = node:range()
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
	return { srow, scol }, { erow, ecol }
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
				match[name] = { get_vim_range(bufnr, node) }
			end
			table.insert(matches, match)
		end
	end)
	return matches
end

-- parse_query({lang}, {query})
-- Parse {query} as a string. (If the query is in a file, the caller should read the contents into a string before calling).
function M.query_from_table(bufnr, queries)
	local parser = parsers.get_parser(bufnr)
	if not parser then return end
	local matches = {}
	parser:for_each_tree(function(tree, lang_tree)
		local lang = lang_tree:lang()
		local query = queries[lang]
		if not query then return end
		local cquery = vim.treesitter.parse_query(lang, query)
		for pattern, ts_match, metadata in cquery:iter_matches(tree:root(), bufnr) do
			local match = { pattern = pattern, metadata = metadata }
			for id, node in pairs(ts_match) do
				local name = cquery.captures[id]
				match[name] = { get_vim_range(bufnr, node) }
			end
			table.insert(matches, match)
		end
	end)
	return matches
end

local q = require "flies2.ts_queries"
local extends = {
	tsx = { "javascript", "typescript" },
}

-- parse_query({lang}, {query})
-- Parse {query} as a string. (If the query is in a file, the caller should read the contents into a string before calling).
-- TODO: fallback language
-- TODO: user queries
function M.query_from_name(bufnr, name)
	local parser = parsers.get_parser(bufnr)
	if not parser then return end
	local matches = {}
	parser:for_each_tree(function(tree, lang_tree)
		local lang = lang_tree:lang()
		local langs = extends[lang] or { lang }
		local query = ""
		for _, lang_ in ipairs(langs) do
			local query_ = q[lang_]
			if query_ then
				local ql = query_[name]
				if ql then
					if query_ then query = query .. ql end
				end
			end
		end
		-- TODO: reparse only if needed
		local cquery = vim.treesitter.parse_query(lang, query)
		for pattern, ts_match, metadata in cquery:iter_matches(tree:root(), bufnr) do
			local match = { pattern = pattern, metadata = metadata }
			for id, node in pairs(ts_match) do
				local capture_name = cquery.captures[id]
				match[capture_name] = { get_vim_range(bufnr, node) }
			end
			table.insert(matches, match)
		end
	end)
	return matches
end

local function get_node_at_pos(bufnr, range)
	local srow, scol = unpack(range[1])
	local erow, ecol = unpack(range[2])
	srow = srow - 1
	scol = scol - 1
	erow = erow - 1

	local root_lang_tree = parsers.get_parser(bufnr)
	if not root_lang_tree then return end

	local root
	root = ts_utils.get_root_for_position(srow, scol, root_lang_tree)

	if not root then return end

	return root:named_descendant_for_range(srow, scol, erow, ecol)
end

function M.get_node_inside(bufnr, range)
	local node = get_node_at_pos(bufnr, range)
	if not node then return end
	local count = node:child_count()
	if count > 1 then
		local _, s = get_vim_range(bufnr, node:child(1))
		local e, _ = get_vim_range(bufnr, node:child(count - 2))
		return { s, e }
	end
end

function M.get_node_second(bufnr, range)
	local node = get_node_at_pos(bufnr, range)
	if not node then return end
	local count = node:child_count()
	if count > 1 then
		local child = node:child(1)
		return { get_vim_range(bufnr, child) }
	end
	if count == 1 then
		local e = range[2]
		local s = { e[1], e[2] + 1 }
		return { s, e }
	end
end

function M.test()
	local pos = vim.api.nvim_win_get_cursor(0)
	local res = M.get_inside_node(0, pos)
end

return M
