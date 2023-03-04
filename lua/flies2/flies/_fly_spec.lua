local M = require "flies2.flies._fly"

local tests = require "flies2.utils.tests"

describe("get_wiseness", function()
	it("should get_wiseness (same line)", function()
		local text = " 234  7 "
		tests.set_buf(text)
		local f = M:new { lonely_wiseness_inner = "V" }
		assert.are.equals("V", f:get_wiseness(0, { { 1, 2 }, { 1, 7 } }))
		assert.are.equals("v", f:get_wiseness(0, { { 1, 3 }, { 1, 7 } }))
	end)
	it("should get_wiseness (multiple lines)", function()
		local text = [[

 aaa
 bbb
 ccc


    ]]
		tests.set_buf(text)
		assert.are.equals("V", M:get_wiseness(0, { { 2, 2 }, { 4, 4 } }))
		assert.are.equals("v", M:get_wiseness(0, { { 2, 3 }, { 4, 4 } }))
		assert.are.equals("v", M:get_wiseness(0, { { 2, 2 }, { 4, 3 } }))
	end)
end)

describe("around (charwise)", function()
	it("description", function()
		tests.set_buf [[
 234  7]]
		local wiseness
		wiseness = M:get_wiseness(0, { { 1, 2 }, { 1, 7 } })
		assert.are.equals(wiseness, "v")
		assert.are.same(
			{ { 1, 1 }, { 1, 7 } },
			M:around(0, { { 1, 2 }, { 1, 7 } }, "v")
		)

		wiseness = M:get_wiseness(0, { { 1, 2 }, { 1, 4 } })
		assert.are.equals(wiseness, "v")
		assert.are.same(
			{ { 1, 2 }, { 1, 6 } },
			M:around(0, { { 1, 2 }, { 1, 4 } }, "v")
		)

		tests.set_buf "1234"
		wiseness = M:get_wiseness(0, { { 1, 1 }, { 1, 4 } })
		assert.are.equals(wiseness, "v")
		assert.are.same(
			{ { 1, 1 }, { 1, 4 } },
			M:around(0, { { 1, 1 }, { 1, 4 } }, "v")
		)

		tests.set_buf [[
235  135  124]]
		assert.are.same(
			{ { 1, 9 }, { 1, 13 } },
			M:around(0, { { 1, 11 }, { 1, 13 } }, "v")
		)
	end)
end)

describe("around (linewise)", function()
	it("description", function()
		tests.set_buf [[
9999

123
456


bbbbbbbbb
]]
		local f = M:new { lonely_wiseness_inner = "V" }
		local wiseness = f:get_wiseness(0, { { 3, 1 }, { 4, 3 } })
		assert.are.equals(wiseness, "V")
		assert.are.same(
			{ { 3, 1 }, { 6, 1 } },
			f:around(0, { { 3, 1 }, { 4, 3 } }, "V")
		)

		wiseness = f:get_wiseness(0, { { 7, 1 }, { 7, 9 } })
		assert.are.equals(wiseness, "V")
		assert.are.same(
			{ { 5, 1 }, { 7, 9 } },
			f:around(0, { { 7, 1 }, { 7, 9 } }, "V")
		)

		wiseness = f:get_wiseness(0, { { 1, 1 }, { 1, 9 } })
		assert.are.equals(wiseness, "V")
		assert.are.same(
			{ { 1, 1 }, { 2, 1 } },
			f:around(0, { { 1, 1 }, { 1, 9 } }, "V")
		)
	end)
end)

describe("right, left (charwise)", function()
	it("should select the proper half, from inside/outside", function()
		tests.set_buf [[
  3456  ]]
		assert.are.same(
			{ { 1, 5 }, { 1, 6 } },
			M:right(0, { 1, 5 }, { { 1, 3 }, { 1, 6 } }, "v")
		)
		assert.are.same(
			{ { 1, 1 }, { 1, 2 } },
			M:right(0, { 1, 1 }, { { 1, 3 }, { 1, 6 } }, "v")
		)
		assert.are.same(
			{ { 1, 3 }, { 1, 4 } },
			M:left(0, { 1, 5 }, { { 1, 3 }, { 1, 6 } }, "v")
		)
		assert.are.same(
			{ { 1, 7 }, { 1, 7 } },
			M:left(0, { 1, 8 }, { { 1, 3 }, { 1, 6 } }, "v")
		)
	end)
end)

describe("right, left (linewise)", function()
	it("should select the proper half, from inside/outside", function()
		tests.set_buf [[


  3333
  4444
  5555
  6666


]]
		assert.are.same(
			{ { 1, 1 }, { 2, 1 } },
			M:right(0, { 1, 1 }, { { 3, 3 }, { 6, 6 } }, "V")
		)
		assert.are.same(
			{ { 5, 3 }, { 6, 6 } },
			M:right(0, { 5, 3 }, { { 3, 3 }, { 6, 6 } }, "V")
		)
		assert.are.same(
			{ { 3, 3 }, { 4, 6 } },
			M:left(0, { 5, 3 }, { { 3, 3 }, { 6, 6 } }, "V")
		)
		assert.are.same(
			{ { 7, 1 }, { 7, 1 } },
			M:left(0, { 8, 1 }, { { 3, 3 }, { 6, 6 } }, "V")
		)
	end)
end)
