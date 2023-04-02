local M = require "flies.utils.ts"
local tests = require "flies.utils.tests"

local function r(a, b) return { { 1, a }, { 1, b } } end

-- describe("query", function()
-- 	it("description", function()
-- 		local text = [[
--  <tata toto="tutu" /> ]]
-- 		tests.set_buf(text)
-- 		vim.bo.filetype = "javascriptreact"
-- 		-- vim.bo.filetype = "typescriptreact"
-- 		local matches = M.query(0, "open_close")
-- 		assert.are.same({
-- 			{
-- 				pattern = 1,
-- 				metadata = {},
-- 				outer = r(2, 21),
-- 				identifier = r(3, 6),
-- 				contents = r(8, 18),
-- 			},
-- 		}, matches)
-- 	end)
-- end)

describe("query", function()
	it("description", function()
		local text = [[
 <tata toto="tutu"></tata> ]]
		tests.set_buf(text)
		vim.bo.filetype = "javascriptreact"
		-- vim.bo.filetype = "typescriptreact"
		local matches = M.query_from_files(0, "open_close")
		assert.are.same({
			{
				pattern = 2,
				metadata = {},
				outer = r(2, 26),
				identifier = r(3, 6),
				contents = r(8, 18),
			},
		}, matches)
	end)
end)
