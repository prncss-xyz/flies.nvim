local M = require "flies2.utils.tests"

describe("borough", function()
	it("description", function()
		local text = [[
    sadf
      asfdjk safd
      fsd
    ]]
		M.set_buf(text)
		assert.are.same(text, M.get_buf())
	end)
end)
