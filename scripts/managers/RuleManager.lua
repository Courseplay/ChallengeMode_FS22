
---@class RuleManager : Manager
RuleManager = {
	modName = g_currentModName,
	modDir = g_currentModDirectory,
	challengeTypesFilePath = "config/ChallengeTypes"
}
RuleManager.xmlRootKey = "RuleManager"
RuleManager.baseKey = RuleManager.xmlRootKey .. "Rules"

local RuleManager_mt = Class(RuleManager, Manager)

function RuleManager.registerXmlSetupSchema()
	RuleManager.xmlSetupSchema = XMLSchema.new("RuleManagerSetupXmlSchema")
	Rule.registerXmlSetupSchema(RuleManager.xmlSetupSchema, RuleManager.baseKey .. "(?)")
end

function RuleManager.registerXmlSchema(schema, baseKey)
	Rule.registerXmlSchema(schema, baseKey .. RuleManager.baseKey .. "(?)")
end

function RuleManager.new(isServer, user, customMt)
	---@type RuleManager
	local self = Manager.new(isServer, user, customMt or RuleManager_mt)
	
	self.rules = {}
	self.rulesByName = {}
	return self
end

function RuleManager:loadRuleTypes()
	local filePath = Utils.getFilename(self.challengeTypesFilePath, self.modDir)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filePath, self.xmlSetupSchema)
	if xmlFile then 
		xmlFile:iterate(self.baseKey, function (ix, key)
			local rule = Rule.createFromSetup(xmlFile, key)
			table.insert(self.rules, rule)
			self.rulesByName[rule:getName()] = rule
		end)

		xmlFile:delete()
	else 
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end
end

function RuleManager:addChallenge()
	
end

function RuleManager:writeStream(streamId, connection)
	Manager.writeStream(self, streamId, connection, self.rules)
end

function RuleManager:readStream(streamId, connection)
	Manager.readStream(self, streamId, connection, self.rules)
end

function RuleManager:saveToXml(xmlFile, baseKey)
	Manager.saveToXml(self, xmlFile, baseKey, self.rules)
end

function RuleManager:loadFromXml(xmlFile, baseKey)
	Manager.loadFromXml(self, xmlFile, baseKey, self.rules)
end

