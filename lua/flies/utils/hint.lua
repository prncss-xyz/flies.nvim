local M = {}

---@alias target {s?: integer[], e?: integer[], match: match}

local DIM_PRIO = 65533
local HINT_PRIO = 65534
local CURSOR_PRIO = 65535

local hl_ns = vim.api.nvim_create_namespace "flies_hint_hl"
local dim_ns = vim.api.nvim_create_namespace "flies_hint_dim"

--- define default highlight groups used by hints
function M.set_highlights()
	local set_hl = function(name, val)
		val.default = true
		vim.api.nvim_set_hl(0, name, val)
	end
	set_hl(
		"FliesHintNextKey",
		{ fg = "#ff007c", bold = true, ctermfg = 198, cterm = { bold = true } }
	)
	set_hl(
		"FliesHintNextKey1",
		{ fg = "#00dfff", bold = true, ctermfg = 45, cterm = { bold = true } }
	)
	set_hl("FliesHintNextKey2", { fg = "#2b8db3", ctermfg = 33 })
	set_hl("FliesHintUnmatched", { fg = "#666666", sp = "#666666", ctermfg = 242 })
	set_hl("FliesHintCursor", { link = "Cursor" })
end

local function clear(buf)
	if not vim.api.nvim_buf_is_valid(buf) then return end
	vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
	vim.api.nvim_buf_clear_namespace(buf, dim_ns, 0, -1)
end

local function add_virt_cur(state)
	local cur_info = vim.fn.getcurpos()
	local cur_row = cur_info[2] - 1
	local cur_col = cur_info[3] - 1
	local cur_offset = cur_info[4]
	local virt_col = cur_info[5] - 1
	local cur_line = vim.api.nvim_get_current_line()

	if state.cursorline then vim.wo[state.win].cursorline = false end

	if cur_offset ~= 0 then
		vim.api.nvim_buf_set_extmark(state.buf, hl_ns, cur_row, cur_col, {
			virt_text = { { "█", "Normal" } },
			virt_text_win_col = virt_col,
			priority = CURSOR_PRIO,
		})
	elseif #cur_line == cur_col then
		vim.api.nvim_buf_set_extmark(state.buf, hl_ns, cur_row, cur_col, {
			virt_text = { { "█", "Normal" } },
			virt_text_pos = "overlay",
			priority = CURSOR_PRIO,
		})
	else
		vim.api.nvim_buf_set_extmark(state.buf, hl_ns, cur_row, cur_col, {
			end_col = vim.fn.byteidx(cur_line, vim.fn.charidx(cur_line, cur_col) + 1),
			hl_group = "FliesHintCursor",
			priority = CURSOR_PRIO,
		})
	end
end

local function apply_dimming(state)
	local info = vim.fn.getwininfo(state.win)[1]
	vim.api.nvim_buf_set_extmark(state.buf, dim_ns, info.topline - 1, 0, {
		end_line = info.botline,
		hl_group = "FliesHintUnmatched",
		hl_eol = true,
		priority = DIM_PRIO,
	})
	for ns in pairs(state.diag_ns) do
		vim.diagnostic.show(ns, state.buf, nil, { virtual_text = false })
	end
end

local function set_hint_extmarks(state, hints)
	for _, hint in ipairs(hints) do
		local label = hint.label
		local virt_text
		if vim.fn.strdisplaywidth(label) == 1 then
			virt_text = { { label, "FliesHintNextKey" } }
		else
			local snd_idx = vim.fn.byteidx(label, 1)
			virt_text = {
				{ label:sub(1, snd_idx), "FliesHintNextKey1" },
				{ label:sub(snd_idx + 1), "FliesHintNextKey2" },
			}
		end
		vim.api.nvim_buf_set_extmark(state.buf, hl_ns, hint.line, hint.column - 1, {
			virt_text = virt_text,
			virt_text_pos = "overlay",
			hl_mode = "combine",
			priority = HINT_PRIO,
		})
	end
end

local function quit(state)
	clear(state.buf)
	if state.cursorline then vim.wo[state.win].cursorline = true end
	if vim.api.nvim_buf_is_valid(state.buf) then
		for ns in pairs(state.diag_ns) do
			vim.diagnostic.show(ns, state.buf)
		end
	end
end

local function reduce_hints(hints, key)
	local next_hints = {}
	for _, h in ipairs(hints) do
		local snd_idx = vim.fn.byteidx(h.label, 1)
		if h.label:sub(1, snd_idx) == key then
			h.label = h.label:sub(snd_idx + 1)
			if h.label == "" then return h end
			next_hints[#next_hints + 1] = h
		end
	end
	return nil, next_hints
end

local function err(msg) vim.api.nvim_echo({ { msg, "Error" } }, true, {}) end

--- select amongst targets by hinting, call a function with result
---@generic M
---@param targets {s?: integer[], e?: integer[], match: M}[]
---@param cb fun(match: M)
function M.hint(targets, cb)
	if not targets then return end
	local config = require("flies").config.hints

	local candidates = {}
	for _, target in ipairs(targets) do
		local point = target.s or target.e
		if point then
			candidates[#candidates + 1] = {
				line = point[1] - 1,
				column = point[2],
				match = target.match,
			}
		end
	end

	local target_idx
	if #candidates == 0 then
		target_idx = 0
	elseif vim.v.count > 0 then
		target_idx = vim.v.count
	elseif #candidates == 1 and config.jump_on_sole_occurrence then
		target_idx = 1
	end
	if target_idx then
		local candidate = candidates[target_idx]
		if candidate then
			cb(candidate.match)
		else
			err " -> there’s no such thing we can see…"
		end
		return
	end

	local win = vim.api.nvim_get_current_win()
	local state = {
		win = win,
		buf = vim.api.nvim_win_get_buf(win),
		diag_ns = vim.diagnostic.get_namespaces(),
		cursorline = vim.wo[win].cursorline,
	}

	local labels =
		require("flies.utils.perm").permutations(config.keys, #candidates)
	local hints = {}
	for i, candidate in ipairs(candidates) do
		hints[i] = {
			label = labels[i],
			line = candidate.line,
			column = candidate.column,
			match = candidate.match,
		}
	end

	apply_dimming(state)
	add_virt_cur(state)
	set_hint_extmarks(state, hints)
	vim.cmd.redraw()

	local quit_key = vim.keycode "<Esc>"
	while true do
		local ok, key = pcall(vim.fn.getchar)
		if not ok then
			quit(state)
			return
		end
		local special = false
		if type(key) == "number" then
			key = vim.fn.nr2char(key)
		elseif key:byte() == 128 then
			special = true
		end

		if special or not config.keys:find(key, 1, true) then
			quit(state)
			if key ~= quit_key then vim.api.nvim_feedkeys(key, "", true) end
			return
		end

		local h, next_hints = reduce_hints(hints, key)
		if h then
			quit(state)
			vim.cmd "normal! m'"
			cb(h.match)
			return
		end
		if #next_hints == 0 then
			err("no remaining sequence starts with " .. key)
		else
			hints = next_hints
			vim.api.nvim_buf_clear_namespace(state.buf, hl_ns, 0, -1)
			set_hint_extmarks(state, hints)
		end
		vim.cmd.redraw()
	end
end

return M
