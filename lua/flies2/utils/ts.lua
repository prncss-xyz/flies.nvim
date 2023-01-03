local M = {}

local ts_utils = require "nvim-treesitter.ts_utils"
local parsers = require "nvim-treesitter.parsers"
local config = require("flies2").config
local buffers = require "flies2.utils.buffers"

--- Get a compatible vim range (1 index based) from a TS node range.
--
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
local function get_node_range(bufnr, node)
	local srow, scol, erow, ecol = node:range()
	local s = buffers.next(bufnr, { srow + 1, scol }, "v")
	local e = buffers.prev(bufnr, { erow + 1, ecol + 1 }, "v")
	return s, e
end

-- TODO: memoize
-- TODO: user-extensible
-- TODO: user-replacible
local function query_from_name(lang, name)
	local langs = config.extends[lang] or { lang }
	local query_str = ""
	for _, lang_ in ipairs(langs) do
		local m = require("flies2.ts_queries")[lang_]
		if m then
			local query_str_ = m[name] or ""
			query_str = query_str .. query_str_
		end
	end

	return vim.treesitter.parse_query(lang, query_str)
end

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
		local cquery = query_from_name(lang, name)
		for pattern, ts_match, metadata in cquery:iter_matches(tree:root(), bufnr) do
			local match = { pattern = pattern, metadata = metadata }
			for id, node in pairs(ts_match) do
				local capture_name = cquery.captures[id]
				match[capture_name] = { get_node_range(bufnr, node) }
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
		local s, _ = get_node_range(bufnr, node:child(1))
		local _, e = get_node_range(bufnr, node:child(count - 2))
		return { s, e }
	end
end

function M.get_node_second(bufnr, range)
	local node = get_node_at_pos(bufnr, range)
	if not node then return end
	local count = node:child_count()
	if count > 1 then
		local child = node:child(1)
		return { get_node_range(bufnr, child) }
	end
	if count == 1 then
		local e = range[2]
		local s = { e[1], e[2] + 1 }
		return { s, e }
	end
end

return M
