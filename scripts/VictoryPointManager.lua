
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
	ScoreBoardCategory.registerXmlSchema(xmlSchema, baseXmlKey .. ".VictoryPoints")
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
	for i, category in ipairs(self.staticPointList) do 
		category:saveToXMLFile(xmlFile, string.format("%s.VictoryPoints.Category(%d)", baseXmlKey, i-1))
	end
	--[[
	local baseKey = string.format("%s.VictoryPoints", baseXmlKey)
	for cIx, category in ipairs(self.configData) do 
		local cKey = string.format("%s.Category(%d)", baseKey, cIx-1)
		xmlFile:setValue(cKey .. "#name", category.name)
		for eIx, element in ipairs(category.elements) do 
			if not element.dependency then
				local eKey = string.format("%s.Element(%d)", cKey, eIx-1)
				xmlFile:setValue(eKey .. "#name", element.name)
				xmlFile:setValue(eKey, element.default)
			end
		end
	end
	]]--
end

function VictoryPointManager:loadFromXMLFile(xmlFile, baseXmlKey)
	xmlFile:iterate(baseXmlKey .. ".VictoryPoints.Category", function (ix, key)
		local name = xmlFile:getValue(key .. "#name")
		if name then
			local category = CmUtil.getCategoryByName(self.staticPointList, name)
			if category then 
				category:loadFromXMLFile(xmlFile, key)
			end
		end
	end)
	--[[
	local setup = {}
	xmlFile:iterate(baseXmlKey .. ".VictoryPoints.Category", function (ix, categoryKey)
		local categoryName = xmlFile:getValue(categoryKey .. "#name")
		if categoryName then
			setup[categoryName] = {}
			xmlFile:iterate(categoryKey .. ".Element", function (ix, elementKey)
				local elementName = xmlFile:getValue(elementKey .. "#name")
				local value = xmlFile:getValue(elementKey)
				if elementName and value ~= nil then 
					setup[categoryName][elementName] = value
				end
			end)
		end
	end)
	for _, category in ipairs(self.configData) do 
		local e = setup[category.name]
		if e then 
			for _, element in ipairs(category.elements) do 
				local v = setup[category.name][element.name]
				if v ~= nil then 
					element.default = v
				end
			end
		end
	end
	]]--
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
	local pointList = {}
	for cIx, categoryData in ipairs(self.configData) do 
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
					cIx = cIx,
					pIx = pIx
				})
			end
		end
		table.insert(pointList, category)
	end
	for i, point in ipairs(dependedPoints) do 
		local category = pointList[point.cIx]
		if point.data.genericFunc == nil then
			category:addElement(VictoryPoint.createFromXml(point.data), point.pIx)
		else 
			local dependency = CmUtil.getCategoryByName(pointList, point.data.dependency)
			self[point.data.genericFunc](self, category, point.data, farmId, farm, dependency)
		end
	end
	return pointList
end

function VictoryPointManager:calculatePoints(farmId, farm)
	self.pointList[farmId] = self:getNewPointList(farmId, farm)
	self.totalPoints[farmId] = 0
	for i, category in ipairs(self.staticPointList) do 
		self.pointList[farmId][i]:applyValues(category)
		self.totalPoints[farmId] = self.totalPoints[farmId] + self.pointList[farmId][i]:count()
	end

end

function VictoryPointManager:countPoints(data)
	local points = 0
	for _, p in pairs(data) do 
		points = points + p:getValue()
	end
	return points
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

function VictoryPointManager:getCategories(farmId)
	return farmId~=nil and self.pointList[farmId]
end

function VictoryPointManager:getNumberOfCategories()
	return #self.configData
end

function VictoryPointManager:getTitles()
	return self.titles	
end

function VictoryPointManager:getSectionTitle(sec)
	return self.configData[sec].title or ""
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

function VictoryPointManager:onTextInput(element, category, value)
	local v = tonumber(value)
	if v ~= nil then
		for _, c in pairs(self.staticPointList) do 
			if c:getName() == category:getName() then 
				local e = c:getElementByName(element:getName())
				if e then
					e:setFactor(v)
					self:update()
				end
			end
		end
	end
end

g_victoryPointManager = VictoryPointManager.new()