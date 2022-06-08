local M = require 'flies.util.object':new()

local t = require('flies.utils').t

M.operators_register = {}

M.op_xs = {}

-- interface: op(mode), query_n(), name

function M:op_n()
  local str = self:query_n()
  if not str then
    return
  end
  vim.cmd(
    'set operatorfunc=v:lua.package.loaded.flies.operators_register.'
      .. self.name
  )
  vim.api.nvim_feedkeys(t('g@' .. str), 'n', true)
end

function M:register()
  M.operators_register[self.name] = function()
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
      ':lua require "flies.operators.base".op_xs[%q]()<cr>',
      self.name
    ),
    { noremap = true }
  )
end

return M
