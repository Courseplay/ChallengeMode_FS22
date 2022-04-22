---@class VehicleLeasingDisabledRule : Rule
VehicleLeasingDisabledRule = {}
local VehicleLeasingDisabledRule_mt = Class(VehicleLeasingDisabledRule, Rule)

function VehicleLeasingDisabledRule.new(isServer, name, customMt)
	---@type VehicleLeasingDisabledRule
	local self = Rule.new(isServer, name, customMt or VehicleLeasingDisabledRule_mt)
	
	return self
end