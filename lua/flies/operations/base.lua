local M = {}

local t = require('flies.utils').t

M.reg = {}

M.op_xs = {}

-- interface: op(mode), query_n(), name

function M.new(o)
  o = o or {}
  return setmetatable(o, { __index = M })
end

function M:op_n()
  local str = self:query_n()
  if not str then
    return
  end
  vim.cmd(
    'set operatorfunc=v:lua.package.loaded.flies.operations_register.'
      .. self.name
  )
  vim.api.nvim_feedkeys(t('g@' .. str), 'n', true)
end

function M:register()
  M.reg[self.name] = function()
    self:op 'o'
  end
  vim.keymap.set('n', string.format('<Plug>(flies-%s)', self.name), function()
    self:op_n()
  end, { desc = self.name })
  M.op_xs[self.name] = function()
    self:op 'x'
  end
  vim.api.nvim_set_keymap(
    'x',
    string.format('<Plug>(flies-%s)', self.name),
    string.format(
      ':lua require "flies.operations.base".op_xs[%q]()<cr>',
      self.name
    ),
    { noremap = true }
  )
end

return M
