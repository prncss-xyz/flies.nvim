local M = require "flies2.flies.word"

local tests = require "flies2.utils.tests"

describe("word", function()
	local text = [[
aaa

...  ccc
  
ddd
]]
	tests.set_buf(text)
	describe("find_forwards", function()
		it("should find next word", function()
			assert.are.same(
				{ { 3, 6 }, { 3, 6 }, { 3, 8 }, { 3, 8 } },
				M:find_forwards(0, 1, { 3, 4 })
			)
			assert.are.same(
				{ { 5, 1 }, { 5, 1 }, { 5, 3 }, { 5, 3 } },
				M:find_forwards(0, 2, { 3, 4 })
			)
			assert.is_nil(M:find_forwards(0, 3, { 3, 4 }))
		end)
	end)
	describe("find_backwards", function()
		it("should find previous word", function()
			assert.are.same(
				{ { 3, 1 }, { 3, 1 }, { 3, 3 }, { 3, 3 } },
				M:find_backwards(0, 1, { 3, 4 })
			)
			assert.are.same(
				{ { 1, 1 }, { 1, 1 }, { 1, 3 }, { 1, 3 } },
				M:find_backwards(0, 2, { 3, 4 })
			)
			assert.is_nil(M:find_backwards(0, 3, { 3, 4 }))
		end)
	end)
	describe("find_upwards", function()
		it("should find upwards word", function()
			assert.is_nil(M:find_upwards(0, 2, { 3, 3 }))
			assert.is_nil(M:find_upwards(0, 1, { 3, 4 }))
			assert.are.same(
				{ { 3, 1 }, { 3, 1 }, { 3, 3 }, { 3, 3 } },
				M:find_upwards(0, 1, { 3, 3 })
			)
		end)
	end)
end)
