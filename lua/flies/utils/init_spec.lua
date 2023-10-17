local M = require "flies.utils.init"

describe("correct_indent", function()
	it("should normalize indentation", function()
		assert.are.equals(
			M.correct_indent(
				"!",
				[[
          aaa
            bbb
          ccc
        ]]
			),

			table.concat({ "!aaa", "!  bbb", "!ccc" }, "\n")
		)
		local input = [[
      aaa
        bbb
      ccc
    ]]
		assert.are.equals(
			M.correct_indent("!", input),
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
			assert.are.equals(M.correct_indent("!", input), input)
		end
	)
end)
