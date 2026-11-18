local M = require "flies.flies.brackets"
local tests = require "flies.utils.tests"

local function r(a, b)
	return {
		{ 1, a },
		{ 1, b },
	}
end

local function outer(match) return match and match.outer end

describe("brackets", function()
	it("should find forward", function()
		tests.set_buf [[ [{(.)}] ]]
		local pos = { 1, 1 }
		assert.are.same(r(2, 8), outer(M:find_forwards(0, pos, { count = 1 })))
		assert.are.same(r(3, 7), outer(M:find_forwards(0, pos, { count = 2 })))
		assert.are.same(r(4, 6), outer(M:find_forwards(0, pos, { count = 3 })))
		assert.is_nil(M:find_forwards(0, pos, { count = 4 }))
	end)
	it("should find backward", function()
		tests.set_buf [[ [{(.)}] ]]
		local pos = { 1, 9 }
		assert.are.same(r(2, 8), outer(M:find_backwards(0, pos, { count = 1 })))
		assert.are.same(r(3, 7), outer(M:find_backwards(0, pos, { count = 2 })))
		assert.are.same(r(4, 6), outer(M:find_backwards(0, pos, { count = 3 })))
		assert.is_nil(M:find_backwards(0, pos, { count = 4 }))
	end)
	it("should find upward", function()
		tests.set_buf [[ [{(.)}] ]]
		local pos = { 1, 5 }
		assert.are.same(r(4, 6), outer(M:find_upwards(0, pos, { count = 1 })))
		assert.are.same(r(3, 7), outer(M:find_upwards(0, pos, { count = 2 })))
		assert.are.same(r(2, 8), outer(M:find_upwards(0, pos, { count = 3 })))
		assert.is_nil(M:find_upwards(0, pos, { count = 4 }))
		assert.are.same(r(4, 6), outer(M:find_upwards(0, { 1, 4 }, { count = 1 })))
		assert.are.same(r(4, 6), outer(M:find_upwards(0, { 1, 6 }, { count = 1 })))
	end)
	it("should find inner", function()
		tests.set_buf [[ (ab) ]]
		assert.are.same(r(3, 4), M:find_upwards(0, { 1, 3 }, { count = 1 }).inner)
	end)
	it("should cope with uneven brackets", function()
		tests.set_buf [[ [{(.) ] ]]
		assert.are.same(r(4, 6), outer(M:find_upwards(0, { 1, 5 }, { count = 1 })))
		assert.are.same(r(2, 8), outer(M:find_upwards(0, { 1, 5 }, { count = 2 })))
		assert.is_nil(M:find_upwards(0, { 1, 5 }, { count = 3 }))
		tests.set_buf [[ [ (.)}] ]]
		assert.are.same(r(2, 8), outer(M:find_forwards(0, { 1, 1 }, { count = 1 })))
		assert.are.same(r(4, 6), outer(M:find_forwards(0, { 1, 1 }, { count = 2 })))
		assert.is_nil(M:find_forwards(0, { 1, 1 }, { count = 3 }))
	end)
end)
