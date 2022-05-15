
VictoryPointManager = {
	FACTORS = {
		MONEY = 1,
		AREA = 2,
		TOTAL_STORAGE = 3,
		DEFAULT_STORAGE = 4
	}
}
local VictoryPointManager_mt = Class(VictoryPointManager)
---@class VictoryPointManager
function VictoryPointManager.new(custom_mt)
	local self = setmetatable({}, custom_mt or VictoryPointManager_mt)
	self.isServer = g_server
		
	self.factors = {}

	self.pointsByFarmId = {}
	self.totalPoints = {}
	self.pointTitles = {}
	self.factorTexts = {}

	--- Factors 
	self.storageFactors = {}
	self.loadedStorageFactors = {}
	self.storageFillTypes = {}

	self.points = {}

	self.fillTypeStoragePoints = {}

	return self
end

function VictoryPointManager:registerXmlSchema(xmlSchema, baseXmlKey)
	local key = baseXmlKey .. ".VictoryPoints"
	xmlSchema:register(XMLValueType.FLOAT,key.."#goal","Victory goal")
	xmlSchema:register(XMLValueType.FLOAT,key..".moneyFactor","Money factor")
	xmlSchema:register(XMLValueType.FLOAT,key..".areaFactor","Area factor")
	xmlSchema:register(XMLValueType.FLOAT,key..".storageFactors#default","Storage default factor")

	xmlSchema:register(XMLValueType.STRING,key..".storageFactors.factor(?)#fillTypes","Storage fillType name")
	xmlSchema:register(XMLValueType.FLOAT,key..".storageFactors.factor(?)","Storage fillType factor")
end

function VictoryPointManager:loadConfigData(xmlFile, baseXmlKey)
	local baseKey = baseXmlKey .. ".VictoryPoints"
	self.victoryGoal = xmlFile:getValue(baseKey.."#goal", 100000)
	self.factors[self.FACTORS.MONEY] = xmlFile:getValue(baseKey..".moneyFactor", 1)
	self.factors[self.FACTORS.AREA] = xmlFile:getValue(baseKey..".areaFactor", 1)
	self.defaultStorageFactor = xmlFile:getValue(baseKey .. ".storageFactors#default", 1)

	xmlFile:iterate(baseKey .. ".storageFactors.factor", function (i, key)
		local names = xmlFile:getValue(key.."#fillTypes")	
		CmUtil.debug("Trying to find fill types: %s", names)
		if names then
			local value = xmlFile:getValue(key)
			local fillTypes = g_fillTypeManager:getFillTypesByNames(names)
			if fillTypes and next(fillTypes) then
				self.loadedStorageFactors[names] = value
				for i, fillType in pairs(fillTypes) do 
					if fillType then
						self.storageFactors[fillType] = value
					end
				end
			end
		end
	end)	
end

function VictoryPointManager:saveConfigData(xmlFile, baseXmlKey)
	local baseKey = baseXmlKey .. ".VictoryPoints"
	xmlFile:setValue(baseKey.."#goal", self.victoryGoal)
	xmlFile:setValue(baseKey..".moneyFactor", self.factors[self.FACTORS.MONEY])
	xmlFile:setValue(baseKey..".areaFactor", self.factors[self.FACTORS.AREA])
	xmlFile:setValue(baseKey..".storageFactors#total", self.factors[self.FACTORS.TOTAL_STORAGE])
	xmlFile:setValue(baseKey .. ".storageFactors#default", self.defaultStorageFactor)

	local ix, key = 0, ""
	for names, value in pairs(self.loadedStorageFactors) do 
		key = string.format("%s.storageFactors.factor(%d)", baseKey, ix)
		xmlFile:setValue(key.."#fillTypes", names)
		xmlFile:setValue(key, value)
		ix = ix + 1
	end
end

function VictoryPointManager:getStorageAmount(farmId)
	local totalFillLevel = 0
	local totalFillLevels = {}
	local usedStorages = {}
	for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
		if usedStorages[storage] == nil and storage:getOwnerFarmId() == farmId and not storage.foreignSilo then
			usedStorages[storage] = true
			local fillLevels = storage:getFillLevels()
			for fillType, v in pairs(fillLevels) do 
				CmUtil.debug("Storage fillType(%s) found.", g_fillTypeManager:getFillTypeNameByIndex(fillType))
				totalFillLevel = totalFillLevel + v
				if totalFillLevels[fillType] == nil then 
					totalFillLevels[fillType] = 0
				end
				totalFillLevels[fillType] = totalFillLevels[fillType] + v
			end
		end
	end
	CmUtil.debug("Total storage of: %.2f", totalFillLevel )
	return totalFillLevel, totalFillLevels
end

function VictoryPointManager:getTotalArea(farmId)
	local totalArea = 0
	local farmlands = g_farmlandManager:getOwnedFarmlandIdsByFarmId(farmId)
	for _, farmlandId in pairs(farmlands) do
		local farmland = g_farmlandManager:getFarmlandById(farmlandId)
		if farmland then
			totalArea = totalArea + farmland.areaInHa
		end
	end
	CmUtil.debug("Total area of: %.2f", totalArea)
	return totalArea
end

function VictoryPointManager:calculatePoints(farmId, farm)
	local money = farm.money or 0
	local totalStorageAmount, fillLevels = self:getStorageAmount(farmId)
	local totalArea = self:getTotalArea(farmId)

	
	self.points[farmId] = {
		self:newMoneyFactor(money),
		self:newAreaFactor(totalArea),
	}

	self.fillTypeStoragePoints[farmId] = {}

	local orderedFillLevels = table.toList(fillLevels)
	
	table.sort(orderedFillLevels, function (a, b)
		return g_fillTypeManager:getFillTypeTitleByIndex(a) < g_fillTypeManager:getFillTypeTitleByIndex(b)
	end)

	for _, fillType in pairs(orderedFillLevels) do 

		table.insert(self.fillTypeStoragePoints[farmId], self:newStorageFillTypeFactor(fillType, fillLevels[fillType]))
	end

	local points = 0
	for _, p in pairs(self.points[farmId]) do 
		points = points + p:getValue()
	end
	local fillTypePoints = 0
	for _, p in pairs(self.fillTypeStoragePoints[farmId]) do 
		fillTypePoints = fillTypePoints + p:getValue()
	end

	table.insert(self.points[farmId], self:newStorageFactor(fillTypePoints, nil))

	self.totalPoints[farmId] = points + fillTypePoints

end

function VictoryPointManager:update()

	local farms = g_farmManager:getFarms()
	for _, farm in pairs(farms) do 
		local farmId = farm.farmId
		if CmUtil.isValidFarm(farmId, farm) then
			CmUtil.debug("Calculating points for farm id: %d", farmId)
			self:calculatePoints(farmId, farm)
		end
	end
end

function VictoryPointManager:getPoints(farmId)
	return self.points[farmId]
end

function VictoryPointManager:getFillTypeStoragePoints(farmId)
	return self.fillTypeStoragePoints[farmId]
end

function VictoryPointManager:getTotalPoints(farmId)
	return self.totalPoints[farmId]
end

function VictoryPointManager:isVictoryGoalReached(farmId)
	return self.totalPoints[farmId] > self.victoryGoal	
end

function VictoryPointManager:getGoal()
	return self.victoryGoal	
end

function VictoryPointManager:newMoneyFactor(value)
	local factor = self.factors[self.FACTORS.MONEY]
	return VictoryPoint.new(value, factor, ScoreBoardFrame.translations.points[self.FACTORS.MONEY], 
		ScoreBoardFrame.translations.factors[self.FACTORS.MONEY])
end

function VictoryPointManager:newAreaFactor(value)
	local factor = self.factors[self.FACTORS.AREA]
	return VictoryPoint.new(value, factor, ScoreBoardFrame.translations.points[self.FACTORS.AREA], 
		ScoreBoardFrame.translations.factors[self.FACTORS.AREA])
end

function VictoryPointManager:newStorageFactor(value, factor)
	return VictoryPoint.new(value, factor, ScoreBoardFrame.translations.points[self.FACTORS.TOTAL_STORAGE])
end

function VictoryPointManager:newStorageFillTypeFactor(fillType, value)
	local title = g_fillTypeManager:getFillTypeTitleByIndex(fillType)
	local factor = self.storageFactors[fillType] 
	if factor == nil then 
		factor = self.defaultStorageFactor
	end
	return VictoryPoint.new(value, factor, title, 	
		ScoreBoardFrame.translations.factors[self.FACTORS.TOTAL_STORAGE])
	
end


g_victoryPointManager = VictoryPointManager.new()