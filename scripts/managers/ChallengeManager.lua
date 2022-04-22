
---@class ChallengeManager : Manager
ChallengeManager = {
	modName = g_currentModName,
	modDir = g_currentModDirectory,
	challengeTypesFilePath = "config/ChallengeTypes",
}
ChallengeManager.setupXmlRootKey = "ChallengeManager"
ChallengeManager.baseSetupXmlKey = ChallengeManager.setupXmlRootKey .. ".Challenges"

ChallengeManager.xmlRootKey = "ChallengeManagers(?)"
ChallengeManager.baseXmlKey = ChallengeManager.xmlRootKey .. "ChallengeManager"


local ChallengeManager_mt = Class(ChallengeManager, Manager)

function ChallengeManager.registerXmlSetupSchema()
	ChallengeManager.xmlSetupSchema = XMLSchema.new("challengeManagerSetupXmlSchema")
	Challenge.registerXmlSetupSchema(ChallengeManager.xmlSetupSchema, ChallengeManager.baseSetupXmlKey .. "(?)")
end

function ChallengeManager.registerXmlSchema(schema, baseKey)
	Challenge.registerXmlSchema(schema, baseKey .. ChallengeManager.baseXmlKey .. "(?)")
end

function ChallengeManager.new(isServer, user, customMt)
	---@type ChallengeManager
	local self = Manager.new(isServer, user, customMt or ChallengeManager_mt)
	
	self.challenges = {}
	self.challengesByName = {}
	return self
end

function ChallengeManager:loadChallengeTypes()
	local filePath = Utils.getFilename(self.challengeTypesFilePath, self.modDir)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filePath, self.xmlSetupSchema)
	if xmlFile then 
		xmlFile:iterate(self.baseSetupXmlKey,function (ix, key)
			local challenge = Challenge.createFromSetup(xmlFile, key)
			table.insert(self.challenges, challenge)
			self.challengesByName[challenge:getName()] = challenge
		end)
		xmlFile:delete()
	else 
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end
end

function ChallengeManager:writeStream(streamId, connection)
	Manager.writeStream(self, streamId, connection, self.challenges)
end

function ChallengeManager:readStream(streamId, connection)
	Manager.readStream(self, streamId, connection, self.challenges)
end

function ChallengeManager:saveToXml(xmlFile, baseKey)
	Manager.saveToXml(self, xmlFile, baseKey, self.challenges)
end

function ChallengeManager:loadFromXml(xmlFile, baseKey)
	Manager.loadFromXml(self, xmlFile, baseKey, self.challenges)
end

