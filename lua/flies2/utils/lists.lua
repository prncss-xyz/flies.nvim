local M = {}

---lexicoraphical comparaison between tuples
function M.cmp(t1, t2)
	local i = 1
	while true do
		local v1, v2 = t1[i], t2[i]
		if v1 == nil then
			if v2 == nil then return 0 end
			return -1
		end
		if v2 == nil then return 1 end
		if v1 < v2 then return -1 end
		if v1 > v2 then return 1 end
		i = i + 1
	end
end

--- axis of a range relative to position
---@param pos table reference (cursor) positon
---@param to table textobject; will consiter .outer range
---@return string backward\forward\upward
function M.relative_pos(pos, to)
	if M.cmp(to[2], pos) < 0 then return "backward" end
	if M.cmp(pos, to[1]) < 0 then return "forward" end
	return "upward"
end


--- returns a sorting function for axis
---@param axis "upward", "forward", "backward"
function M.sort_axis(axis)
	if axis == "upward" then
		return function(a, b)
			a = a.outer
			b = b.outer
			local r
			r = a[1][1] - b[1][1]
			if r ~= 0 then return r > 0 end
			r = a[1][2] - b[1][2]
			if r ~= 0 then return r > 0 end
			r = a[2][1] - b[2][1]
			if r ~= 0 then return r < 0 end
			r = a[2][2] - b[2][2]
			if r ~= 0 then return r < 0 end
		end
	elseif axis == "forward" then
		return function(a, b)
			a = a.outer
			b = b.outer
			local r
			r = a[1][1] - b[1][1]
			if r ~= 0 then return r < 0 end
			r = a[1][2] - b[1][2]
			if r ~= 0 then return r < 0 end
			r = a[2][1] - b[2][1]
			if r ~= 0 then return r < 0 end
			r = a[2][2] - b[2][2]
			if r ~= 0 then return r < 0 end
		end
	elseif axis == "backward" then
		return function(a, b)
			a = a.outer
			b = b.outer
			local r
			r = a[1][1] - b[1][1]
			if r ~= 0 then return r > 0 end
			r = a[1][2] - b[1][2]
			if r ~= 0 then return r > 0 end
			r = a[2][1] - b[2][1]
			if r ~= 0 then return r > 0 end
			r = a[2][2] - b[2][2]
			if r ~= 0 then return r > 0 end
		end
	end
end

local function ripairs(s, i)
	i = i - 1
	if i > 0 then return i, s[i] end
end

--- reversed ipairs
---@param t table list
function M.ripairs(t) return ripairs, t, #t + 1 end

--- bidirectional ipairs
---@param t table list
function M.bipairs(fwd, t)
	if fwd then
		return ipairs(t)
	else
		return M.ripairs(t)
	end
end

return M
