local M = {}

--- transforms a list into a single value iterator
--- ie iterates the value, but not the index like ipairs
function M.from_list_single(list)
	local i = 0
	return function()
		i = i + 1
		return list[i]
	end
end

--- transforms an iterator of single values into a list
function M.to_list_single(gen, param, state)
	local list = {}
	local i = 1
	while true do
		state = gen(param, state)
		if state == nil then return list end
		list[i] = state
		i = i + 1
	end
end

--- transforms a list of lists into a multiple value iterator
function M.from_list_many(list)
	local i = 0
	return function()
		i = i + 1
		if list[i] then return unpack(list[i]) end
	end
end

--- transforms a multiple value iterator into a list of lists
function M.to_list_many(gen, param, state)
	local list = {}
	local i = 1
	while true do
		local values = { gen(param, state) }
		state = values[1]
		if state == nil then return list end
		list[i] = values
		i = i + 1
	end
end

---the null iterator (iterates nothing)
function M.null()
	return function() end
end

---the unit iterator (iterates once the provided values)
function M.unit(...)
	local res = { ... }
	local once = true
	return function()
		if once then
			once = false
			return unpack(res)
		end
	end
end

---iterates (singe value) over a range
---range(a) iterates from 1 to a
---ranbe(a, b) iterates from a to b
---range(a, b, c) iterates from a to b by steps of c
function M.range(a_, b_, c_)
	local b, e, s
	if a_ and b_ and c_ then
		b, e, s = a_, b_, c_
	elseif a_ and b_ then
		b, e, s = a_, b_, 1
	elseif a_ then
		b, e, s = 1, a_, 1
	else
		b, e, s = 1, nil, 1
	end
	return function(_, v)
		v = v + s
		if e then
			if s > 0 then
				if v > e then return end
			else
				if v < e then return end
			end
		end
		return v
	end,
		nil,
		b - s
end

---returns the nth value of an iterator
---if nth is lower than one, return nil
---if nth is fractional, returns the same as nth(Math.floor(i))
function M.nth(i)
	return function(gen, param, state)
		while true do
			if i < 1 then return end
			if i < 2 then return gen(param, state) end
			state = gen(param, state)
			if state == nil then return end
			i = i - 1
		end
	end
end

--- transforms an iterator of iterators into an iterator
function M.flatten(gen1, param1, state1)
	local gen2, param2, state2 = gen1(param1, state1)
	if gen2 == nil then return end
	local function d(k2_, ...)
		state2 = k2_
		if state2 == nil then
			gen2, param2, state2 = gen1(param1, state1)
			if gen2 == nil then return end
			return d(gen2(param2, state2))
		else
			return state2, ...
		end
	end

	return function() return d(gen2(param2, state2)) end
end

return M
