---@class Word: _Subline
local M = require("flies.flies._subline"):new {}

M.solid = true

--[[
To generate the pattern, run the following script:

local pattern = ""
for i = 0, 127 do
	local c = string.char(i)
	if c:match "%p" and c ~= "_" then pattern = pattern .. "%" .. c end
end
pattern = "[^%s" .. pattern .. "]+"
print(string.format("%q", pattern))

--]]

M.patterns =
	{ "[^%s%!%\"%#%$%%%&%'%(%)%*%+%,%-%.%/%:%;%<%=%>%?%@%[%\\%]%^%`%{%|%}%~]+" }

return M
