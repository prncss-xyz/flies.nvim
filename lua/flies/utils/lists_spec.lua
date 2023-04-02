local M = require "flies.utils.lists"

describe("is_inside", function()
	it(
		"should determine wether pos is inside range",
		function()
      assert.is.truthy(M.is_inside({ { 1, 1 }, { 3, 3 } }, { 1, 1 }))
      assert.is.truthy(M.is_inside({ { 1, 1 }, { 3, 3 } }, { 3, 3 }))
      assert.is.truthy(M.is_inside({ { 1, 1 }, { 3, 3 } }, { 2, 2 }))
      assert.is.falsy(M.is_inside({ { 1, 1 }, { 3, 3 } }, { 0, 0 }))
      assert.is.falsy(M.is_inside({ { 1, 1 }, { 3, 3 } }, { 4, 4 }))
    end
	)
end)

describe("cmp", function()
	it("compares greater", function()
		assert.is_greater(0, M.cmp({ 1 }, { 2 }))
		assert.is_greater(0, M.cmp({ 1 }, { 1, 2 }))
		assert.is_greater(0, M.cmp({ 1, 1 }, { 1, 2 }))
		assert.is_greater(0, M.cmp({ 1, 1 }, { 2, 1 }))
	end)
	it("compares smaller", function()
		assert.is_smaller(0, M.cmp({ 2 }, { 1 }))
		assert.is_smaller(0, M.cmp({ 1, 2 }, { 1 }))
		assert.is_smaller(0, M.cmp({ 1, 2 }, { 1, 1 }))
		assert.is_smaller(0, M.cmp({ 2, 1 }, { 1, 1 }))
	end)
	it("compares equals", function()
		assert.are.equals(0, M.cmp({}, {}))
		assert.are.equals(0, M.cmp({ 1 }, { 1 }))
		assert.are.equals(0, M.cmp({ 2 }, { 2 }))
	end)
end)

describe("ripairs", function()
	it("should iterate pairs in reverse order", function()
		local table_in = { 4, 5, 6 }
		local table_out = {}
		local i_
		for i, v in M.ripairs(table_in) do
			table_out[i] = v
			if i_ then assert.is_greater(i, i_) end
		end
		assert.are.same(table_in, table_out)
	end)
end)
