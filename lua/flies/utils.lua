local M = {}
local util = require 'flies.objects.utils'

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

-- https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/surround.lua
function M.get_marks_pos(mode)
  -- Region is inclusive on both ends
  local mark1, mark2
  if mode == 'x' then
    mark1, mark2 = '<', '>'
  else
    mark1, mark2 = '[', ']'
  end

  local pos1 = vim.api.nvim_buf_get_mark(0, mark1)
  local pos2 = vim.api.nvim_buf_get_mark(0, mark2)

  -- Tweak position in linewise mode as marks are placed on the first column
  local is_linewise = (mode == 'x' and vim.fn.visualmode() == 'V')
  if is_linewise then
    -- Move start mark past the indent
    pos1[2] = vim.fn.indent(pos1[1])
    -- Move end mark to the last character (` - 2` here because `col()` returns
    -- column right after the last 1-based column)
    pos2[2] = vim.fn.col { pos2[1], '$' } - 2
  end

  -- Make columns 1-based instead of 0-based. This is needed because
  -- `nvim_buf_get_mark()` returns the first 0-based byte of mark symbol and
  -- all the following operations are done with Lua's 1-based indexing.
  pos1[2], pos2[2] = pos1[2] + 1, pos2[2] + 1

  -- Tweak second position to respect multibyte characters. Reasoning:
  -- - These positions will be used with 'insert_into_line(line, col, text)' to
  --   add some text. Its logic is `line[1:(col - 1)] + text + line[col:]`,
  --   where slicing is meant on byte level.
  -- - For the first mark we want the first byte of symbol, then text will be
  --   insert to the left of the mark.
  -- - For the second mark we want last byte of symbol. To add surrounding to
  --   the right, use `pos2[2] + 1`.
  local line2 = vim.fn.getline(pos2[1])
  ---- This returns the last byte inside character because
  ---- `vim.str_byteindex()` 'rounds upwards to the end of that sequence'.
  pos2[2] = vim.str_byteindex(
    line2,
    -- Use `math.min()` because it might lead to 'index out of range' error
    -- when mark is positioned at the end of line (that extra space which is
    -- selected when selecting with `v$`)
    vim.str_utfindex(line2, math.min(#line2, pos2[2]))
  )

  return pos1, pos2
end

function M.query_obj()
  local qualifier
  local qualifier_char
  while true do
    local char = vim.fn.getchar()
    char = vim.fn.nr2char(char)
    local r = require('flies').qualifiers[char]
    if r then
      if qualifier then
        return
      end
      qualifier = r
      qualifier_char = char
    elseif char == M.t '<esc>' then
      return
    else
      return {
        query = require('flies').queries[char],
        query_char = char,
        qualifier = qualifier or 'plain',
        qualifier_char = qualifier_char,
      }
    end
  end
end

function M.set_cursor(pos)
  pos[2] = pos[2] - 1
  vim.api.nvim_win_set_cursor(0, pos)
end

function M.get_cursor()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  return init
end

function M.get_path(o, ...)
  for _, p in ipairs { ... } do
    o = o[p]
    if o == nil then
      return
    end
  end
  return o
end

function M.get_range_text(s, e)
  local start_row, start_col = unpack(s)
  start_row = start_row - 1
  local end_row, end_col = unpack(e)
  end_row = end_row - 1

  -- We have to remember that end_col is end-exclusive

  if start_row ~= end_row then
    local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
    lines[1] = string.sub(lines[1], start_col)
    -- end_row might be just after the last line. In this case the last line is not truncated.
    if #lines == end_row - start_row + 1 then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
    return lines
  else
    local line =
      vim.api.nvim_buf_get_lines(
        0,
        start_row,
        start_row + 1,
        false
      )[1]
    -- If line is nil then the line is empty
    return line and { string.sub(line, start_col, end_col) } or {}
  end
end

function M.to_lsp_range(s, e)
  local rtn = {}
  rtn.start = { line = s[1] - 1, character = s[2] - 1 }
  rtn['end'] = { line = e[1] - 1, character = e[2] }
  return rtn
end

function M.lsp_edit(ls, cs, le, ce, text)
  return {
    range = {
      start = { line = ls, character = cs },
      ['end'] = { line = le, character = ce },
    },
    newText = text,
  }
end

function M.strip0(os, is, ie, oe)
  is[2] = is[2] - 1
  ie[2] = ie[2] + 1

  local bufnr = vim.api.nvim_get_current_buf()

  local edits = {}
  if os[1] == is[1] then
    table.insert(edits, M.lsp_edit(os[1] - 1, os[2] - 1, is[1] - 1, is[2], ''))
  else
    table.insert(edits, M.lsp_edit(os[1] - 1, 0, is[1] - 1, 0, ''))
  end
  for r = os[1], ie[1] - 1 do
    table.insert(edits, M.lsp_edit(r, os[2] - 3, r, is[2], '.'))
  end
  table.insert(edits, M.lsp_edit(ie[1] - 1, ie[2] - 1, oe[1] - 1, oe[2], ''))
  vim.lsp.util.apply_text_edits(edits, bufnr, 'utf-8')
end

function M.strip1(os, is, ie, oe)
  is[2] = is[2] - 1
  ie[2] = ie[2] + 1

  local bufnr = vim.api.nvim_get_current_buf()

  local edits = {}
  if os[1] == is[1] then
    table.insert(edits, M.lsp_edit(os[1] - 1, os[2] - 1, is[1] - 1, is[2], ''))
  else
    table.insert(edits, M.lsp_edit(os[1] - 1, 0, is[1] - 1, 0, ''))
  end
  for r = os[1], ie[1] - 1 do
    table.insert(edits, M.lsp_edit(r, os[2] - 1, r, is[2], '.'))
  end
  table.insert(edits, M.lsp_edit(ie[1] - 1, ie[2] - 1, oe[1] - 1, oe[2], ''))
  vim.lsp.util.apply_text_edits(edits, bufnr, 'utf-8')
end

function M.strip2(os, is, ie, oe)
  is[2] = is[2] - 1
  ie[2] = ie[2] + 1

  local bufnr = vim.api.nvim_get_current_buf()

  local edits = {}
  if os[1] == is[1] then
    table.insert(edits, M.lsp_edit(os[1] - 1, os[2] - 1, is[1] - 1, is[2], ''))
  else
    table.insert(edits, M.lsp_edit(os[1] - 1, 0, is[1] - 1, 0, ''))
  end
  for r = os[1], ie[1] - 1 do
    table.insert(edits, M.lsp_edit(r, os[2] - 1, r, is[2], ''))
  end
  local str = util.get_row(oe[1])
  str = str:sub(oe[2] + 1)
  -- table.insert(edits, M.lsp_edit(ie[1] - 1, ie[2] - 1, oe[1] - 1, oe[2], ''))
  if str:len() > 0 then
    table.insert(edits, M.lsp_edit(ie[1] - 1, os[2] - 1, oe[1], oe[2], str))
  else
    local r = ie[1] - 1
    table.insert(edits, M.lsp_edit(r, os[2] - 1, r, is[2], ''))
    table.insert(edits, M.lsp_edit(ie[1] - 1, ie[2] - 1, oe[1] - 1, oe[2], ''))
  end
  vim.lsp.util.apply_text_edits(edits, bufnr, 'utf-8')
end

M.strip = M.strip1

function M.swap(s1, e1, s2, e2, cursor_to_second)
  local range1 = M.to_lsp_range(s1, e1)
  local range2 = M.to_lsp_range(s2, e2)

  local bufnr = vim.api.nvim_get_current_buf()
  local text1 = M.get_range_text(s1, e1)
  local text2 = M.get_range_text(s2, e2)

  local edit1 = { range = range1, newText = table.concat(text2, '\n') }
  local edit2 = { range = range2, newText = table.concat(text1, '\n') }
  vim.lsp.util.apply_text_edits({ edit1, edit2 }, bufnr, 'utf-8')

  if cursor_to_second then
    require('nvim-treesitter.utils').set_jump()

    local char_delta = 0
    local line_delta = 0
    if
      range1['end'].line < range2.start.line
      or (
        range1['end'].line == range2.start.line
        and range1['end'].character < range2.start.character
      )
    then
      line_delta = #text2 - #text1
    end

    if
      range1['end'].line == range2.start.line
      and range1['end'].character < range2.start.character
    then
      if line_delta ~= 0 then
        --- why?
        --correction_after_line_change =  -range2.start.character
        --text_now_before_range2 = #(text2[#text2])
        --space_between_ranges = range2.start.character - range1["end"].character
        --char_delta = correction_after_line_change + text_now_before_range2 + space_between_ranges
        --- Equivalent to:
        char_delta = #text2[#text2] - range1['end'].character

        -- add range1.start.character if last line of range1 (now text2) does not start at 0
        if range1.start.line == range2.start.line + line_delta then
          char_delta = char_delta + range1.start.character
        end
      else
        char_delta = #text2[#text2] - #text1[#text1]
      end
    end

    vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), {
      range2.start.line + 1 + line_delta,
      range2.start.character + char_delta,
    })
  end
end

return M
