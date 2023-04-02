local assert = require "luassert"
local say = require "say"
local tables = require "flies.utils.tables"

local function is_greater(state, arguments) return arguments[1] > arguments[2] end
say:set("assertion.is_greater.positive", "Expected %s\n to be greater than: %s")
assert:register(
	"assertion",
	"is_greater",
	is_greater,
	"assertion.is_greater.positive"
)

local function is_smaller(state, arguments) return arguments[1] < arguments[2] end
say:set("assertion.is_smaller.positive", "Expected %s\n to be smaller than: %s")
assert:register(
	"assertion",
	"is_smaller",
	is_smaller,
	"assertion.is_smaller.positive"
)

local function is_nil(state, arguments) return arguments[1] == nil end
say:set("assertion.is_nil.positive", "Expected %s\n to be nil")
assert:register("assertion", "is_nil", is_nil, "assertion.is_nil.positive")

local function contains(state, arguments)
	return tables.contains(arguments[1], arguments[2])
end
say:set("assertion.containts.positive", "Expected %s\n to contain %s")
assert:register(
	"assertion",
	"contains",
	contains,
	"assertion.contains.positive"
)
