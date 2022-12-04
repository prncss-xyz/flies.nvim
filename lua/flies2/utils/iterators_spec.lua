local M = require "flies2.utils.iterators"

describe("to_list_single", function()
	it("should create list", function()
		local function producer()
			coroutine.yield(4)
			coroutine.yield(5)
			coroutine.yield(6)
		end
		assert.are.same({ 4, 5, 6 }, M.to_list_single(coroutine.wrap(producer)))
	end)
end)

describe("from_list_single", function()
	it(
		"should invert to_list_single",
		function()
			assert.are.same(
				{ 4, 5, 6 },
				M.to_list_single(M.from_list_single { 4, 5, 6 })
			)
		end
	)
end)

describe("to_list_many", function()
	it("should create list", function()
		local function producer()
			coroutine.yield(4, 7)
			coroutine.yield(5, 8)
			coroutine.yield(6, 9)
		end
		assert.are.same(
			{ { 4, 7 }, { 5, 8 }, { 6, 9 } },
			M.to_list_many(coroutine.wrap(producer))
		)
	end)
end)

describe("from_list_many", function()
	it(
		"should invert to_list_many",
		function()
			assert.are.same(
				{ { 4, 7 }, { 5, 8 }, { 6, 9 } },
				M.to_list_many(M.from_list_many { { 4, 7 }, { 5, 8 }, { 6, 9 } })
			)
		end
	)
end)

describe("null", function()
	it("should iterate no values", function()
		for _ in M.null() do
			assert(false, "Should not happen")
		end
	end)
end)

describe("nth", function()
	it("description", function()
		assert.are.same({ 2, 5 }, { M.nth(2)(ipairs { 4, 5, 6 }) })
		assert.is_nil(M.nth(0)(ipairs { 4, 5, 6 }))
		assert.is_nil(M.nth(7)(ipairs { 4, 5, 6 }))
		assert.is_nil(M.nth(1)(M.null()))
	end)
end)
