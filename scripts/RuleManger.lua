
RuleManager = {
	MISSION_TITLES = {
		cultivate = "fieldJob_jobType_cultivating",
		mow_bale = "fieldJob_jobType_baling",
		plow = "fieldJob_jobType_plowing",
		spray = "fieldJob_jobType_spraying",
		sow = "fieldJob_jobType_sowing",
		weed = "fieldJob_jobType_weeding",
		harvest = "fieldJob_jobType_harvesting",
		fertilize = "fieldJob_jobType_fertilizing",
		transport = "fieldJob_jobType_transporting"
	}
}
HusbandrySystem.GAME_LIMIT = 1000

local RuleManager_mt = Class(RuleManager)
---@class RuleManager
function RuleManager.new(custom_mt)
	local self = setmetatable({}, custom_mt or RuleManager_mt)
	self.isServer = g_server
		
	self.ruleList = {}

	self.missionTypes = {}
	for i, missionType in pairs(g_missionManager.missionTypes) do 
		self.missionTypes[missionType.name] = missionType
	end

	return self
end


function RuleManager:registerXmlSchema(xmlSchema, baseXmlKey)
	ScoreBoardList.registerXmlSchema(xmlSchema, baseXmlKey .. ".Rules")
end

function RuleManager:registerConfigXmlSchema(xmlSchema, baseXmlKey)
	CmUtil.registerConfigXmlSchema(xmlSchema, baseXmlKey .. ".Rules")
end

function RuleManager:loadConfigData(xmlFile, baseXmlKey)
		
	self.configData, self.titles = CmUtil.loadConfigCategories(xmlFile, baseXmlKey .. ".Rules")

	self.ruleList = ScoreBoardList.new("rules", self.titles)
	for _, categoryData in pairs(self.configData) do 
		local category = ScoreBoardCategory.new(categoryData.name, categoryData.title)
		for _, rule in pairs(categoryData.elements) do 
			if rule.genericFunc == nil then
				category:addElement(Rule.createFromXml(rule))
			else 
				self[rule.genericFunc](self, category, rule)
			end
		end
		self.ruleList:addElement(category)
	end

	g_currentMission.getHasPlayerPermission = Utils.overwrittenFunction(g_currentMission.getHasPlayerPermission, Rule.getCanStartHelper)

	g_currentMission.maxNumHirables = 1000
end

function RuleManager:saveToXMLFile(xmlFile, baseXmlKey)
	self.ruleList:saveToXMLFile(xmlFile, baseXmlKey .. ".Rules", 0)
end

function RuleManager:loadFromXMLFile(xmlFile, baseXmlKey)
	ScoreBoardList.loadFromXMLFile(self, xmlFile, baseXmlKey .. ".Rules")
end

function RuleManager:writeStream(streamId, connection)
	self.ruleList:writeStream(streamId)
end

function RuleManager:readStream(streamId, connection)
	self.ruleList:readStream(streamId)
end

function RuleManager:addMissionRules(category, ruleData)
	local missionNames = table.toList(self.missionTypes)
	table.sort(missionNames)
	for _, name in ipairs(missionNames) do 
		ruleData.name = name
		ruleData.title = g_i18n:getText(self.MISSION_TITLES[name])
		category:addElement(Rule.createFromXml(ruleData))
	end
end

function RuleManager:addAnimalHusbandryLimitRules(category, ruleData)
	local types = {}
	for i, type in pairs(g_currentMission.animalSystem:getTypes()) do 
		table.insert(types, type)
	end
	table.sort(types, function (a, b)
		local aName = "fillType_"..string.lower(a.name)
		local bName = "fillType_"..string.lower(b.name)
		return g_i18n:getText(aName) < g_i18n:getText(bName)
	end)
	for _, type in ipairs(types) do 
		ruleData.name = type.name
		ruleData.title = g_i18n:getText("fillType_"..string.lower(type.name))
		category:addElement(Rule.createFromXml(ruleData))
	end
end

function RuleManager:isMissionAllowed(mission)
	for _,missionRule in pairs(self:getMissionRules()) do 
		if missionRule:getValue() == Rule.MISSION_DEACTIVATED then 
			local missionType = self.missionTypes[missionRule:getName()]
			if mission.type == missionType then 
				return false
			end
		end
	end
	return true
end

function RuleManager:getList()
	return self.ruleList
end

function RuleManager:getListByName()
	return self.ruleList
end

function RuleManager:getGeneralRuleValue(name)
	return self.ruleList:getElementByName("general", name):getValue()
end

function RuleManager:getMissionRules()
	return self.ruleList:getElementByName("missions"):getElements()
end

function RuleManager:getAnimalHusbandryLimitByName(name)
	return self.ruleList:getElementByName("animalHusbandryLimits"):getElementByName(name)
end

g_ruleManager = RuleManager.new()
--missionTypes