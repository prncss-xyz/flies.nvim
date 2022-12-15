local M = require "flies2.utils.objects"

describe("new", function()
	local base = M:new {}
	function base:i_() return self.i end
	local derived = base:new { i = 3 }
	function derived:i_() return 4 end
	it(
		"should create a derived class",
		function() assert.are.equals(4, derived:i_()) end
	)
	it(
		"should refer to base method with super",
		function() assert.are.equals(3, derived:super "i_") end
	)
end)
describe("instance", function()
	it("should determine if provided object is an instance", function()
		local a = M:new {}
		local b = a:new {}
		assert.is.falsy(b:is_instance(a))
		assert.is.truthy(a:is_instance(b))
		assert.is.truthy(M:is_instance(b))
		assert.is.truthy(a:is_instance(a))
	end)
end)
