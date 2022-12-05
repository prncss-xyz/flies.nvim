local M = require "flies2.utils.lists"

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

describe("is_in_range", function()
	it(
		"should be true when in range",
		function() assert.is_true(M.is_in_range({ 1, 1 }, { 1, 3 }, { 1, 2 })) end
	)
	it("should be true when not in range", function()
		assert.is_false(M.is_in_range({ 1, 1 }, { 1, 3 }, { 1, 4 }))
		assert.is_false(M.is_in_range({ 1, 1 }, { 1, 3 }, { 1, 0 }))
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
