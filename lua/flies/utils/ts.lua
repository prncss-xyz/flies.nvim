local M = {}
-- https://neovim.io/doc/user/treesitter.html#_vim.treesitter

local buffers = require "flies.utils.buffers"

local function get_parser(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then return nil end
	return parser
end

local function range_to_node(range)
	local s, e = unpack(range)
	local srow, scol = s[1] - 1, s[2] - 1
	local erow, ecol = e[1] - 1, e[2]
	return srow, scol, erow, ecol
end

--- Get a compatible vim range (1 index based) from a TS node range.
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
--- get vim range from ts node
local function node_to_range(node, inside)
	local scol, srow, ecol, erow
	if inside then
		local count = node:child_count()
		scol, srow =
			vim.treesitter.get_node_range(count >= 1 and node:child(1) or node)
		_, _, ecol, erow =
			vim.treesitter.get_node_range(count >= 2 and node:child(count - 2) or node)
	else
		scol, srow, ecol, erow = vim.treesitter.get_node_range(node)
	end
	return { { scol + 1, srow + 1 }, { ecol + 1, erow } }
end

--- process nodes range according to modifiers
local function spice_match(bufnr, match)
	local res = {}
	for k, v in pairs(match) do
		-- inside
		local name, mod = unpack(vim.split(k, ".", { plain = true }))
		if mod == "start" then
			local r = res[name] or {}
			r[1] = v[1]
			res[name] = r
		elseif mod == "end" then
			local r = res[name] or {}
			r[2] = v[2]
			res[name] = r
		elseif mod == "before" then
			local r = res[name] or {}
			r[1] = buffers.next(bufnr, v[2], "v")
			res[name] = r
		elseif mod == "after" then
			local r = res[name] or {}
			r[2] = v[1]
			r[2] = buffers.prev(bufnr, v[1], "v")
			res[name] = r
		else
			res[name] = v
		end
	end

	res.inner = res.inner or res.outer
	return res
end

---@param lang string
---@param name string
local function query_from_name(lang, name)
	local config = require("flies").config
	local queries = config.ts.queries or {}
	local langs = config.ts.extends[lang] or { lang }
	local query_str = ""
	for _, lang_ in ipairs(langs) do
		local m = queries[lang_]
		if m then
			local query_str_ = m[name] or ""
			query_str = query_str .. query_str_
		end
	end
	return vim.treesitter.query.parse(lang, query_str)
end

---return all matches from registered queries under name from specified buffer; returns nil if treesitter not supported on buffer
---@param bufnr number
---@param names table|string
function M.query_from_name(bufnr, names)
	if type(names) == "string" then names = { names } end
	local parser = get_parser(bufnr)
	if not parser then return end
	local matches = {}
	parser:for_each_tree(function(tree, lang_tree)
		local lang = lang_tree:lang()
		for _, name in ipairs(names) do
			local cquery = query_from_name(lang, name)
			for pattern, ts_match, metadata in cquery:iter_matches(tree:root(), bufnr) do
				local match = { pattern = pattern, metadata = metadata }
				for id, nodes in pairs(ts_match) do
					local capture_name = cquery.captures[id]
					for _, node in ipairs(nodes) do
						match[capture_name] =
							node_to_range(node, vim.endswith(capture_name, ".inside"))
					end
				end
				table.insert(matches, spice_match(bufnr, match))
			end
		end
	end)
	return matches
end

-- https://github.com/numToStr/Comment.nvim/blob/0236521ea582747b58869cb72f70ccfa967d2e89/lua/Comment/ft.lua
local function contains(tree, range)
	for lang, child in pairs(tree:children()) do
		if lang ~= "comment" and child:contains(range) then
			return contains(child, range)
		end
	end
	return tree
end

---@param bufnr integer
---@param range integer[][]
function M.get_ts_lang(bufnr, range)
	local tree = get_parser(bufnr)
	if not tree then return end
	tree = contains(tree, { range_to_node(range) })
	return tree:lang()
end

return M
