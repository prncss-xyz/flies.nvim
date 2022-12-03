local M = {}

function M.cmp(t1, t2)
  local i = 1
  while true do
    local v1, v2 = t1[i], t2[i]
    if v1 == nil then
      if v2 == nil then
        return 0
      end
      return -1
    end
    if v2 == nil then
      return 1
    end
    if v1 < v2 then
      return -1
    end
    if v1 > v2 then
      return 1
    end
    i = i + 1
  end
end

function M.is_in_range(s, e, x)
  return M.cmp(s, x) <= 0 and M.cmp(x, e) <= 0
end

return M
