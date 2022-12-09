local M = require("flies2.flies.subline"):new {}

function M.validator(i, m, j, m_) return i == j and m == m_ end

local buffers = require "flies2.utils.buffers"
local lists = require "flies2.utils.lists"
local iterators = require "flies2.utils.iterators"

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

local function get_half_range(fwd, opening, row, line, s, e)
	local inner, outer, find_last
	if fwd == opening then
		outer = { row, s }
		if line:sub(e + 1):match "^%s*$" then
			inner = { row + 1, 1 }
		else
			inner = { row, e + 1 }
		end
	else
		outer = { row, e }
		if line:sub(1, s - 1):match "^%s*$" then
			find_last = true
		else
			inner = { row, s - 1 }
		end
	end
	return inner, outer, find_last
end

-- TODO: extend scope of `if lat then`
-- TODO: reduce ifs nesting
-- TODO: comment the algorythm
-- TODO: add tests for uneven matching
local function np_co(self, patterns, bufnr, fwd, pos, up, lat)
	local sgn = fwd and 1 or -1
	local finding = {}
	local found = {}
	local opening
	local prev_line, prev_line_
	local last_char_close
	for row, line in buffers.get_lines(bufnr, fwd, pos[1], self.lookahead) do
		prev_line = prev_line_
		prev_line_ = line
		if last_char_close then
			last_char_close = false
			opening.inner = { row, line:len() }
		end
		local matches = self:get_matches(patterns, line)
		for _, match in lists.bipairs(fwd, matches) do
			local i, s, e, m = unpack(match)
			if lists.cmp({ row, s }, pos) ~= -sgn then
				if is_opening(fwd, #self.left_patterns, i) then
					if lists.cmp({ row, s }, pos) == sgn then
						-- current match is an opening pattern (left)
						if opening then table.insert(finding, opening) end
						local inner, outer
						inner, outer, last_char_close = get_half_range(fwd, true, row, line, s, e)
						opening = {
							i = i,
							m = m,
							inner = inner,
							outer = outer,
						}
					end
					-- current match is a closing pattern (right)
					-- does current match corresponds to opening pattern we are looking for?
				elseif opening then
					if lists.cmp({ row, s }, pos) == sgn then
						local valid
						if fwd then
							valid = self.validator(opening.i, opening.m, i - #self.left_patterns, m)
						else
							valid = self.validator(i, m, opening.i - #self.left_patterns, opening.m)
						end
						if valid then
							local inner, outer, last_char_open =
								get_half_range(fwd, false, row, line, s, e)
							if last_char_open then inner = { row - 1, prev_line:len() } end
							assert(not last_char_close, "faulty logic")
							if fwd then
								table.insert(found, {
									opening.outer,
									opening.inner,
									inner,
									outer,
								})
							else
								table.insert(found, {
									outer,
									inner,
									opening.inner,
									opening.outer,
								})
							end
							opening = table.remove(finding)
							if not opening then
								if lat then
									for _, res in lists.ripairs(found) do
										coroutine.yield(res)
									end
								end
								found = {}
							end
						end
					end
				elseif up then
					-- return match if upward
					local inner, outer, last_char_close_ =
						get_half_range(fwd, false, row, line, s, e)
					if last_char_close_ then inner = { row - 1, prev_line:len() } end
					coroutine.yield {
						i = i,
						m = m,
						inner = inner,
						outer = outer,
					}
				end
			end
		end
	end
end

function M:_np_iter(bufnr, patterns, fwd, pos, up, lat)
	return coroutine.wrap(
		function() np_co(self, patterns, bufnr, fwd, pos, up, lat) end
	)
end

function M:iterate_upwards(bufnr, pos)
	local patterns = process_pair_patterns(self)
	return iterators.zip_match(function(right, left)
		if self.validator(left.i, left.m, right.i - #self.left_patterns, right.m) then
			return { left.outer, left.inner, right.inner, right.outer }
		end
	end, self:_np_iter(bufnr, patterns, true, pos, true, false))(
		self:_np_iter(bufnr, patterns, false, pos, true, false)
	)
end

function M:iterate_forwards(bufnr, pos)
	local patterns = process_pair_patterns(self)
	return self:_np_iter(bufnr, patterns, true, pos, false, true)
end

function M:iterate_backwards(bufnr, pos)
	local patterns = process_pair_patterns(self)
	return self:_np_iter(bufnr, patterns, false, pos, false, true)
end

return M
