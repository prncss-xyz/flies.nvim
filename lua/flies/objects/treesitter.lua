local name = require('flies.utils').name

local M = require('flies.objects.base').new()

-- FIXME: previous object when already on valid object
-- TODO: hijack komment.outer to komment.inner on move

function M.new(query, query2)
  local o = setmetatable({ query = query, query2 = query2 }, { __index = M })
  if o.query2 then
    o.name = string.format('@%s @%s', o.query, o.query2)
  else
    o.name = string.format('@%s', o.query)
  end
  return o
end

function M:query_string(domain)
  if self.query2 then
    local q = domain == 'inner' and self.query or self.query2
    return '@' .. q
  else
    return string.format('@%s.%s', self.query, domain)
  end
end

-- M:texobject_domain_qualifier(mode)
-- M:texobject_domain_np(qualifier, mode)

function M:textobject_outer_plain(mode)
  require('nvim-treesitter.textobjects.select').select_textobject(
    self:query_string 'outer',
    mode
  )
end

function M:textobject_inner_plain(mode)
  require('nvim-treesitter.textobjects.select').select_textobject(
    self:query_string 'inner',
    mode
  )
end

function M:textobject_outer_hint(mode)
  self:move('outer', 'hint', true, mode)
  self:textobject_outer_plain(mode)
end

function M:textobject_inner_hint(mode)
  self:move('inner', 'hint', true, mode)
  self:textobject_inner_plain(mode)
end

function M:textobject_outer_np(domain, mode)
  self:move('outer', domain, true, mode)
  self:textobject_inner_plain(mode)
end

function M:textobject_inner_np(domain, mode)
  self:move('inner', domain, true, mode)
  self:textobject_inner_plain(mode)
end

function M:move(domain, qualifier, start, _)
  if qualifier == 'hint' then
    require 'nvim-treesitter.textobjects.select'
    require('hop-extensions').hint_textobjects(
      string.format('%s.%s', self.query, domain)
      -- TODO: start = false
    )
  end
  if qualifier == 'next' or qualifier == 'previous' then
    local function method()
      require('nvim-treesitter.textobjects.move')[name(
        'goto',
        qualifier,
        start and 'start' or 'end'
      )](self:query_string(domain))
    end
    for _ = 1, vim.v.count1 do
      method()
    end
  end
end

return M
