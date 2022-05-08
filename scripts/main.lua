---@class ChallengeMod
ChallengeMod = {
	MOD_NAME = g_currentModName,
	BASE_DIRECTORY = g_currentModDirectory,
	rootXmlKey = "ChallengeMod",
	baseXmlKey = "ChallengeMod.",
	configFileName = "ChallengeModConfig.xml",
	areaFactor = 1,
	storageFactor = 1,
	moneyFactor = 1,

	attributes = {
		victoryPoints = XMLValueType.INT,
		moneyFactor = XMLValueType.FLOAT,
		storageFactor = XMLValueType.FLOAT,
		areaFactor = XMLValueType.FLOAT,
		maxHelpers = XMLValueType.INT,
		leaseVehicle = XMLValueType.BOOL,
		leaseMissionVehicle = XMLValueType.BOOL,
	},
	numberOfPointAttributes = 3
}

ChallengeMod.image = {
	path = Utils.getFilename('Icon_ChallengeMode.dds', ChallengeMod.BASE_DIRECTORY),
	uvs = {0, 0,1,1}
}


local ChallengeMod_mt = Class(ChallengeMod)

function ChallengeMod.new(custom_mt)
	local self = setmetatable({}, custom_mt or ChallengeMod_mt)
	self.isServer = g_server

	self.victoryPointsByFarmId = {}
	self.totalVictoryPointsByFarmId = {}
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
    for name, xmlType in pairs(self.attributes) do 
        self.xmlSchema:register(xmlType,self.baseXmlKey..name,"Configuration value")
    end
end

function ChallengeMod:loadConfigData(filename)
	local xmlFile = XMLFile.loadIfExists("xmlFile", filename, self.xmlSchema)
	if xmlFile then 
		CmUtil.debug("Challenge setup loaded from %s.", filename)
		for name, _ in pairs(self.attributes) do 
			self[name] = xmlFile:getValue(self.baseXmlKey..name)
		end
		xmlFile:delete()
	else
		CmUtil.debug("Challenge setup xml could not be loaded.")
	end

end

function ChallengeMod:saveConfigData(filename)
	local xmlFile = XMLFile.create("xmlFile", filename, self.rootXmlKey, self.xmlSchema)
	if xmlFile then 
		CmUtil.debug("Challenge setup saved to %s.", filename)
		for name, _ in pairs(self.attributes) do 
			xmlFile:setValue(self.baseXmlKey..name, self[name])
		end
		xmlFile:save()
		xmlFile:delete()
	else
		CmUtil.debug("Challenge setup xml could not be created.")
	end
end

function ChallengeMod:reloadConfigData()
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
		copyFile(g_challengeMod.configFilePath, saveGamePath, false)
		g_challengeMod:saveConfigData(saveGamePath)
	end
end
ItemSystem.save = Utils.prependedFunction(ItemSystem.save, ChallengeMod.saveToXMLFile)




function ChallengeMod:getTotalStorageAmount(farmId)
	local totalFillLevel = 0
	local usedStorages = {}
	for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
		if usedStorages[storage] == nil and storage:getOwnerFarmId() == farmId and not storage.foreignSilo then
			usedStorages[storage] = true
			local fillLevels = storage:getFillLevels()
			for typ, v in pairs(fillLevels) do 
				totalFillLevel = totalFillLevel + v
			end
		end
	end
	CmUtil.debugSparse("Total storage of: %.2f", totalFillLevel)
	return totalFillLevel
end

function ChallengeMod:getTotalArea(farmId)
	local totalArea = 0
	local farmlands = g_farmlandManager:getOwnedFarmlandIdsByFarmId(farmId)
	for _, farmlandId in pairs(farmlands) do
		local farmland = g_farmlandManager:getFarmlandById(farmlandId)
		if farmland then
			totalArea = totalArea + farmland.areaInHa
		end
	end
	CmUtil.debugSparse("Total area of: %.2f", totalArea)
	return totalArea
end

function ChallengeMod:calculatePoints(farmId, farm)
	local money = farm.money or 0
	local totalStorageAmount = self:getTotalStorageAmount(farmId)
	local totalArea = self:getTotalArea(farmId)

	local moneyPoints = money * self.moneyFactor
	local storagePoints = totalStorageAmount * self.storageFactor
	local areaPoints = totalArea * self.areaFactor
	local totalPoints = moneyPoints + storagePoints + areaPoints
	self.victoryPointsByFarmId[farmId] = {
		moneyPoints,
		storagePoints,
		areaPoints,
	}
	self.victoryPointsFactors = {
		self.moneyFactor,
		self.storageFactor,
		self.areaFactor
	}
	self.totalVictoryPointsByFarmId[farmId] = totalPoints
	table.insert(self.drawData, {
		name = farm.name,
		value = string.format("%.2f, %.2f, %.2f, %.2f", totalPoints, 
								moneyPoints, storagePoints, areaPoints)
	})
end

function ChallengeMod:getPointsForFarmId(farmId)
	return self.victoryPointsByFarmId[farmId]
end

function ChallengeMod:getTotalPointsForFarmId(farmId)
	return self.totalVictoryPointsByFarmId[farmId]
end

function ChallengeMod:getPointFactors()
	return self.victoryPointsFactors
end

function ChallengeMod:update(dt)
	local farms = g_farmManager:getFarms()
	self.drawData = {
		{
			name = "Farms",
			value = "Points, moneyPoints, storagePoints, areaPoints"
		}
	}
	for _, farm in pairs(farms) do 
		local farmId = farm.farmId
		if CmUtil.isValidFarm(farmId, farm) then
			CmUtil.debugSparse("Calculating points for farm id: %d", farmId)
			self:calculatePoints(farmId, farm)
		end
	end
	table.sort(self.drawData, function (a, b)
		return a.value>b.value		
	end)
end

function ChallengeMod:draw()
	DebugUtil.renderTable(0.2, 0.46, 0.02, self.drawData)	
end

g_challengeMod = ChallengeMod.new()

addModEventListener(g_challengeMod)
