local M = {}

local function first_key(keys) return keys:sub(1, vim.fn.byteidx(keys, 1)) end

local function next_key(keys, key)
	local _, e = keys:find(key, 1, true)
	if e == #keys then return nil end
	local next = keys:sub(e + 1)
	return next:sub(1, vim.fn.byteidx(next, 1))
end

local function lookup_seq_trie(trie, p)
	local seq = {}
	local t = trie
	for _, i in pairs(p) do
		local current_trie = t[i]
		seq[#seq + 1] = current_trie.key
		t = current_trie.trie
	end
	seq[#seq + 1] = t[#t].key
	return seq
end

local function add_trie_key(trie, p, key)
	local t = trie
	for _, i in pairs(p) do
		t = t[i].trie
	end
	t[#t + 1] = { key = key, trie = {} }
	return trie
end

local function maintain_deep_pointer(depth, n, p)
	local q = vim.deepcopy(p)
	for i = #p + 1, depth do
		q[i] = n
	end
	return q
end

local function next_perm(keys, trie, p)
	if #trie == 0 then return { { key = first_key(keys), trie = {} } }, p end

	local current_seq = lookup_seq_trie(trie, p)
	local key = next_key(keys, current_seq[#current_seq])

	if key ~= nil then
		add_trie_key(trie, p, key)
		return trie, p
	end

	local max_depth = #p
	local keys_len = vim.fn.strwidth(keys)

	while #p > 0 do
		local last_index = p[#p]
		if last_index > 1 then
			p[#p] = last_index - 1
			p = maintain_deep_pointer(max_depth, keys_len, p)
			add_trie_key(trie, p, first_key(keys))
			add_trie_key(trie, p, next_key(keys, first_key(keys)))
			return trie, p
		else
			p[#p] = nil
		end
	end

	p = maintain_deep_pointer(max_depth, keys_len, p)
	p[#p + 1] = #trie
	add_trie_key(trie, p, first_key(keys))
	add_trie_key(trie, p, next_key(keys, first_key(keys)))
	return trie, p
end

local function trie_to_perms(trie, perm)
	local p = vim.deepcopy(perm)
	p[#p + 1] = trie.key
	if #trie.trie == 0 then return { p } end
	local perms = {}
	for _, sub_trie in pairs(trie.trie) do
		vim.list_extend(perms, trie_to_perms(sub_trie, p))
	end
	return perms
end

--- generate `n` distinct labels from `keys`, shortest first (trie backtrack filling)
---@param keys string
---@param n integer
---@return string[]
function M.permutations(keys, n)
	local trie = {}
	local p = {}
	for _ = 1, n do
		trie, p = next_perm(keys, trie, p)
	end
	local perms = {}
	for _, sub_trie in pairs(trie) do
		vim.list_extend(perms, trie_to_perms(sub_trie, {}))
	end
	return vim.tbl_map(table.concat, perms)
end

return M
