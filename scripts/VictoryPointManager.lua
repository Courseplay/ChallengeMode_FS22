
VictoryPointManager = {
	FACTORS = {
		MONEY = 1,
		AREA = 2,
		TOTAL_STORAGE = 3,
		BALE_STORAGE = 4,
		PALLET_STORAGE = 5
	},
	POINT_LIST = {
		POINTS = 1,
		STORAGE = 2,
		BALE_STORAGE = 3,
		PALLET_STORAGE = 4
	},
	NUM_CATEGORIES = 4
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

	self.balePoints = {}
	self.palletPoints = {}

	self.pointList = {}

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

function VictoryPointManager:getBaleAmount(farmId)
	local baleFillLevels = {}
	for _, object in pairs(g_currentMission.nodeToObject) do
		if object:isa(Bale) and object:getOwnerFarmId(farmId) == farmId and not object.isMissionBale then 
			if baleFillLevels[object.fillType] == nil then 
				baleFillLevels[object.fillType] = 0
			end
			baleFillLevels[object.fillType] = baleFillLevels[object.fillType] + object.fillLevel
		end
	end
	return baleFillLevels
end

function VictoryPointManager:getPalletAmount(farmId)
	local palletFillLevels = {}
	for _, object in pairs(g_currentMission.vehicles) do
		if object.spec_pallet and object:getOwnerFarmId(farmId) == farmId then 
			local fillUnitIndex = object.spec_pallet.fillUnitIndex
			local fillLevel = object:getFillUnitFillLevel(fillUnitIndex)
			local fillType = object:getFillUnitFillType(fillUnitIndex)
			if palletFillLevels[fillType] == nil then 
				palletFillLevels[fillType] = 0
			end
			palletFillLevels[fillType] = palletFillLevels[fillType] + fillLevel
		end
	end
	return palletFillLevels
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
	local baleFillLevels = self:getBaleAmount(farmId)
	local palletFillLevels = self:getPalletAmount(farmId)
	local totalArea = self:getTotalArea(farmId)
	

	

	
	self.points[farmId] = {
		self:newMoneyFactor(money),
		self:newAreaFactor(totalArea),
	}

	self.fillTypeStoragePoints[farmId] = {}
	self.balePoints[farmId] = {}
	self.palletPoints[farmId] = {}

	self:addFillLevels(fillLevels, self.fillTypeStoragePoints[farmId])
	self:addFillLevels(baleFillLevels, self.balePoints[farmId])
	self:addFillLevels(palletFillLevels, self.palletPoints[farmId])

	local points = self:countPoints(self.points[farmId])
	local fillTypePoints = self:countPoints(self.fillTypeStoragePoints[farmId])
	local balePoints = self:countPoints(self.balePoints[farmId])
	local palletPoints = self:countPoints(self.palletPoints[farmId])

	table.insert(self.points[farmId], self:newStorageFactor(fillTypePoints, self.FACTORS.TOTAL_STORAGE))
	table.insert(self.points[farmId], self:newStorageFactor(balePoints, self.FACTORS.BALE_STORAGE))
	table.insert(self.points[farmId], self:newStorageFactor(palletPoints, self.FACTORS.PALLET_STORAGE))

	self.totalPoints[farmId] = points + fillTypePoints + balePoints + palletPoints

	self.pointList[farmId] = {
		self.points[farmId],
		self.fillTypeStoragePoints[farmId],
		self.balePoints[farmId],
		self.palletPoints[farmId]
	}

end

function VictoryPointManager:countPoints(data)
	local points = 0
	for _, p in pairs(data) do 
		points = points + p:getValue()
	end
	return points
end

function VictoryPointManager:addFillLevels(fillLevels, target)
	local orderedFillLevels = table.toList(fillLevels)
	
	table.sort(orderedFillLevels, function (a, b)
		return g_fillTypeManager:getFillTypeTitleByIndex(a) < g_fillTypeManager:getFillTypeTitleByIndex(b)
	end)

	for _, fillType in pairs(orderedFillLevels) do 

		table.insert(target, self:newStorageFillTypeFactor(fillType, fillLevels[fillType]))
	end
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

function VictoryPointManager:getPointList(farmId)
	return self.pointList[farmId]
end

function VictoryPointManager:getPoints(farmId)
	return self.points[farmId]
end

function VictoryPointManager:getFillTypeStoragePoints(farmId)
	return self.fillTypeStoragePoints[farmId]
end

function VictoryPointManager:getBalesPoints(farmId)
	return self.balePoints[farmId]
end

function VictoryPointManager:getPalletsPoints(farmId)
	return self.palletPoints[farmId]
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

function VictoryPointManager:newStorageFactor(value, ix)
	return VictoryPoint.new(value, nil, ScoreBoardFrame.translations.points[ix])
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