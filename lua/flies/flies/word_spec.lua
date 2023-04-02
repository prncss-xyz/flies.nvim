local M = require "flies.flies.word"

local tests = require "flies.utils.tests"

local function r(row, a, b)
	return {
		{ row, a },
		{ row, b },
	}
end

describe("word", function()
	local text = [[
aaa

...  ccc 
  
ddd
]]
	tests.set_buf(text)
	describe("find_forwards", function()
		it("should find next word", function()
			assert.are.same(r(3, 6, 8), M:find_forwards(0, 1, { 3, 4 }).outer)
			assert.are.same(r(5, 1, 3), M:find_forwards(0, 2, { 3, 4 }).outer)
			assert.is_nil(M:find_forwards(0, 3, { 3, 4 }))
			assert.are.same(r(3, 6, 8), M:find_forwards(0, 1, { 3, 1 }).outer)
			assert.are.same(r(3, 6, 8), M:find_forwards(0, 1, { 3, 3 }).outer)
		end)
	end)
	describe("find_backwards", function()
		it("should find previous word", function()
			assert.are.same(r(3, 1, 3), M:find_backwards(0, 1, { 3, 4 }).outer)
			assert.are.same(r(1, 1, 3), M:find_backwards(0, 2, { 3, 4 }).outer)
			assert.is_nil(M:find_backwards(0, 3, { 3, 4 }))
			assert.are.same(r(1, 1, 3), M:find_backwards(0, 1, { 3, 1 }).outer)
			assert.are.same(r(1, 1, 3), M:find_backwards(0, 1, { 3, 3 }).outer)
		end)
	end)
	describe("find_upwards", function()
		it("should find upwards word", function()
			assert.is_nil(M:find_upwards(0, 2, { 3, 3 }))
			assert.is_nil(M:find_upwards(0, 1, { 3, 4 }))
			assert.are.same(r(3, 1, 3), M:find_upwards(0, 1, { 3, 3 }).outer)
		end)
	end)
end)
