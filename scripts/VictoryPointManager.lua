
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
	NUM_CATEGORIES = 4,
	CONFIG_CATEGORIES = {
		"GeneralFactors",
		"StorageFactors",
		"BaleFactors",
		"PalletFactors",
	},
}
local VictoryPointManager_mt = Class(VictoryPointManager)
---@class VictoryPointManager
function VictoryPointManager.new(custom_mt)
	local self = setmetatable({}, custom_mt or VictoryPointManager_mt)
	self.isServer = g_server
		
	self.totalPoints = {}
	self.pointList = {}

	return self
end

function VictoryPointManager:registerXmlSchema(xmlSchema, baseXmlKey)
	ScoreBoardList.registerXmlSchema(xmlSchema, baseXmlKey .. ".VictoryPoints")
end


function VictoryPointManager:registerConfigXmlSchema(xmlSchema, baseXmlKey)
	CmUtil.registerConfigXmlSchema(xmlSchema, baseXmlKey .. ".VictoryPoints")
	xmlSchema:register(XMLValueType.INT, baseXmlKey .. ".VictoryPoints#goal", "Victory point goal")
end

function VictoryPointManager:loadConfigData(xmlFile, baseXmlKey)
	
	self.configData, self.titles = CmUtil.loadConfigCategories(xmlFile, baseXmlKey .. ".VictoryPoints")
	self.victoryGoal = xmlFile:getValue(baseXmlKey .. ".VictoryPoints#goal", 100000)

	self.staticPointList = self:getNewPointList()
end

function VictoryPointManager:saveToXMLFile(xmlFile, baseXmlKey)
	self.staticPointList:saveToXMLFile(xmlFile, baseXmlKey .. ".VictoryPoints", 0)
end

function VictoryPointManager:loadFromXMLFile(xmlFile, baseXmlKey)
	ScoreBoardList.loadFromXMLFile(self, xmlFile, baseXmlKey .. ".VictoryPoints")
end

function VictoryPointManager:writeStream(streamId, connection)
	self.staticPointList:writeStream(streamId)
end

function VictoryPointManager:readStream(streamId, connection)
	self.staticPointList:readStream(streamId)
end

function VictoryPointManager:addStorageFactors(category, factorData, farmId, farm)
	local fillLevels = VictoryPointsUtil.getStorageAmount(farmId)
	VictoryPointsUtil.addFillTypeFactors(fillLevels, category, factorData)
end

function VictoryPointManager:addBaleFactors(category, factorData, farmId, farm)
	local fillLevels = VictoryPointsUtil.getBaleAmount(farmId)
	VictoryPointsUtil.addFillTypeFactors(fillLevels, category, factorData)
end

function VictoryPointManager:addPalletFactors(category, factorData, farmId, farm)
	local fillLevels = VictoryPointsUtil.getPalletAmount(farmId)
	VictoryPointsUtil.addFillTypeFactors(fillLevels, category, factorData)
end

function VictoryPointManager:addMoneyFactor(category, factorData, farmId, farm)
	local money = farm and farm.money or 0
	category:addElement(VictoryPoint.createFromXml(factorData, money))
end

function VictoryPointManager:addAreaFactor(category, factorData, farmId, farm)
	local area = VictoryPointsUtil.getTotalArea(farmId)
	category:addElement(VictoryPoint.createFromXml(factorData, area))
end

function VictoryPointManager:addDependentPoint(category, factorData, farmId, farm, dependency)
	category:addElement(VictoryPoint.createFromXml(factorData, farmId ~=nil and dependency:count() or 0))
end

function VictoryPointManager:getNewPointList(farmId, farm)
	local dependedPoints = {}
	local pointList = ScoreBoardList.new("victoryPoints", self.titles)
	for _, categoryData in ipairs(self.configData) do 
		local category = ScoreBoardCategory.new(categoryData.name, categoryData.title)
		for pIx, pointData in ipairs(categoryData.elements) do 
			if pointData.dependency == nil then 
				if pointData.genericFunc == nil then
					category:addElement(VictoryPoint.createFromXml(pointData))
				else 
					self[pointData.genericFunc](self, category, pointData, farmId, farm)
				end
			else 
				table.insert(dependedPoints, {
					data = pointData,
					cName = categoryData.name,
					pIx = pIx
				})
			end
		end
		pointList:addElement(category)
	end
	for i, point in ipairs(dependedPoints) do 
		local category = pointList:getElementByName(point.cName)
		if point.data.genericFunc == nil then
			category:addElement(VictoryPoint.createFromXml(point.data), point.pIx)
		else 
			local dependency = pointList:getElementByName(point.data.dependency)
			self[point.data.genericFunc](self, category, point.data, farmId, farm, dependency)
		end
	end
	return pointList
end

function VictoryPointManager:calculatePoints(farmId, farm)
	self.pointList[farmId] = self:getNewPointList(farmId, farm)
	self.pointList[farmId]:applyValues(self.staticPointList)
	self.totalPoints[farmId] = self.pointList[farmId]:count()
end

function VictoryPointManager:update()
	self.pointList = {}
	self.totalPoints = {}
	local farms = g_farmManager:getFarms()
	for _, farm in pairs(farms) do 
		local farmId = farm.farmId
		if CmUtil.isValidFarm(farmId, farm) then
			CmUtil.debug("Calculating points for farm id: %d", farmId)
			self:calculatePoints(farmId, farm)
		end
	end
end

function VictoryPointManager:getList(farmId)
	return farmId~=nil and self.pointList[farmId] or self.staticPointList
end

function VictoryPointManager:getListByName()
	return self.staticPointList
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

g_victoryPointManager = VictoryPointManager.new()