local M = {}

local editor = require "flies2.utils.editor"

local rep = {
	prev = function(_) end,
	next = function(_) end,
}

function M.recompose(prev, next_)
	if type(prev) == "string" then prev = editor.feedkeys(prev) end
	if type(next_) == "string" then next_ = editor.feedkeys(next_) end
	local fp = function()
		M.register(prev, next_)
		prev()
	end
	local fn = function()
		M.register(prev, next_)
		next_()
	end
	return fp, fn
end

function M.register(previous, next_)
	rep.prev = previous
	rep.next = next_
end

function M.prev()
	if rep.prev then rep.prev() end
end

function M.next()
	print "next"
	if rep.next then rep.next() end
end

return M
