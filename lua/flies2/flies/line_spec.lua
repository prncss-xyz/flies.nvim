local M = require "flies2.flies.line"

local tests = require "flies2.utils.tests"

local function r(row, a, b)
	return {
		{ row, a },
		{ row, a },
		{ row, b },
		{ row, b },
	}
end

describe("quote", function()
	it("should find non-empty line", function()
		local text = [[ 234 67 ]]
		tests.set_buf(text)
		assert.are.same(r(1, 2, 7), M:find_forwards(0, 1, { 1, 1 }))
		local text = [[     67 ]]
		tests.set_buf(text)
		assert.are.same(r(1, 6, 7), M:find_forwards(0, 1, { 1, 1 }))
		local text = [[

 23 
]]
		tests.set_buf(text)
		assert.are.same(r(2, 2, 3), M:find_forwards(0, 1, { 1, 1 }))
	end)
end)
