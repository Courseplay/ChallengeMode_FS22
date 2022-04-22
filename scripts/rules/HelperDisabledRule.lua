---@class HelperDisabledRule : Rule
HelperDisabledRule = {}
local HelperDisabledRule_mt = Class(HelperDisabledRule, Rule)

function HelperDisabledRule.new(isServer, name, customMt)
	---@type HelperDisabledRule
	local self = Rule.new(isServer, name, customMt or HelperDisabledRule_mt)
	
	return self
end