---@class ChallengeMod
ChallengeMod = {
	MOD_NAME = g_currentModName,
	BASE_DIRECTORY = g_currentModDirectory,
	baseXmlKey = "ChallengeMod",
	configFileName = "ChallengeModConfig.xml",
	isDevelopmentVersion = true
}

ChallengeMod.image = {
	path = Utils.getFilename('Icon_ChallengeMode.dds', ChallengeMod.BASE_DIRECTORY),
	--uvs = {0, 0,1,1}
}


local ChallengeMod_mt = Class(ChallengeMod)

function ChallengeMod.new(custom_mt)
	local self = setmetatable({}, custom_mt or ChallengeMod_mt)
	self.isServer = g_server
	self.visibleFarms = {}
	self.finalPoints = {}
	self.isAdminModeActive = false
	self.trackDuration = false
	self.timePassed = 1
	self.duration = 0

	g_messageCenter:subscribe(MessageType.FARM_CREATED, self.newFarmCreated, self)

	if ChallengeMod.isDevelopmentVersion then
		addConsoleCommand('CmGenerateContracts', 'Generates new contracts', 'consoleGenerateFieldMission', g_missionManager)
		CmUtil.debugActive = true
	end

	return self
end

function ChallengeMod:newFarmCreated(farmId)
	self.visibleFarms[farmId] = true
end

function ChallengeMod:changeFarmVisibility(farmId, visible, noEvent)
	if self.visibleFarms[farmId] ~= nil then
		CmUtil.debug("Change visibility of farm %s", farmId)
		if visible == nil then
			self.visibleFarms[farmId] = not self.visibleFarms[farmId]
		else
			self.visibleFarms[farmId] = visible
		end
	else
		self.visibleFarms[farmId] = true
	end
	if noEvent == nil or noEvent == false then
		ChangeFarmVisibilityEvent.sendEvent(farmId, self.visibleFarms[farmId])
	end
end

function ChallengeMod:getIsFarmVisible(farmId)
	return self.visibleFarms[farmId]
end

function ChallengeMod:changeAdminPassword(newPassword, noEvent)
	if newPassword ~= nil then
		self.adminPassword = newPassword
		if noEvent == nil or noEvent == false then
			ChangeAdminPasswordEvent.sendEvent(newPassword)
		end
	end
end

function ChallengeMod:setDuration(duration, noEvent)
	self.duration = duration

	if duration == 0 then
		self.trackDuration = false
		g_messageCenter:unsubscribe(MessageType.PERIOD_CHANGED, self)
	else
		self.trackDuration = true
		g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
	end

	if noEvent == nil or not noEvent then
		ChangeDurationEvent.sendEvent(duration)
	end
end

function ChallengeMod:getAdminPassword()
	return self.adminPassword
end

function ChallengeMod:getDefaultAdminPassword()
	return self.defaultAdminPassword
end

function ChallengeMod:isTimeTracked()
	return self.trackDuration
end

function ChallengeMod:isDurationOver()
	return self.timePassed > self.duration
end

function ChallengeMod:getDuration()
	return self.duration
end

function ChallengeMod:getTimePassed()
	return self.timePassed
end

function ChallengeMod:getFinalPointList()
	return self.finalPoints
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

	ChallengeMod.startVehicleButtonInfo = {
		text = g_i18n:getText("CM_buttonText_markStartVehicle"),
		inputAction = InputAction.MENU_EXTRA_1,
		callback = function ()
			local vehicle = g_currentMission.shopMenu.selectedDisplayElement.concreteItem

			vehicle.isStartVehicle = not vehicle.isStartVehicle
			ChallengeMod.setButtonText(vehicle)

			g_currentMission.shopMenu:updateButtonsPanel(g_currentMission.shopMenu.pageShopItemDetails)
		end
	}
end

function ChallengeMod:addStartVehicleButton(isOwned, numItems, hasCombinations)
	local buttons = self:getPageButtonInfo(g_currentMission.shopMenu.pageShopItemDetails)

	if numItems > 0 and g_challengeMod.isAdminModeActive then
		table.insert(buttons, ChallengeMod.startVehicleButtonInfo)

		local vehicle = g_currentMission.shopMenu.selectedDisplayElement.concreteItem

		ChallengeMod.setButtonText(vehicle)
	end

	self:updateButtonsPanel(g_currentMission.shopMenu.pageShopItemDetails)
end

function ChallengeMod.setButtonText(vehicle)
	if vehicle.isStartVehicle then
		ChallengeMod.startVehicleButtonInfo.text = g_i18n:getText("CM_buttonText_unmarkStartVehicle")
	else
		ChallengeMod.startVehicleButtonInfo.text = g_i18n:getText("CM_buttonText_markStartVehicle")
	end
end

ShopMenu.updateGarageButtonInfo = Utils.appendedFunction(ShopMenu.updateGarageButtonInfo, ChallengeMod.addStartVehicleButton)

function ChallengeMod:setupGui()
	g_gui:loadProfiles(Utils.getFilename("gui/guiProfiles.xml", self.BASE_DIRECTORY))
	self.frame = ScoreBoardFrame.new()
	g_gui:loadGui(Utils.getFilename("gui/ScoreBoardFrame.xml", self.BASE_DIRECTORY), "ScoreBoardPage", self.frame, true)

	CmUtil.fixInGameMenuPage(self.frame, "pageScoreBoard", self.image)

	self:setupDialogs()
end

function ChallengeMod:setupDialogs()
	local dialog = AddPointsDialog.new()
	g_gui:loadGui(Utils.getFilename("gui/dialogs/AddPointsDialog.xml", self.BASE_DIRECTORY), "AddPointsDialog", dialog, false)
end

function ChallengeMod:registerXmlSchema()
	self.xmlSchema = XMLSchema.new("ChallengeMod")
	self.xmlSchema:register(XMLValueType.STRING, self.baseXmlKey .. "#password", "Admin password")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. "#trackDuration", "Specifies if the duration is tracked or not", false)
	self.xmlSchema:register(XMLValueType.INT, self.baseXmlKey .. ".Farms.Farm(?)#id", "Farm id")
	self.xmlSchema:register(XMLValueType.BOOL, self.baseXmlKey .. ".Farms.Farm(?)#visible", "Farm visible", true)
	self.xmlSchema:register(XMLValueType.INT, self.baseXmlKey .. ".Farms.Farm(?)#finalPoints", "Final points of farm when challenge is over.")
	local key = self.baseXmlKey .. ".TimeLimit"
	self.xmlSchema:register(XMLValueType.INT, key .. ".Duration", "How long the Challenge will go at most.")
	self.xmlSchema:register(XMLValueType.INT, key .. ".TimePassed", "The current Month of the Challenge.", 1)
	g_victoryPointManager:registerXmlSchema(self.xmlSchema, self.baseXmlKey)
	g_ruleManager:registerXmlSchema(self.xmlSchema, self.baseXmlKey)

	self.xmlConfigSchema = XMLSchema.new("ChallengeModConfig")
	self.xmlConfigSchema:register(XMLValueType.STRING, self.baseXmlKey .. "#defaultPassword", "Admin password", "")

	g_victoryPointManager:registerConfigXmlSchema(self.xmlConfigSchema, self.baseXmlKey)
	g_ruleManager:registerConfigXmlSchema(self.xmlConfigSchema, self.baseXmlKey)
end

function ChallengeMod:loadConfigData(filename)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filename, self.xmlConfigSchema)
	if xmlFile ~= nil then
		CmUtil.debug("Challenge setup loaded from %s.", filename)
		self.adminPassword = xmlFile:getValue(self.baseXmlKey .. "#defaultPassword")
		self.defaultAdminPassword = self.adminPassword
		g_ruleManager:loadConfigData(xmlFile, self.baseXmlKey)
		g_victoryPointManager:loadConfigData(xmlFile, self.baseXmlKey)
		xmlFile:delete()
		return true
	else
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end
end

function ChallengeMod:saveToXMLFile(filename)
	local xmlFile = XMLFile.create("xmlFile", filename, self.baseXmlKey, self.xmlSchema)
	if xmlFile ~= nil then
		CmUtil.debug("Challenge setup saved to %s.", filename)
		xmlFile:setValue(self.baseXmlKey .. "#password", self.adminPassword)
		xmlFile:setValue(self.baseXmlKey .. "#trackDuration", self.trackDuration)
		local i = 0
		for farmId, visible in pairs(self.visibleFarms) do
			local key = string.format("%s.Farms.Farm(%d)", self.baseXmlKey, i)
			xmlFile:setValue(key .. "#id", farmId)
			xmlFile:setValue(key .. "#visible", visible)

			if self:isDurationOver() and visible then
				xmlFile:setValue(key .. "#finalPoints", self.finalPoints[farmId])
			end
			i = i + 1
		end

		if self.trackDuration then
			local key = self.baseXmlKey .. ".TimeLimit"

			xmlFile:setValue(key .. ".Duration", self.duration)
			xmlFile:setValue(key .. ".TimePassed", self.timePassed)
		end

		g_ruleManager:saveToXMLFile(xmlFile, self.baseXmlKey)
		g_victoryPointManager:saveToXMLFile(xmlFile, self.baseXmlKey)
		xmlFile:save()
		xmlFile:delete()
	else
		CmUtil.debug("Challenge setup xml could not be created.")
	end
end

function ChallengeMod:saveStartVehicleAttributeToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setBool(key .. "#isStartVehicle", self.isStartVehicle or false)
end

Vehicle.saveToXMLFile = Utils.appendedFunction(Vehicle.saveToXMLFile, ChallengeMod.saveStartVehicleAttributeToXMLFile)

function ChallengeMod:loadFromXMLFile(filename)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filename, self.xmlSchema)
	if xmlFile ~= nil then
		CmUtil.debug("Challenge setup loaded from %s.", filename)
		--maybe save password encrypted to increase user security. Many people use the same passwords everywhere so this could make them more attackable with a password saved in clear text
		self.adminPassword = xmlFile:getValue(self.baseXmlKey .. "#password", self.adminPassword)

		if not xmlFile:hasProperty(self.baseXmlKey .. "#trackDuration") then
			self:setDuration(0)
			self.trackDuration = false
		else
			self.trackDuration = xmlFile:getValue(self.baseXmlKey .. "#trackDuration")

			if self.trackDuration then
				local key = self.baseXmlKey .. ".TimeLimit"

				self:setDuration(xmlFile:getValue(key .. ".Duration", 0))
				self.timePassed = xmlFile:getValue(key .. ".TimePassed", 1)
			end
		end

		xmlFile:iterate(self.baseXmlKey .. ".Farms.Farm", function(ix, key)
			local id = xmlFile:getValue(key .. "#id")
			local visible = xmlFile:getValue(key .. "#visible", true)
			if id ~= nil then
				self.visibleFarms[id] = visible
			end

			if self:isDurationOver() and visible then
				self.finalPoints[id] = xmlFile:getValue(key .. "#finalPoints")
			end
		end)

		g_ruleManager:loadFromXMLFile(xmlFile, self.baseXmlKey)
		g_victoryPointManager:loadFromXMLFile(xmlFile, self.baseXmlKey)
		xmlFile:delete()
		return true
	else
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end
end

function ChallengeMod:loadStartVehicleAttribute(i3dNode, failedReason, arguments, i3dLoadingId)
	local savegame = arguments["savegame"]

	if savegame ~= nil then
		self.isStartVehicle = savegame.xmlFile:getBool(savegame.key .. "#isStartVehicle", false)
	end
end

Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, ChallengeMod.loadStartVehicleAttribute)

function ChallengeMod:writeStream(streamId, connection)
	streamWriteString(streamId, self.adminPassword)

	for farmId, visible in pairs(self.visibleFarms) do
		streamWriteInt8(streamId, farmId)
		streamWriteBool(streamId, visible)
	end
	streamWriteInt8(streamId, -1) -- break stream reading for visible farms

	streamWriteInt32(streamId, self.timePassed)
	streamWriteInt32(streamId, self.duration)
	if self:isDurationOver() then
		local numFarms = #self.finalPoints
		streamWriteInt8(streamId, numFarms)

		for farmId, points in pairs(self.finalPoints) do
			streamWriteInt8(streamId, farmId)
			streamWriteInt32(streamId, points)
		end
	end
	g_ruleManager:writeStream(streamId, connection)
	g_victoryPointManager:writeStream(streamId, connection)
end

function ChallengeMod:writeStreamVehicleAttribute(streamId, connection)
	streamWriteBool(streamId, self.isStartVehicle or false)
end
Vehicle.writeStream = Utils.appendedFunction(Vehicle.writeStream, ChallengeMod.writeStreamVehicleAttribute)

function ChallengeMod:readStream(streamId, connection)
	self.adminPassword = streamReadString(streamId)

	while true do
		local id = streamReadInt8(streamId)
		if id < 0 then
			break
		end
		self.visibleFarms[id] = streamReadBool(streamId)
	end
	self.timePassed = streamReadInt32(streamId)
	self:setDuration(streamReadInt32(streamId))

	if self:isDurationOver() then
		local numFarms = streamReadInt8(streamId)

		for i = 1, numFarms do
			local farmId = streamReadInt8(streamId)
			self.finalPoints[farmId] = streamReadInt32(streamId)
		end
	end

	g_ruleManager:readStream(streamId, connection)
	g_victoryPointManager:readStream(streamId, connection)
end

function ChallengeMod:readStreamVehicleAttribute(streamId, connection)
	self.isStartVehicle = streamReadBool(streamId)
end
Vehicle.readStream = Utils.appendedFunction(Vehicle.readStream, ChallengeMod.readStreamVehicleAttribute)

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
		local saveGamePath = g_currentMission.missionInfo.savegameDirectory .. "/" .. ChallengeMod.configFileName
		g_challengeMod:saveToXMLFile(saveGamePath)
	end
end

ItemSystem.save = Utils.prependedFunction(ItemSystem.save, ChallengeMod.saveToSaveGame)

function ChallengeMod:onPeriodChanged()
	self.timePassed = self.timePassed + 1

	if self:isDurationOver() then
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_INFO,
			text = g_i18n:getText("CM_dialog_challengeOver")
		})
		if g_currentMission:getIsServer() then
			for _, farm in pairs(g_farmManager:getFarms()) do
				local farmId = farm.farmId
				g_victoryPointManager:calculatePoints(farmId)
				self.finalPoints[farmId] = g_victoryPointManager:getTotalPoints(farmId)
			end
		end
	end
end

g_challengeMod = ChallengeMod.new()

addModEventListener(g_challengeMod)