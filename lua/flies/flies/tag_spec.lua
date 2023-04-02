local M = require "flies.flies.tag"
local tests = require "flies.utils.tests"

describe("tags", function()
	describe("find tags", function()
		local text = [[

<TaGa>
  <tagb attr="32"> 
    <tagc>toto</tagc>
  </TAGB>
</taga>

]]
		tests.set_buf(text)
		it("should find tags forward", function()
			assert.are.same(
				{ outer = { { 2, 1 }, { 6, 7 } }, inner = { { 3, 1 }, { 5, 9 } } },
				M:find_forwards(0, 1, { 1, 1 })
			)
			assert.are.same({
				outer = { { 3, 3 }, { 5, 9 } },
				inner = { { 4, 1 }, { 4, 21 } },
			}, M:find_forwards(0, 2, { 1, 1 }))
			assert.are.same({
				outer = { { 4, 5 }, { 4, 21 } },
				inner = { { 4, 11 }, { 4, 14 } },
			}, M:find_forwards(0, 3, { 1, 1 }))
			assert.is_nil(M:find_forwards(0, 4, { 1, 1 }))
		end)
		it("should find tags backward", function()
			assert.are.same({
				outer = { { 2, 1 }, { 6, 7 } },
				inner = { { 3, 1 }, { 5, 9 } },
			}, M:find_backwards(0, 1, { 7, 1 }))
			assert.are.same({
				outer = { { 3, 3 }, { 5, 9 } },
				inner = { { 4, 1 }, { 4, 21 } },
			}, M:find_backwards(0, 2, { 7, 1 }))
			assert.are.same({
				outer = { { 4, 5 }, { 4, 21 } },
				inner = { { 4, 11 }, { 4, 14 } },
			}, M:find_backwards(0, 3, { 7, 1 }))
			assert.is_nil(M:find_backwards(0, 4, { 7, 1 }))
		end)
	end)
	describe("find mustache tags", function()
		local text = [[

{{#tag_a}}blah a{{/tag_a}}
{{#tag_b?}}blah b{{/tag_b?}}

]]
		tests.set_buf(text)
		it("should find tags forward", function()
			assert.are.same(
				{ outer = { { 2, 1 }, { 2, 26 } }, inner = { { 2, 11 }, { 2, 16 } } },
				M:find_forwards(0, 1, { 1, 1 })
			)
			assert.are.same(
				{ outer = { { 3, 1 }, { 3, 28 } }, inner = { { 3, 12 }, { 3, 17 } } },
				M:find_forwards(0, 2, { 1, 1 })
			)
		end)
	end)
	describe("find erb tags", function()
		local text = [[

<%% blah %%>
<%# blah %>
<%= blah %>
<% blah %>

]]
		tests.set_buf(text)
		it("should find tags forward", function()
			assert.are.same(
				{ outer = { { 2, 1 }, { 2, 12 } }, inner = { { 2, 4 }, { 2, 9 } } },
				M:find_forwards(0, 1, { 1, 1 })
			)
			assert.are.same(
				{ outer = { { 3, 1 }, { 3, 11 } }, inner = { { 3, 4 }, { 3, 9 } } },
				M:find_forwards(0, 2, { 1, 1 })
			)
			assert.are.same(
				{ outer = { { 4, 1 }, { 4, 11 } }, inner = { { 4, 4 }, { 4, 9 } } },
				M:find_forwards(0, 3, { 1, 1 })
			)
			assert.are.same(
				{ outer = { { 5, 1 }, { 5, 10 } }, inner = { { 5, 3 }, { 5, 8 } } },
				M:find_forwards(0, 4, { 1, 1 })
			)
		end)
	end)
end)
