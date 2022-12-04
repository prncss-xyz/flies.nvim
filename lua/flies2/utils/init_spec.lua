local M = require "flies2.utils.init"

describe("min", function()
	local function cmp(a, b) return a - b end
	it("should return the non nil value", function()
		assert.are.equals(1, M.min(cmp, 1, nil))
		assert.are.equals(1, M.min(cmp, nil, 1))
	end)
	it("should return the smallest value", function()
		assert.are.equals(1, M.min(cmp, 1, 2))
		assert.are.equals(1, M.min(cmp, 2, 1))
	end)
end)

describe("correct_indent", function()
	it("should normalize indentation", function()
		assert.are.equals(
			M.correct_indent(
				[[
          aaa
            bbb
          ccc
        ]],
				"!"
			),

			table.concat({ "!aaa", "!  bbb", "!ccc" }, "\n")
		)
		local input = [[
      aaa
        bbb
      ccc
    ]]
		assert.are.equals(
			M.correct_indent(input, "!"),
			table.concat({ "!aaa", "!  bbb", "!ccc" }, "\n")
		)
	end)
	it(
		"should not modify input when some indentation do not start with first line indentation",
		function()
			local input = [[
      aaa
        ccc
    ee
      ccc
    ]]
			assert.are.equals(M.correct_indent(input, "!"), input)
		end
	)
end)
