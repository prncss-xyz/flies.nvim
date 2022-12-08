local M = require("flies2.flies.subline"):new {}

function M.validator(i, m, j, m_) return i == j and m == m_ end

local buffers = require "flies2.utils.buffers"
local lists = require "flies2.utils.lists"

local function process_pair_patterns(self)
	local patterns = {}
	for i, pattern in ipairs(self.left_patterns) do
		patterns[i] = pattern
	end
	local offset = #patterns
	for i, pattern in ipairs(self.right_patterns) do
		patterns[i + offset] = pattern
	end
	return patterns
end

local function is_opening(fwd, left_len, i)
	local is_left = i <= left_len
	if fwd then return is_left end
	return not is_left
end

function inner_outer(fwd, line, prev_line, row, s, e)
	local inner, outer
	if fwd then
		if line:sub(e + 1):match "^%s*$" then
			inner = { row + 1, 1 }
		else
			inner = { row, e + 1 }
		end
		outer = { row, s }
	else
		if line:sub(1, s - 1):match "^%s*$" then
			inner = { row - 1, prev_line and prev_line:len() or 0 } -- TODO: define semantics
		else
			inner = { row, s - 1 }
		end
		outer = { row, e }
	end
	return inner, outer
end

local function np_co(self, fwd, bufnr, pos)
	local patterns = process_pair_patterns(self)
	local last = fwd
			and math.min(pos[1] + self.lookahead - 1, buffers.get_eob(bufnr))
		or math.max(pos[1] - self.lookahead + 1, 1)
	local sgn = fwd and 1 or -1
	local _ipairs = fwd and ipairs or lists.ripairs
	local stack = {}
	local stack2 = {}
	local opening
	local prev_line, line
	for row = pos[1], last, sgn do
		prev_line = line
		line = buffers.get_line(bufnr, row)
		local matches = self:get_matches(patterns, line)
		for _, match in _ipairs(matches) do
			local i, s, e, m = unpack(match)
			if lists.cmp({ row, s }, pos) == sgn then
				if is_opening(fwd, #self.left_patterns, i) then
					-- current match is an opening pattern (left)
					if opening then table.insert(stack, opening) end
					if fwd then
						local inner_open
						if line:sub(e + 1):match "^%s*$" then
							inner_open = { row + 1, 1 }
						else
							inner_open = { row, e + 1 }
						end
						opening = {
							i = i,
							m = m,
							outer_open = { row, s },
							inner_open = inner_open,
						}
					else
						local inner_close
						if line:sub(1, s - 1):match "^%s*$" then
							inner_close = { row - 1, 1 }
						else
							inner_close = { row, s - 1 }
						end
						opening = {
							i = i,
							m = m,
							outer_close = { row, s },
							inner_close = inner_close,
						}
					end
				else
					-- current match is a closing pattern (right)
					-- does current match corresponds to opening pattern we are looking for?
					if opening then
						local valid
						if fwd then
							valid = self.validator(opening.i, opening.m, i - #self.left_patterns, m)
						else
							valid = self.validator(opening.m, i, m, opening.i - #self.left_patterns)
						end
						if valid then
							if fwd then
								local inner_close
								if line:sub(1, s - 1):match "^%s*$" then
									assert(prev_line, "TODO") -- TODO: handle not defined case
									inner_close = { row - 1, prev_line:len() }
								else
									inner_close = { row, s - 1 }
								end
								local outer_close = { row, e }
								table.insert(stack2, {
									opening.outer_open,
									opening.inner_open,
									inner_close,
									outer_close,
								})
							else
								local inner_open
								if line:sub(1, s - 1):match "^%s*$" then
									assert(prev_line, "TODO") -- TODO: handle not defined case
									inner_open = { row - 1, prev_line:len() }
								else
									inner_open = { row, s - 1 }
								end
								local outer_open = { row, e }
								table.insert(stack2, {
									opening.outer_open,
									opening.inner_open,
									inner_open,
									outer_open,
								})
							end
							opening = table.remove(stack)

							if not opening then
								for _, res in lists.ripairs(stack2) do
									coroutine.yield(res)
								end
								stack2 = {}
							end
						end
					end
				end
			end
		end
	end
end

function M:iterate_forwards(bufnr, pos)
	return coroutine.wrap(function() np_co(self, true, bufnr, pos) end)
end

local function backwards_co(self, bufnr, pos)
	local patterns = process_pair_patterns(self)
	local last = math.max(pos[1] - self.lookahead + 1, 1)
	local stack = {}
	local stack2 = {}
	local opening
	local prev_line, line
	for row = pos[1], last do
		prev_line = line
		line = buffers.get_line(bufnr, row)
		local matches = self:get_matches(patterns, line)
		for _, match in lists.ripairs(matches) do
			local i, s, e, m = unpack(match)
			if lists.cmp(pos, { row, s }) > 0 then
				if i > #self.left_patterns then
					-- current match is an opening pattern (left)
					if opening then table.insert(stack, opening) end
					local inner_open
					if line:sub(e - 1):match "^%s*$" then
						inner_open = { row - 1, 1 }
					else
						inner_open = { row, e - 1 }
					end
					opening = {
						i = i,
						m = m,
						outer_open = { row, s },
						inner_open = inner_open,
					}
				else
					-- current match is a closing pattern (right)
					-- does current match corresponds to opening pattern we are looking for?
					local valid
					local j = i - #self.left_patterns
					if self.validator then
						valid = self.validator(opening.i, opening.m, j, m)
					else
						valid = opening.i == j and opening.m == m
					end
					if valid then
						local inner_close
						if line:sub(1, s - 1):match "^%s*$" then
							assert(prev_line, "TODO") -- TODO: handle not defined case
							inner_close = { row - 1, prev_line:len() }
						else
							inner_close = { row, s - 1 }
						end
						local outer_close = { row, e }
						table.insert(stack2, {
							opening.outer_open,
							opening.inner_open,
							inner_close,
							outer_close,
						})
						opening = table.remove(stack)

						if not opening then
							for _, res in lists.ripairs(stack2) do
								coroutine.yield(res)
							end
							stack2 = {}
						end
					end
				end
			end
		end
	end
end

function M:iterate_backwards(bufnr, pos)
	return coroutine.wrap(function() backwards_co(self, bufnr, pos) end)
end

return M
