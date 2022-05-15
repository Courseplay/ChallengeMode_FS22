
RuleManager = {
	RULES = {
		HELPER_LIMIT = 1,
		LEASE_VEHICLES = 2,
	},
	LEASE_VEHICLES = {
		DISABLED = 0,
		ONLY_SHOP_VEHICLES = 1,
		ENABLED = 2
	}
}
local RuleManager_mt = Class(RuleManager)
---@class RuleManager
function RuleManager.new(custom_mt)
	local self = setmetatable({}, custom_mt or RuleManager_mt)
	self.isServer = g_server
		
	self.rules = {}
	self.missionRules = {}

	self.missionTypes = {}
	self.missionTypesEnabled = {}
	for i, missionType in pairs(g_missionManager.missionTypes) do 
		self.missionTypes[missionType.name] = missionType
		self.missionTypesEnabled[missionType.name] = true
	end
	self.translations = ScoreBoardFrame.translations
	return self
end


function RuleManager:registerXmlSchema(xmlSchema, baseXmlKey)
	local baseKey = baseXmlKey .. ".Rules"
	xmlSchema:register(XMLValueType.INT, baseKey..".helperLimit", "Helper limit")
	xmlSchema:register(XMLValueType.INT, baseKey..".leaseVehicles", "Vehicle leasing allowed.")
	xmlSchema:register(XMLValueType.STRING, baseKey..".missions.mission(?)#name", "Mission name")
	xmlSchema:register(XMLValueType.BOOL, baseKey..".missions.mission(?)", "Mission disabled.")
end

function RuleManager:loadConfigData(xmlFile, baseXmlKey)
	local baseKey = baseXmlKey .. ".Rules"
	self.helperLimit = xmlFile:getValue(baseKey..".helperLimit", g_currentMission.maxNumHirables)
	self.leaseVehicles = xmlFile:getValue(baseKey..".leaseVehicles", self.LEASE_VEHICLES.ENABLED)


	xmlFile:iterate(baseKey .. ".missions.mission", function (i, key)
		local name = xmlFile:getValue(key.."#name")	
		CmUtil.debug("Trying to find mission type: %s", name)
		if name and self.missionTypes[name] then 
			local value = xmlFile:getValue(key, true)
			self.missionTypesEnabled[name] = value
		end			
	end)	

	self.rules = {
		Rule.new(self.helperLimit, self.translations.rules[self.RULES.HELPER_LIMIT]),
		Rule.new(self.leaseVehicles, self.translations.rules[self.RULES.LEASE_VEHICLES], self.translations.leaseVehicleRule)
	}
	for name, value in pairs(self.missionTypesEnabled) do 
		table.insert(self.missionRules,Rule.new(value, name, self.translations.missionRule))
	end

end

function RuleManager:saveConfigData(xmlFile, baseXmlKey)
	local baseKey = baseXmlKey .. ".Rules"
	xmlFile:setValue(baseKey..".helperLimit", self.helperLimit)
	xmlFile:setValue(baseKey..".leaseVehicles", self.leaseVehicles)

	local ix, key = 0, ""
	for name, value in pairs(self.missionTypesEnabled) do 
		key = string.format("%s.missions.mission(%d)", baseKey, ix)
		xmlFile:setValue(key.."#name", name)
		xmlFile:setValue(key, value)
		ix = ix + 1
	end
end

function RuleManager:getRules()
	return self.rules
end

function RuleManager:getMissionRules()
	return self.missionRules
end

g_ruleManager = RuleManager.new()
--missionTypes