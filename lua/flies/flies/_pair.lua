local M = require("flies.flies._subline"):new {}

function M.validator(i, m, j, m_) return i == j and m == m_ end

local buffers = require "flies.utils.buffers"
local lists = require "flies.utils.lists"
local iterators = require "flies.utils.iterators"

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

--- whether ith pattern is opening (ie. left when formards or right when backwards)
local function is_opening(fwd, left_len, i)
	local is_left = i <= left_len
	if fwd then return is_left end
	return not is_left
end

---comment gets the inner and outer coordiates of half of the textobject determinded by token
---@param fwd boolean
---@param opening boolean
---@param row number
---@param line string
---@param s number start column of token
---@param e number end column of token
---@return table inner (start or end) coordinate
---@return table outer (start or end) coordinate
---@return boolean true means outer should be equal to { row - 1, len }, where len is the length of line at row -1
local function get_half_textobject(fwd, opening, row, line, s, e)
	local inner, outer, find_last
	if fwd == opening then
		outer = { row, s }
		-- is it the last non-blank char of the line
		if line:sub(e + 1):match "^%s*$" then
			inner = { row + 1, 1 }
		else
			inner = { row, e + 1 }
		end
	else
		outer = { row, e }
		-- is it the first non-blank char of the line
		if line:sub(1, s - 1):match "^%s*$" then
			find_last = true
		else
			inner = { row, s - 1 }
		end
	end
	return inner, outer, find_last
end

-- sorry for the weird usage of the verb "to find"; just trying to be consistent with function names (i.e. `find()`)

---comment
---@param self table
---@param patterns table processed patterns
---@param bufnr number
---@param fwd boolean wether to search forward
---@param pos table reference position, from where to start search
---@param up boolean wether to yield closing patterns when there is not finding an open pattern, including reference position
---@param lat boolean wether to yield matched pairs, ordered is searching direction, excluding reference position
local function np_co(self, patterns, bufnr, fwd, pos, up, lat)
	local sgn = fwd and 1 or -1
	---an opening pattern that we are currently finding
	local finding
	---stack of finding patterns, excluding the one we are currently finding
	local findings = {}
	---found patterns, waiting to be yield
	--they accumulate in finding order, which is reverse from the search direction
	--when no open pattern is being curretly finding, we can yield them in reverse order
	local found = {}
	local prev_line, prev_line_
	local last_char_close
	for row, line in buffers.get_lines(bufnr, fwd, pos[1], self.lookahead) do
		prev_line = prev_line_
		prev_line_ = line
		if last_char_close then
			last_char_close = false
			finding.inner = { row, line:len() }
		end
		local matches = self:get_matches(patterns, line)
		for _, match in lists.bipairs(fwd, matches) do
			local i, s, e, m = unpack(match)
			if lists.cmp({ row, s }, pos) ~= -sgn then
				if is_opening(fwd, #self.left_patterns, i) then
					-- current match is an opening pattern
					if lists.cmp({ row, s }, pos) == sgn then
						-- current match is an opening pattern (left)
						if finding then table.insert(findings, finding) end
						local inner, outer
						inner, outer, last_char_close =
							get_half_textobject(fwd, true, row, line, s, e)
						finding = {
							-- TODO: i, m
							i = i,
							m = m,
							inner = inner,
							outer = outer,
						}
					end
				elseif finding then
					-- current match is a closing pattern
					-- does current match corresponds to the opening pattern we are finding?
					if lists.cmp({ row, s }, pos) == sgn then
						local valid
						if fwd then
							valid = self.validator(finding.i, finding.m, i - #self.left_patterns, m)
						else
							valid = self.validator(i, m, finding.i - #self.left_patterns, finding.m)
						end
						if valid then
							local inner, outer, last_char_open =
								get_half_textobject(fwd, false, row, line, s, e)
							if last_char_open then inner = { row - 1, prev_line:len() } end
							assert(not last_char_close, "faulty logic")
							-- TODO: i, m
							if fwd then
								table.insert(found, {
									outer = { finding.outer, outer },
									inner = { finding.inner, inner },
								})
							else
								table.insert(found, {
									outer = { outer, finding.outer },
									inner = { inner, finding.inner },
								})
							end
							finding = table.remove(findings)
							if not finding then
								if lat then
									-- matches accumulate in closing order but must be returned in
									-- opening order to correspond to search direction
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
						get_half_textobject(fwd, false, row, line, s, e)
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

-- in case of unbalanced pairs, algorythm prioritises forward tokens, skiping as
-- much backwards tokens as needed to match them
function M:iterate_upwards(bufnr, pos)
	local patterns = process_pair_patterns(self)
	return iterators.zip_match(function(right, left)
		if self.validator(left.i, left.m, right.i - #self.left_patterns, right.m) then
			return {
				outer = { left.outer, right.outer },
				inner = { left.inner, right.inner },
			}
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
