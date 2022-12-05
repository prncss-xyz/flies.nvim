local M = require "flies2.flies.word"
local iterators = require "flies2.utils.iterators"

local tests = require "flies2.utils.tests"

describe("word", function()
	local text = [[
aaa

bbb  ccc
  
ddd
]]
	tests.set_buf(text)
	describe("find_forwards", function()
		it("should find next word", function()
			assert.are.same(
				{ { 3, 6 }, { 3, 6 }, { 3, 8 }, { 3, 8 } },
				M:find_forwards(1, { 3, 4 })
			)
			assert.are.same(
				{ { 5, 1 }, { 5, 1 }, { 5, 3 }, { 5, 3 } },
				M:find_forwards(2, { 3, 4 })
			)
			assert.is_nil(M:find_forwards(3, { 3, 4 }))
		end)
	end)
	describe("find_backwards", function()
		it("should find previous word", function()
			assert.are.same(
				{ { 3, 1 }, { 3, 1 }, { 3, 3 }, { 3, 3 } },
				M:find_backwards(1, { 3, 4 })
			)
			assert.are.same(
				{ { 1, 1 }, { 1, 1 }, { 1, 3 }, { 1, 3 } },
				M:find_backwards(2, { 3, 4 })
			)
			assert.is_nil(M:find_backwards(3, { 3, 4 }))
		end)
	end)
	describe("find_upwards", function()
		it("should find upwards word", function()
			assert.is_nil(M:find_upwards(2, { 3, 3 }))
			assert.is_nil(M:find_upwards(1, { 3, 4 }))
			assert.are.same(
				{ { 3, 1 }, { 3, 1 }, { 3, 3 }, { 3, 3 } },
				M:find_upwards(1, { 3, 3 })
			)
		end)
	end)
end)
