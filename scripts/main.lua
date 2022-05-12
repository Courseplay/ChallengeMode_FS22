---@class ChallengeMod
ChallengeMod = {
	MOD_NAME = g_currentModName,
	BASE_DIRECTORY = g_currentModDirectory,
	baseXmlKey = "ChallengeMod",
	configFileName = "ChallengeModConfig.xml",
}

ChallengeMod.image = {
	path = Utils.getFilename('Icon_ChallengeMode.dds', ChallengeMod.BASE_DIRECTORY),
	uvs = {0, 0,1,1}
}


local ChallengeMod_mt = Class(ChallengeMod)

function ChallengeMod.new(custom_mt)
	local self = setmetatable({}, custom_mt or ChallengeMod_mt)
	self.isServer = g_server

	addConsoleCommand('challengeModReloadConfig', 'Reloading config file', 'reloadConfigData', self)

	return self
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

	g_victoryPointManager:registerXmlSchema(self.xmlSchema, self.baseXmlKey)

end

function ChallengeMod:loadConfigData(filename)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filename, self.xmlSchema)
	if xmlFile then 
		CmUtil.debug("Challenge setup loaded from %s.", filename)
		g_victoryPointManager:loadConfigData(xmlFile, self.baseXmlKey)
		xmlFile:delete()
		return true
	else
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end
end


function ChallengeMod:saveConfigData(filename)
	local xmlFile = XMLFile.create("xmlFile", filename, self.baseXmlKey, self.xmlSchema)
	if xmlFile then 
		CmUtil.debug("Challenge setup saved to %s.", filename)
		g_victoryPointManager:saveConfigData(xmlFile, self.baseXmlKey)
		xmlFile:save()
		xmlFile:delete()
	else
		CmUtil.debug("Challenge setup xml could not be created.")
	end
end



function ChallengeMod:reloadConfigData()
	if g_currentMission.missionInfo.savegameDirectory ~= nil then
		local saveGamePath =  g_currentMission.missionInfo.savegameDirectory .."/" .. ChallengeMod.configFileName
		if self:loadConfigData(saveGamePath) then 
			return 
		end
	end
	self:loadConfigData(self.configFilePath)
end

function ChallengeMod:loadFromSaveGame()
	if g_currentMission.missionInfo.savegameDirectory ~= nil then
		local fileName = g_currentMission.missionInfo.savegameDirectory .. "/" .. self.configFileName
		self:loadConfigData(fileName)
	end
end

function ChallengeMod:saveToXMLFile()
	if g_modIsLoaded[ChallengeMod.MOD_NAME] then
		local saveGamePath =  g_currentMission.missionInfo.savegameDirectory .."/" .. ChallengeMod.configFileName
	--	copyFile(g_challengeMod.configFilePath, saveGamePath, false)
		g_challengeMod:saveConfigData(saveGamePath)
	end
end
ItemSystem.save = Utils.prependedFunction(ItemSystem.save, ChallengeMod.saveToXMLFile)

g_challengeMod = ChallengeMod.new()

addModEventListener(g_challengeMod)
