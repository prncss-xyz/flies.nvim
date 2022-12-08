local M = {}

local buffers = require "flies2.utils.buffers"

---sets the buffer to provided value
function M.set_buf(text)
	local row = buffers.get_eob(0)
	local line = buffers.get_line(0, row)
	local col = line:len() + 1
	buffers.edit(0, { { { 1, 1 }, { row, col }, text } })
end

---gets the whole buffer
function M.get_buf()
	local row = buffers.get_eob(0)
	local line = buffers.get_line(0, row)
	local col = line:len()
	return buffers.get_range(0, { 1, 1 }, { row, col })
end

return M
