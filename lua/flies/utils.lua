local M = {}

function M.count()
	if vim.v.count == vim.v.count1 then
		return vim.v.count
	end
end

function M.name(...)
  return table.concat({ ... }, '_')
end

function M.t(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

return M
