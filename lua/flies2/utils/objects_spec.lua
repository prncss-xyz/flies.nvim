local M = require "flies2.utils.objects"

describe("new", function()
	it("description", function()
		local base = M:new {}
		function base:i_() return self.i end
		local derived = base:new { i = 3 }
		function derived:i_() return 4 end
		assert.are.equals(4, derived:i_())
		assert.are.equals(3, derived:super "i_")
	end)
end)
