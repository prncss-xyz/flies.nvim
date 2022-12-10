local M = require "flies2.flies.fly"

local tests = require "flies2.utils.tests"

describe("get_wiseness", function()
	it("should get_wiseness (same line)", function()
		local text = " 234  7 "
		tests.set_buf(text)
		local f = M:new { lonely_wiseness = "V" }
		assert.are.equals("V", f:get_wiseness(0, { 1, 2 }, { 1, 7 }))
		assert.are.equals("v", f:get_wiseness(0, { 1, 3 }, { 1, 7 }))
	end)
	it("should get_wiseness (multiple lines)", function()
		local text = [[

 aaa
 bbb
 ccc


    ]]
		tests.set_buf(text)
		assert.are.equals("V", M:get_wiseness(0, { 2, 2 }, { 4, 4 }))
		assert.are.equals("v", M:get_wiseness(0, { 2, 3 }, { 4, 4 }))
		assert.are.equals("v", M:get_wiseness(0, { 2, 2 }, { 4, 3 }))
	end)
end)

describe("borough (charwise)", function()
	it("description", function()
		tests.set_buf " 234  7"
		local wiseness
		wiseness = M:get_wiseness(0, { 1, 2 }, { 1, 7 })
		assert.are.equals(wiseness, "v")
		assert.are.same({ { 1, 2 }, { 1, 7 } }, { M:borough(0, { 1, 2 }, { 1, 7 }) })

		wiseness = M:get_wiseness(0, { 1, 2 }, { 1, 4 })
		assert.are.equals(wiseness, "v")
		assert.are.same({ { 1, 2 }, { 1, 6 } }, { M:borough(0, { 1, 2 }, { 1, 4 }) })

		tests.set_buf "1234"
		wiseness = M:get_wiseness(0, { 1, 1 }, { 1, 4 })
		assert.are.equals(wiseness, "v")
		assert.are.same({ { 1, 1 }, { 1, 4 } }, { M:borough(0, { 1, 1 }, { 1, 4 }) })
	end)
end)

describe("borough (linewise)", function()
	it("description", function()
		tests.set_buf [[
9999

123
456


bbbbbbbbb
]]
		local f = M:new { lonely_wiseness = "V" }
		local wiseness = f:get_wiseness(0, { 3, 1 }, { 4, 3 })
		assert.are.equals(wiseness, "V")
		assert.are.same({ { 3, 1 }, { 6, 1 } }, { f:borough(0, { 3, 1 }, { 4, 3 }) })

		wiseness = f:get_wiseness(0, { 7, 1 }, { 7, 9 })
		assert.are.equals(wiseness, "V")
		assert.are.same({ { 5, 1 }, { 7, 9 } }, { f:borough(0, { 7, 1 }, { 7, 9 }) })

		wiseness = f:get_wiseness(0, { 1, 1 }, { 1, 9 })
		assert.are.equals(wiseness, "V")
		assert.are.same({ { 1, 1 }, { 2, 1 } }, { f:borough(0, { 1, 1 }, { 1, 9 }) })
	end)
end)
