local M = require "flies2.flies.brackets"
local tests = require "flies2.utils.tests"

local function r(a, b)
	return {
		{ 1, a },
		{ 1, a + 1 },
		{ 1, b - 1 },
		{ 1, b },
	}
end

describe("brackets", function()
	describe("find brackets", function()
		it("should find forward", function()
			local text = [[ [{(.)}] ]]
			tests.set_buf(text)
			assert.are.same(r(2, 8), M:find_forwards(0, 1, { 1, 1 }))
			assert.are.same(r(3, 7), M:find_forwards(0, 2, { 1, 1 }))
			assert.are.same(r(4, 6), M:find_forwards(0, 3, { 1, 1 }))
			assert.is_nil(M:find_forwards(0, 4, { 1, 1 }))
		end)
		it("should find backward", function()
			local text = [[ [{(.)}] ]]
			tests.set_buf(text)
			assert.are.same(r(2, 8), M:find_backwards(0, 1, { 1, 9 }))
			assert.are.same(r(3, 7), M:find_backwards(0, 2, { 1, 9 }))
			assert.are.same(r(4, 6), M:find_backwards(0, 3, { 1, 9 }))
			assert.is_nil(M:find_forwards(0, 4, { 1, 9 }))
		end)
		it("should find upward", function()
			local text = [[ [{(.)}] ]]
			tests.set_buf(text)
			assert.are.same(r(4, 6), M:find_upwards(0, 1, { 1, 5 }))
			assert.are.same(r(3, 7), M:find_upwards(0, 2, { 1, 5 }))
			assert.are.same(r(2, 8), M:find_upwards(0, 3, { 1, 5 }))
			assert.is_nil(M:find_forwards(0, 4, { 1, 5 }))
			assert.are.same(r(4, 6), M:find_upwards(0, 1, { 1, 4 }))
			assert.are.same(r(4, 6), M:find_upwards(0, 1, { 1, 6 }))
		end)
		it("should cope with uneven braces", function()
			local text = [[ [{(.) ] ]]
			tests.set_buf(text)
			assert.is_nil(M:find_forwards(0, 1, { 1, 1 }))
			assert.are.same(r(4, 6), M:find_upwards(0, 1, { 1, 5 }))
			assert.are.same(r(2, 8), M:find_upwards(0, 2, { 1, 5 }))
			assert.is_nil(M:find_forwards(0, 3, { 1, 5 }))
			text = [[ [ (.)}] ]]
			tests.set_buf(text)
			assert.are.same(r(2, 8), M:find_forwards(0, 1, { 1, 1 }))
			assert.are.same(r(4, 6), M:find_forwards(0, 2, { 1, 1 }))
			assert.is_nil(M:find_forwards(0, 3, { 1, 1 }))
			assert.are.same(r(4, 6), M:find_upwards(0, 1, { 1, 5 }))
			assert.is_nil(M:find_forwards(0, 2, { 1, 5 }))
		end)
	end)
end)
