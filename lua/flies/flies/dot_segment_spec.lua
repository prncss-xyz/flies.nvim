local M = require "flies.flies.dot_segment"

local tests = require "flies.utils.tests"

local function r(a, b) return { { 1, a }, { 1, b } } end

describe("quote", function()
	it("should find dot segments", function()
		local text = [[ 234 de.fg ]]
		tests.set_buf(text)
		assert.are.same(r(6, 7), M:find_forwards(0, 1, { 1, 1 }).outer)
		assert.are.same(r(6, 8), M:around(0, M:find_forwards(0, 1, { 1, 1 }), "v"))
	end)
end)
