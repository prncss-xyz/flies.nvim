local M = {}

local editor = require "flies.utils.editor"
local windows = require "flies.utils.windows"
local esc = editor.t "<esc>"
local async = require "plenary.async"

local value_to_type = {
	inner = "domain",
	outer = "domain",
	toggle = nil,
	left = "direction",
	right = "direction",
	first = "axis",
	last = "axis",
	hint = "axis",
	forward = "axis",
	backward = "axis",
}

local defaults = {
	domain = "inner",
	around = "solid",
	axis = "best",
}

---@alias domain "inner"|"outer"|"context"
---@alias direction "left"|"right"
---@alias around "never"|"around"|"always"
---@alias opts {domain: domain, axis: string, target: _Fly, hint_keep_first: boolean?, count: integer?, move: "left"|"right"|"opposite", external: boolean?, around: around }

---@param opts opts
---@param override table<string, any>
---@param is_move boolean
---@param cb fun(opts: opts)
---@return opts?
function M.ask(opts, override, is_move, cb)
	local mappings = require("flies").config.mappings
	opts = opts or {}
	override = override or {}
	local res = vim.tbl_extend("force", defaults, opts)
	local count_str = ""
	local cumul = ""
	local to_match = ""
	while not res.target do
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == esc then return end
		cumul = cumul .. char
		if override[cumul] then
			res = vim.tbl_extend("force", defaults, opts)
			override[cumul](res)
			return
		end
		if char:match "%d" then
			count_str = count_str .. char
		else
			to_match = to_match .. char
			local value = mappings[to_match]
			if value then
				to_match = ""
				if value == "toggle" then
					res.domain = res.domain == "inner" and "outer" or "inner"
				else
					local type_ = value_to_type[value] or "target"
					if type_ == "direction" then type_ = is_move and "move" or "domain" end
					res[type_] = value
				end
			elseif char:match "%p" then
				res.target = require("flies.flies._char_to"):new {
					patterns = { require("flies.utils").pattern_escape(char, false) },
				}
			end
		end
	end

	if
		res.axis == "hint"
		and res.target:is_instance(require "flies.flies.char_to_any")
	then
		res.target = require "flies.flies.char_to_2"
	end

	local target = res.target
	target:ask(function()
		local count = tonumber(count_str)
		if count then res.count = count end
		if res.axis == "hint" then
			local pos = windows.get_cursor()
			local targets = target:get_hints(pos, opts)
			if targets[1] then
				return require("flies.utils.hint").hint(targets, function(match_)
					res.match = match_
					return cb(res)
				end)
			else
				return
			end
		end
		cb(res)
	end)
end

return M
