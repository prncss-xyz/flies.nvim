local M = require "flies.utils.iterators"

describe("to_list_single", function()
	it("should create list", function()
		local function producer()
			coroutine.yield(4)
			coroutine.yield(5)
			coroutine.yield(6)
		end
		assert.are.same({ 4, 5, 6 }, M.to_list_single(coroutine.wrap(producer)))
		assert.are.same({}, M.to_list_single(M.null()))
		assert.are.same({ 3 }, M.to_list_single(M.unit(3)))
	end)
end)

describe("from_list_single", function()
	it("should invert to_list_single", function()
		assert.are.same({ 4, 5, 6 }, M.to_list_single(M.from_list_single { 4, 5, 6 }))
		assert.are.same({}, M.to_list_many(M.null()))
		assert.are.same({ { 1, 2 } }, M.to_list_many(M.unit(1, 2)))
	end)
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
		assert.is_nil(M.nth(0)(M.range(2, 3)))
		assert.are.same(2, M.nth(1)(M.range(2, 3)))
		assert.are.same(3, M.nth(2)(M.range(2, 3)))
		assert.is_nil(M.nth(3)(M.range(2, 3)))
	end)
end)

describe("range", function()
	it("should iterate the range with index", function()
		assert.are.same({ 1, 2, 3 }, (M.to_list_single(M.range(1, 3))))
		assert.are.same({ 1, 3, 5 }, (M.to_list_single(M.range(1, 5, 2))))
		assert.are.same({ 5, 3, 1 }, (M.to_list_single(M.range(5, 1, -2))))
	end)
end)

describe("flatten", function()
	it("description", function()
		local n = 0
		local function fu()
			n = n + 1
			if n < 4 then return M.range(n) end
		end
		assert.are.same({ 1, 1, 2, 1, 2, 3 }, M.to_list_single(M.flatten(fu)))
	end)
	it(
		"should respect multiple values",
		function()
			assert.are.same(
				{ { 4, 5 }, { 6, 7 } },
				M.to_list_many(M.flatten(M.unit(M.from_list_many { { 4, 5 }, { 6, 7 } })))
			)
		end
	)
end)

-- describe("chain", function()
-- 	-- TODO: import: compose, comp
-- 	it("should chain", function()
-- 		local function t(n) return M.range(n) end
--
-- 		assert.are.same(
-- 			{ 1, 1, 2, 1, 2, 3 },
-- 			M.compose(M.chain(t), M.to_list_single)(M.range(3))
-- 		)
-- 	end)
-- 	it("should chain", function()
-- 		local t = { 1, 2, 1, 2 }
-- 		assert.are.same(
-- 			t,
-- 			M.comp { 1, 2 }(
-- 				ipairs,
-- 				M.chain(function(_, _) return ipairs(t) end),
-- 				M.to_list_single
-- 			)
-- 		)
-- 	end)
-- end)

describe("zip_match", function()
	it("description", function()
		assert.are.same(
			{ { 0, 0 }, { 2, 6 }, { 4, 12 } },
			M.to_list_single(
				M.zip_match(
					function(a, b) return a * 3 == b and { a, b } end,
					M.range(0, 12, 2)
				)(M.range(0, 12, 3))
			)
		)
	end)
end)
