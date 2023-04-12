local M = {}

---lexicoraphical comparaison between tuples
---@param t1 table
---@param t2 table
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

function M.is_inside(range, pos)
	if M.cmp(pos, range[1]) < 0 then return false end
	if M.cmp(range[2], pos) < 0 then return false end
	return true
end

--- axis of a range relative to position
---@param pos table reference (cursor) positon
---@param to table textobject; will consiter .outer range
function M.relative_pos(pos, to)
	if M.cmp(to[2], pos) < 0 then return "backward" end
	if M.cmp(pos, to[1]) < 0 then return "forward" end
	return "upward"
end

local function cmp0(a, b)
	if a == b then return 0, 0 end
	if a < b then return b - a, -1 end
	return a - b, 1
end

local function dist(pos, match)
	local outer = match.outer
	local va, sa = cmp0(pos[1], outer[1][1])
	local vb, sb = cmp0(pos[1], outer[2][1])
	local vc, sc = cmp0(pos[2], outer[1][2])
	local vd, sd = cmp0(pos[2], outer[2][2])
	return { va, vb, vc, vd, sa, sb, sc, sd }
end

function M.get_upwards_sorter(pos)
	return function(a, b) return M.cmp(dist(pos, a), dist(pos, b)) <= 0 end
end

--- returns a sorting function for axis
---@param axis "upward" | "forward" | "backward"
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
	else
		error("unknown axis: " .. axis)
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
---@param fwd boolean
---@param t table list
function M.bipairs(fwd, t)
	if fwd then
		return ipairs(t)
	else
		return M.ripairs(t)
	end
end

return M
