local M = {}

local ts_utils = require "nvim-treesitter.ts_utils"
local parsers = require "nvim-treesitter.parsers"
local buffers = require "flies.utils.buffers"

--- Get a compatible vim range (1 index based) from a TS node range.
--
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
--- get vim range from ts node
---@param bufnr integer
---@param node unknown
---@return integer[], integer[]
local function get_node_range(bufnr, node)
	local srow, scol, erow, ecol = node:range()
	local s = buffers.next(bufnr, { srow + 1, scol }, "v")
	local e = buffers.prev(bufnr, { erow + 1, ecol + 1 }, "v")
	return s, e
end

--- converts vim range to ts range
---@param bufnr integer
---@param range integer[][]
---@return integer, integer, integer, integer
local function get_range_node(bufnr, range)
	-- local srow, scol = unpack(range[1])
	-- local erow, ecol = unpack(range[2])
	local srow, scol = unpack(buffers.prev(bufnr, range[1], "v"))
	srow = srow - 1
	local erow, ecol = unpack(buffers.next(bufnr, range[2], "v"))
	erow = erow - 1
	ecol = ecol - 1
	return srow, scol, erow, ecol
end

--- get named ts-node enclosing vim-range
---@param bufnr integer
---@param range integer[][]
local function get_node_at_range(bufnr, range)
	local srow, scol, erow, ecol = get_range_node(bufnr, range)

	local root_lang_tree = parsers.get_parser(bufnr)
	if not root_lang_tree then return end

	local root
	root = ts_utils.get_root_for_position(srow, scol, root_lang_tree)

	if not root then return end

	return root:named_descendant_for_range(srow, scol, erow, ecol)
end

---@param bufnr integer
---@param range integer[][]
local function get_node_inside(bufnr, range)
	local node = get_node_at_range(bufnr, range)
	if not node then return end
	local count = node:child_count()
	if count > 2 then
		local s, _ = get_node_range(bufnr, node:child(1))
		local _, e = get_node_range(bufnr, node:child(count - 2))
		return { s, e }
	end
	return { get_node_range(bufnr, node) }
end

---@param bufnr integer
---@param range integer[][]
local function get_node_second(bufnr, range)
	local node = get_node_at_range(bufnr, range)
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
	return { get_node_range(bufnr, node) }
end

--- process nodes range according to modifiers
local function spice_match(bufnr, match)
	local res = {}
	for k, v in pairs(match) do
		local name, mod = unpack(vim.split(k, ".", { plain = true }))
		if mod == "node_inside" then
			res[name] = get_node_inside(bufnr, v)
		elseif mod == "node_second" then
			res[name] = get_node_second(bufnr, v)
		elseif mod == "start" then
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
			res[k] = v
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

local function extend_query(name, query_by_lang)
	for lang, query in query_by_lang do
		-- TODO:
	end
end

---return all matches from registered queries under name from specified buffer; returns nil if treesitter not supported on buffer
---@param bufnr number
---@param names table|string
function M.query_from_name(bufnr, names)
	if type(names) == "string" then names = { names } end
	local parser = parsers.get_parser(bufnr)
	if not parser then return end
	local matches = {}
	parser:for_each_tree(function(tree, lang_tree)
		local lang = lang_tree:lang()
		for _, name in ipairs(names) do
			local cquery = query_from_name(lang, name)
			for pattern, ts_match, metadata in cquery:iter_matches(tree:root(), bufnr) do
				local match = { pattern = pattern, metadata = metadata }
				for id, node in pairs(ts_match) do
					local capture_name = cquery.captures[id]
					match[capture_name] = { get_node_range(bufnr, node) }
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
		if lang ~= "comment" and contains(child, range) then
			return contains(child, range)
		end
	end
	return tree
end

---@param bufnr integer
---@param range integer[][]
function M.get_ts_lang(bufnr, range)
	local tree = parsers.get_parser(bufnr)
	if not tree then return end
	tree = contains(tree, get_range_node(bufnr, range))
	return tree:lang()
end

local conv = {
	tsx = "typescriptreact",
}

---@param bufnr integer
---@param range integer[][]
function M.get_vim_lang(bufnr, range)
	local lang = M.get_ts_lang(bufnr, range)
	if lang then return conv[lang] or lang end
	return vim.api.nvim_buf_get_option(bufnr, "filetype")
end

return M
