---@class ChallengeMod
ChallengeMod = {
	MOD_NAME = g_currentModName,
	BASE_DIRECTORY = g_currentModDirectory,
	baseXmlKey = "ChallengeMod",
	configFileName = "ChallengeModConfig.xml",
}

ChallengeMod.image = {
	path = Utils.getFilename('Icon_ChallengeMode.dds', ChallengeMod.BASE_DIRECTORY),
	--uvs = {0, 0,1,1}
}


local ChallengeMod_mt = Class(ChallengeMod)

function ChallengeMod.new(custom_mt)
	local self = setmetatable({}, custom_mt or ChallengeMod_mt)
	self.isServer = g_server

	addConsoleCommand('CmGenerateContracts', 'Generates new contracts', 'generateContracts', self)

	return self
end

function ChallengeMod:generateContracts()
	g_missionManager:generateMissions()
end

function ChallengeMod:changeAdminPassword(newPassword)
	if newPassword ~= nil then
		self.adminPassword = newPassword
		ChangeAdminPasswordEvent.sendEvent(newPassword)
	end
end

function ChallengeMod:getAdminPassword()
	return self.adminPassword
end

function ChallengeMod:getDefaultAdminPassword()
	return self.defaultAdminPassword
end

function ChallengeMod:loadMap()
	self:setup()
end

function ChallengeMod:setup()
	self:registerXmlSchema()

	self.configFilePath = Utils.getFilename(self.configFileName, self.BASE_DIRECTORY)

	self:loadConfigData(self.configFilePath)

	self:loadFromSaveGame()

	self:setupGui()
end

function ChallengeMod:setupGui()
	local frame = ScoreBoardFrame.new()
	g_gui:loadGui(Utils.getFilename("gui/ScoreBoardFrame.xml", self.BASE_DIRECTORY),
				 "ScoreBoardPage", frame, true)

	CmUtil.fixInGameMenuPage(frame, "pageScoreBoard", 
			self.image)
end


function ChallengeMod:registerXmlSchema()
    self.xmlSchema = XMLSchema.new("ChallengeMod")
	self.xmlSchema:register(XMLValueType.STRING, self.baseXmlKey .. "#password", "Admin password")
	g_victoryPointManager:registerXmlSchema(self.xmlSchema, self.baseXmlKey)
	g_ruleManager:registerXmlSchema(self.xmlSchema, self.baseXmlKey)

    self.xmlConfigSchema = XMLSchema.new("ChallengeMod")
	self.xmlConfigSchema:register(XMLValueType.STRING, self.baseXmlKey .. "#defaultPassword", "Admin password", "")
	g_victoryPointManager:registerConfigXmlSchema(self.xmlConfigSchema, self.baseXmlKey)
	g_ruleManager:registerConfigXmlSchema(self.xmlConfigSchema, self.baseXmlKey)
end

function ChallengeMod:loadConfigData(filename)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filename,  self.xmlConfigSchema)
	if xmlFile then 
		CmUtil.debug("Challenge setup loaded from %s.", filename)
		self.adminPassword = xmlFile:getValue(self.baseXmlKey.."#defaultPassword")
		self.defaultAdminPassword = self.adminPassword
		g_victoryPointManager:loadConfigData(xmlFile, self.baseXmlKey)
		g_ruleManager:loadConfigData(xmlFile, self.baseXmlKey)
		xmlFile:delete()
		return true
	else
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end
end

function ChallengeMod:saveToXMLFile(filename)
	local xmlFile = XMLFile.create("xmlFile", filename, self.baseXmlKey, self.xmlSchema)
	if xmlFile then 
		CmUtil.debug("Challenge setup saved to %s.", filename)
		xmlFile:setValue(self.baseXmlKey .. "#password", self.adminPassword)
		g_victoryPointManager:saveToXMLFile(xmlFile, self.baseXmlKey)
		g_ruleManager:saveToXMLFile(xmlFile, self.baseXmlKey)
		xmlFile:save()
		xmlFile:delete()
	else
		CmUtil.debug("Challenge setup xml could not be created.")
	end
end

function ChallengeMod:loadFromXMLFile(filename)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filename, self.xmlSchema)
	if xmlFile then 
		CmUtil.debug("Challenge setup loaded from %s.", filename)
		self.adminPassword = xmlFile:getValue(self.baseXmlKey .."#password", self.adminPassword)
		g_victoryPointManager:loadFromXMLFile(xmlFile, self.baseXmlKey)
		g_ruleManager:loadFromXMLFile(xmlFile, self.baseXmlKey)
		xmlFile:delete()
		return true
	else
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end
end

function ChallengeMod:writeStream(streamId, connection)
	streamWriteString(streamId, self.adminPassword)
	g_victoryPointManager:writeStream(streamId, connection)
	g_victoryPointManager:writeStream(streamId, connection)
end

function ChallengeMod:readStream(streamId, connection)
	self.adminPassword = streamReadString(streamId)
	g_victoryPointManager:readStream(streamId, connection)
	g_victoryPointManager:readStream(streamId, connection)
end

function ChallengeMod:reloadConfigData()
	--self:loadConfigData(self.configFilePath)
end

function ChallengeMod:loadFromSaveGame()
	if g_currentMission.missionInfo.savegameDirectory ~= nil then
		local fileName = g_currentMission.missionInfo.savegameDirectory .. "/" .. self.configFileName
		self:loadFromXMLFile(fileName)
	end
end

function ChallengeMod:saveToSaveGame()
	if g_modIsLoaded[ChallengeMod.MOD_NAME] then
		local saveGamePath =  g_currentMission.missionInfo.savegameDirectory .."/" .. ChallengeMod.configFileName
		g_challengeMod:saveToXMLFile(saveGamePath)
	end
end
ItemSystem.save = Utils.prependedFunction(ItemSystem.save, ChallengeMod.saveToSaveGame)

g_challengeMod = ChallengeMod.new()

addModEventListener(g_challengeMod)
