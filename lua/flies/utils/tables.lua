local M = {}

---recursivly merges an array into another
---updates first array, unlike vim.tbl_deep_extend, which creates a new one
function M.deep_merge(t1, t2)
	local offset = #t1
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k]) == "table") then
			M.deep_merge(t1[k], t2[k])
		elseif type(k) == "number" then
			t1[offset + k] = v
		else
			t1[k] = v
		end
	end
	return t1
end

function M.contains(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k]) == "table") then
			if not M.contains(t1[k], t2[k]) then return false end
		else
			if t1[k] ~= v then return false end
		end
	end
	return true
end

return M
