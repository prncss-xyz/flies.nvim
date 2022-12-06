local M = require "flies2.flies.quote"

local tests = require "flies2.utils.tests"

local function r(a, b)
	return {
		{ 1, a },
		{ 1, a + 1 },
		{ 1, b - 1 },
		{ 1, b },
	}
end

describe("quote", function()
	it("should find quoted strings", function()
		local text = [[ " ' " '"' `` "a\"b" ]]
		tests.set_buf(text)
		assert.are.same(r(2, 6), M:find_forwards(0, 1, { 1, 1 }))
		assert.are.same(r(8, 10), M:find_forwards(0, 2, { 1, 1 }))
		assert.are.same(r(12, 13), M:find_forwards(0, 3, { 1, 1 }))
		assert.are.same(r(15, 20), M:find_forwards(0, 4, { 1, 1 }))
	end)

	it("should find quoted strings", function()
		local f = M:new { restrict = '"' }
		local text = [[ ' " ' `" " ' ' ` "a\"b" ]]
		tests.set_buf(text)
		assert.are.same(r(19, 24), f:find_forwards(0, 1, { 1, 1 }))
	end)
end)
