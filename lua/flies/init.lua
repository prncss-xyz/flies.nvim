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
	local qualifier
	while true do
		local char = vim.fn.getchar()
		char = vim.fn.nr2char(char)
		if not qualifier and qualifiers[char] then
			qualifier = qualifiers[char]
		elseif queries[char] then
			qualifier = qualifier or qualifiers[""]
			if qualifier then
				M.cache = { query = queries[char], qualifier = qualifier }
				return true
			else
				return false
			end
		else
			return false
		end
	end
end

function M.move(domain, start, mode)
	local name = require("flies").utils.name
	if not query_obj() then
		return
	end
	local query = M.cache.query
	if domain == "plain" then
		domain = "next"
	end
	local command_name = name("move", M.cache.qualifier)
	if not query[command_name] then
		return
	end
	local prev = name("move", domain, "previous")
	if query[prev] then
		local next = name("move", domain, "next")
		M.repeat_register(function(mode0)
			query[prev](query, start, mode0)
		end, function(mode0)
			query[next](query, start, mode0)
		end)
	end
	query[command_name](query, start, mode)
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
end

return M
