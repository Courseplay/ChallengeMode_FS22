---@class ChallengeMod
ChallengeMod = {
	MOD_NAME = g_currentModName,
	BASE_DIRECTORY = g_currentModDirectory,
	baseXmlKey = "ChallengeMod",
	saveGameXmlFileName = "ChallengeMod"
}
local ChallengeMod_mt = Class(ChallengeMod)

function ChallengeMod.new(custom_mt)
	local self = setmetatable({}, custom_mt or ChallengeMod_mt)

	return self
end

function ChallengeMod:loadMap()
	self:setup()
end

function ChallengeMod:setupGui()
	g_gui:loadProfiles(Utils.getFilename("gui/guiProfiles.xml", ChallengeMod.BASE_DIRECTORY))
--	local screen =  ChallengeModScreen.new()
--	g_gui:loadGui(Utils.getFilename("gui/ChallengeModScreen.xml", ChallengeMod.BASE_DIRECTORY), ChallengeMod.GUI_NAME, screen)
end

function ChallengeMod:setup()
	--- Register xml schemas	
	ChallengeManager.registerXmlSetupSchema()
	RuleManager.registerXmlSetupSchema()

	self.xmlSchema = XMLSchema.new("xmlSaveGameSchema")
	ChallengeManager.registerXmlSchema(self.xmlSchema, self.baseXmlKey)
	RuleManager.registerXmlSchema(self.xmlSchema, self.baseXmlKey)
	VictoryPointManager.registerXmlSchema(self.xmlSchema, self.baseXmlKey)

	self:setupManagers()


	self:loadFromSaveGame()
end

function ChallengeMod:setupManagers()
	self.challengeManager = ChallengeManager(g_server, g_currentMission.user)
	self.ruleManager = RuleManager(g_server, g_currentMission.user)
	self.victoryPointManager = VictoryPointManager(g_server, g_currentMission.user)

	self.challengeManager:loadChallengeTypes()
	self.ruleManager:loadRuleTypes()

end

function ChallengeMod:loadFromSaveGame()
	if g_currentMission.missionInfo.savegameDirectory ~= nil then
		local fileName = Utils.getFilename(self.saveGameXmlFileName, g_currentMission.missionInfo.savegameDirectory)
		local xmlFile = XMLFile.loadIfExists("xmlFile", fileName, self.xmlSchema)
		if xmlFile then 

			xmlFile:delete()
		end
	end
end

function ChallengeMod:saveToSaveGame()

end

function ChallengeMod.openGui()

end

addModEventListener(ChallengeMod.new())
