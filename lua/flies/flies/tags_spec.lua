local M = require "flies.flies.tags"
local tests = require "flies.utils.tests"

describe("tags", function()
	describe("find tags", function()
		local text = [[

<TaGa>
  <tagb attr="32"> 
    <tagc>toto</tagc>
  </TAGB>
</taga>

]]
		tests.set_buf(text)
		it("should find tags forward", function()
			assert.are.same(
				{ outer = { { 2, 1 }, { 6, 7 } }, inner = { { 3, 1 }, { 5, 9 } } },
				M:find_forwards(0, 1, { 1, 1 })
			)
			assert.are.same({
				outer = { { 3, 3 }, { 5, 9 } },
				inner = { { 4, 1 }, { 4, 21 } },
			}, M:find_forwards(0, 2, { 1, 1 }))
			assert.are.same({
				outer = { { 4, 5 }, { 4, 21 } },
				inner = { { 4, 11 }, { 4, 14 } },
			}, M:find_forwards(0, 3, { 1, 1 }))
			assert.is_nil(M:find_forwards(0, 4, { 1, 1 }))
		end)
		it("should find tags backward", function()
			assert.are.same({
				outer = { { 2, 1 }, { 6, 7 } },
				inner = { { 3, 1 }, { 5, 9 } },
			}, M:find_backwards(0, 1, { 7, 1 }))
			assert.are.same({
				outer = { { 3, 3 }, { 5, 9 } },
				inner = { { 4, 1 }, { 4, 21 } },
			}, M:find_backwards(0, 2, { 7, 1 }))
			assert.are.same({
				outer = { { 4, 5 }, { 4, 21 } },
				inner = { { 4, 11 }, { 4, 14 } },
			}, M:find_backwards(0, 3, { 7, 1 }))
			assert.is_nil(M:find_backwards(0, 4, { 7, 1 }))
		end)
	end)
end)
