local M = require "flies2.flies.variable_segment"

local tests = require "flies2.utils.tests"

local function r(a, b) return { { 1, a }, { 1, b } } end

describe("quote", function()
	it("should find snake-case segments", function()
		local text = [[ 234 de_fg ]]
		tests.set_buf(text)
		assert.are.same(r(6, 7), M:find_forwards(0, 1, { 1, 1 }).outer)
		assert.are.same(r(9, 10), M:find_forwards(0, 2, { 1, 1 }).outer)
		--TODO: test around
	end)
	it("should find camel-case segments", function()
		tests.set_buf " abCd"
		assert.are.same(r(2, 3), M:find_forwards(0, 1, { 1, 1 }).outer)
		assert.are.same(r(4, 5), M:find_forwards(0, 2, { 1, 1 }).outer)
		tests.set_buf " Efg"
		assert.are.same(r(2, 4), M:find_forwards(0, 1, { 1, 1 }).outer)
		tests.set_buf " noHTML"
		assert.are.same(r(2, 3), M:find_forwards(0, 1, { 1, 1 }).outer)
		assert.are.same(r(4, 7), M:find_forwards(0, 2, { 1, 1 }).outer)
		-- TODO:
		-- tests.set_buf " HTMLno"
		-- assert.are.same(r(2, 5), M:find_forwards(0, 1, { 1, 1 }).outer)
	end)
end)
