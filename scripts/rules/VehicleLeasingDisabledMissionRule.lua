
---@class VehicleLeasingDisabledMissionRule : Rule
VehicleLeasingDisabledMissionRule = {}
local VehicleLeasingDisabledMissionRule_mt = Class(VehicleLeasingDisabledMissionRule, Rule)

function VehicleLeasingDisabledMissionRule.new(isServer, name, customMt)
	---@type VehicleLeasingDisabledMissionRule
	local self = Rule.new(isServer, name, customMt or VehicleLeasingDisabledMissionRule_mt)

	return self
end
