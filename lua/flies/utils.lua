local M = {}

function M.invert(t)
  local r = {}
  for k, v in pairs(t) do
    r[v] = k
  end
  return r
end

function M.reverse(t)
  local i = 1
  local j
  while true do
    j = #t + 1 - i
    if j <= i then
      break
    end
    t[i], t[j] = t[j], t[i]
    i = i + 1
  end
end

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

function M.jump(target, qualifier, till, n_times)
  local flags = qualifier == 'previous' and 'Wb' or 'W'
  if till then
    if qualifier == 'previous' then
      target = target .. '.'
    else
      target = '.' .. target
    end
  end
  if qualifier == 'previous' and till then
    flags = flags .. 'e'
  end

  for _ = 1, n_times do
    vim.fn.search(target, flags)
  end

  -- Open enough folds to show jump
  vim.cmd 'normal! zv'
end

return M
