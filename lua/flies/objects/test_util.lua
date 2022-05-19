local M = {}

-- Utility used for testing

-- https://github.com/siffiejoe/lua-finally/blob/master/finally.lua

local pcall, error = pcall, error

local function _finally(after, ok, ...)
  if ok then
    after()
    return ...
  else
    after((...))
    error((...), 0)
  end
end

local function finally(main, after)
  return _finally(after, pcall(main))
end

-- move(self, domain, qualifier, start, mode)

local mock_utils = setmetatable({}, { __index = require 'flies.objects.utils' })
local fake_buf
function mock_utils.row_forward_iterator(start)
  return function(max, row)
    row = row + 1
    if row > max then
      return
    end
    return row, fake_buf[row]
  end,
    #fake_buf,
    start and start - 1 or 0
end

function mock_utils.row_backward_iterator(start)
  return function(_, row)
    row = row - 1
    if row == 0 then
      return
    end
    return row, fake_buf[row]
  end,
    nil,
    start and start + 1 or #fake_buf + 1
end

function mock_utils.get_row(row)
  return fake_buf[row]
end

function M.with_fake_buf(buf, cb)
  fake_buf = buf
  package.loaded['flies.objects.utils'] = mock_utils
  finally(function()
    cb()
  end, function()
    package.loaded['flies.objects.utils'] = nil
  end)
end

function M.iter_to_list(f, state, i)
  local res = {}
  local s, e
  while i ~= nil do
    i, s, e = f(state, i)
    if i then
      res[i] = { s, e }
    end
  end
  return res
end

return M
