local M = require "flies2.utils.tables"

describe("deep_merge", function()
	it(
		"should merge recursively",
		function()
			assert.are.same(
				{ a = { b = 2, c = 3 } },
				M.deep_merge({ a = { b = 2 } }, { a = { c = 3 } })
			)
		end
	)
end)

describe("contains", function()
	it("should be truthy if left  recursively contain right", function()
		assert.is.truthy(M.contains({ 1, 2 }, { 1 }))
		assert.is.truthy(M.contains({ 1, 2 }, {}))
		assert.is.truthy(M.contains({ 1 }, { 1 }))
		assert.is.truthy(M.contains({}, {}))
	end)
	it(
		"should be falsy if left does not recursively contain right",
		function() assert.is.falsy(M.contains({ 1 }, { 1, 2 })) end
	)
end)
