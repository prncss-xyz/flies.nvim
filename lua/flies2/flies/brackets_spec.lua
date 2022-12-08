local M = require "flies2.flies.brackets"
local tests = require "flies2.utils.tests"

local function r(a, b)
	return {
		{ 1, a },
		{ 1, a + 1 },
		{ 1, b - 1 },
		{ 1, b },
	}
end

describe("brackets", function()
	local text = [[ [{(.)}] ]]
	tests.set_buf(text)
	describe("find brackets", function()
		it("should find brackets", function()
			assert.are.same(r(2, 8), M:find_forwards(0, 1, { 1, 1 }))
			assert.are.same(r(3, 7), M:find_forwards(0, 2, { 1, 1 }))
			assert.are.same(r(4, 6), M:find_forwards(0, 3, { 1, 1 }))
			assert.is_nil(M:find_forwards(0, 4, { 1, 1 }))
		end)
	end)
end)
