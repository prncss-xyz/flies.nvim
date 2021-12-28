local M = {}

local conf
local queries
local qualifiers

local rep = {
	previous = function(_) end,
	next = function(_) end,
}

function M.repeat_register(previous, next)
	rep.previous = previous
	rep.next = next
end

function M.repeat_previous(mode)
	if rep.previous then
		rep.previous(mode)
	end
end

function M.repeat_next(mode)
	if rep.next then
		rep.next(mode)
	end
end

function M.textobject(command_name, query_map, mode)
	local t = require("flies.utils").t
	local query = queries[t(query_map)]
	query[command_name](query, mode)
end

local function query_obj()
	local t = require("flies.utils").t
	local qualifier
	while true do
		local char = vim.fn.getchar()
		char = vim.fn.nr2char(char)
		if char == t("<esc>") then
			return nil
		end
		if not qualifier and qualifiers[char] then
			qualifier = qualifiers[char]
		else
			qualifier = qualifier or qualifiers[""]
			if qualifier then
				return qualifier, char
			else
				return nil
			end
		end
	end
end

local function jump(target, backward, till, n_times)
	local flags = backward and "Wb" or "W"
	if till then
		if backward then
			target = target .. "."
		else
			target = "." .. target
		end
	end
	if backward and till then
		flags = flags .. "e"
	end

	for _ = 1, n_times do
		vim.fn.search(target, flags)
	end

	-- Open enough folds to show jump
	vim.cmd("normal! zv")
end

function M.move(query_char, qualifier, domain, start, mode)
	local name = require("flies.utils").name
	local query = queries[query_char]
	if query then
		local command_name = name("move", domain, qualifier)
		if query[command_name] then
			query[command_name](query, start, mode)
			return
		end
		domain = domain == "inner" and "outer" or "inner"
		command_name = name("move", domain, qualifier)
		if query[command_name] then
			query[command_name](query, start, mode)
			return
		end
		return
	end
	jump("[" .. query_char .. "]", qualifier == "previous", domain == "inner", vim.v.count1)
end

function M.mapped_move(domain, start, mode)
	local qualifier, char = query_obj()
	if not qualifier then
		return
	end
	M.repeat_register(function(mode0)
		M.move(char, "previous", domain, start, mode0)
	end, function(mode0)
		M.move(char, "next", domain, start, mode0)
	end)
	if qualifier == "plain" then
		qualifier = "next"
	end
	M.move(char, qualifier, domain, start, mode)
end

local function map_move()
	if conf.maps then
		for lhs, v in pairs(conf.maps) do
			for _, mode in ipairs({ "n", "x", "o" }) do
				vim.api.nvim_set_keymap(
					mode,
					lhs,
					string.format(
						'<cmd>lua require"flies".mapped_move(%q, %s, %q)<cr>',
						v.domain,
						v.start and 'true' or 'false',
						mode
					),
					{}
				)
			end
		end
	end
end

local function map_texobjects()
	local name = require("flies.utils").name
	local t = require("flies.utils").t
	for domain_map, domain in pairs(conf.textobjects) do
		for mode in string.gmatch("ox", ".") do
			for qualifier_map, qualifier in pairs(conf.qualifiers) do
				for query_map, query in pairs(conf.queries) do
					local command_name = name("textobject", domain, qualifier)
					if query[command_name] then
						vim.api.nvim_set_keymap(
							mode,
							domain_map .. qualifier_map .. query_map,
							string.format(
								':lua require("flies").textobject(%q, %q, %q)<cr>',
								command_name,
								t(query_map),
								mode
							),
							{ noremap = true }
						)
					end
				end
			end
		end
	end
end

function M.setup(user_conf)
	local t = require("flies.utils").t
	conf = user_conf
	queries = {}
	for k, v in pairs(conf.queries) do
		queries[t(k)] = v
	end
	qualifiers = {}
	for k, v in pairs(conf.qualifiers) do
		qualifiers[t(k)] = v
	end
	map_texobjects()
  map_move()
end

return M
