local move_cursor = require('flies.utils').move_cursor
local name = require('flies.utils').name
local to_pos = require('flies.utils').to_pos
local line_ending_pos = require('flies.utils').line_ending_pos
local select_line_range = require('flies.utils').select_line_range

local M = require('flies.objects.base').new()

-- FIXME: previous object when already on valid object
-- TODO: hijack komment.outer to komment.inner on move

function M.new(query, query2)
  return setmetatable({ query = query, query2 = query2 }, { __index = M })
end

function M:name()
  if self.query2 then
    return string.format('@%s @%s', self.query, self.query2)
  else
    return string.format('@%s inner/outer', self.query)
  end
end

function M:query_string(domain)
  if self.query2 then
    local q = domain == 'inner' and self.query or self.query2
    return '@' .. q
  else
    return string.format('@%s.%s', self.query, domain)
  end
end

for _, domain in ipairs { 'inner', 'outer' } do
  M[name('textobject', domain, 'plain')] = function(self, mode)
    print(self:query_string(domain))
    require('nvim-treesitter.textobjects.select').select_textobject(
      self:query_string(domain),
      mode
    )
  end
  M[name('move', domain, 'hint')] = function(self, _, _)
    require 'nvim-treesitter.textobjects.select'
    require('hop-extensions').hint_textobjects(
      string.format('%s.%s', self.query, domain)
    )
    -- TODO: start = false
  end
  for _, qualifier in ipairs { 'next', 'previous' } do
    M[name('move', domain, qualifier)] = function(self, start, _)
      local method = require('nvim-treesitter.textobjects.move')[name(
        'goto',
        qualifier,
        start and 'start' or 'end'
      )]
      for _ = 1, vim.v.count1 do
        method(self:query_string(domain))
      end
    end
  end
  for _, qualifier in ipairs { 'hint', 'next', 'previous' } do
    M[name('textobject', domain, qualifier)] = function(self, mode)
      M[name('move', domain, qualifier)](self, true, mode)
      M[name('textobject', domain, 'plain')](self, mode)
    end
  end
end

return M
