VictoryPointsUtil = {}

function VictoryPointsUtil.getStorageAmount(farmId, maxFillLevel)
	if farmId == nil then 
		return VictoryPointsUtil.getFillTypes()
	end
	maxFillLevel = maxFillLevel == Rule.MAX_FILL_LEVEL_DISABLED and math.huge or maxFillLevel
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
				totalFillLevels[fillType] = totalFillLevels[fillType] + math.min(v, maxFillLevel)
			end
		end
	end

	for _, production in pairs(g_currentMission.productionChainManager:getProductionPointsForFarmId(farmId)) do
		local storage = production.storage

		for fillType, _ in pairs(production.outputFillTypeIds) do
			local fillLevel = storage:getFillLevel(fillType)

			if totalFillLevels[fillType] == nil then
				totalFillLevels[fillType] = 0
			end
			totalFillLevels[fillType] = totalFillLevels[fillType] + math.min(fillLevel, maxFillLevel)
		end
	end

	CmUtil.debug("Total storage of: %.2f", totalFillLevel )
	return totalFillLevels
end

function VictoryPointsUtil.getBaleAmount(farmId, maxFillLevel)
	if farmId == nil then 
		local fillTypes = {}
		for i, bale in pairs(g_baleManager.bales) do
			for _,data in pairs(bale.fillTypes) do
				fillTypes[data.fillTypeIndex] = 1
			end
		end
		return fillTypes
	end
	maxFillLevel = maxFillLevel == Rule.MAX_FILL_LEVEL_DISABLED and math.huge or maxFillLevel
	local baleFillLevels = {}
	for _, object in pairs(g_currentMission.nodeToObject) do
		if object:isa(Bale) and object:getOwnerFarmId(farmId) == farmId and not object.isMissionBale then 
			if baleFillLevels[object.fillType] == nil then 
				baleFillLevels[object.fillType] = 0
			end
			baleFillLevels[object.fillType] = baleFillLevels[object.fillType] + math.min(object.fillLevel, maxFillLevel)
		end
	end
	return baleFillLevels
end

function VictoryPointsUtil.getPalletAmount(farmId, maxFillLevel)
	if farmId == nil then 
		return VictoryPointsUtil.getFillTypes()
	end
	maxFillLevel = maxFillLevel == Rule.MAX_FILL_LEVEL_DISABLED and math.huge or maxFillLevel
	local palletFillLevels = {}
	for _, object in pairs(g_currentMission.vehicles) do
		if object.spec_pallet and object:getOwnerFarmId(farmId) == farmId then
			local fillUnitIndex = object.spec_pallet.fillUnitIndex
			local fillLevel = object:getFillUnitFillLevel(fillUnitIndex)
			local fillType = object:getFillUnitFillType(fillUnitIndex)
			if palletFillLevels[fillType] == nil then 
				palletFillLevels[fillType] = 0
			end
			palletFillLevels[fillType] = palletFillLevels[fillType] + math.min(fillLevel, maxFillLevel)
		end
	end
	return palletFillLevels
end

function VictoryPointsUtil.getTotalArea(farmId)
	if farmId == nil then 
		return 0
	end
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

function VictoryPointsUtil.getTotalBuildingSellValue(farmId)
	local value = 0
	for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
		if placeable:getOwnerFarmId() == farmId then
			value = value + placeable:getSellPrice()
		end
	end
	return value
end

function VictoryPointsUtil.getVehicleSellValue(farmId)
	local value = 0
	if g_currentMission.player ~= nil then
		for _, vehicle in ipairs(g_currentMission.vehicles) do
			local hasAccess = vehicle:getOwnerFarmId() == farmId
			local isProperty = vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED
			local isPallet = vehicle.typeName == "pallet"
			local isStartVehicle = vehicle.isStartVehicle

			if not isStartVehicle and hasAccess and vehicle.getSellPrice ~= nil and vehicle.price ~= nil and isProperty and not isPallet and not SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations) then
				value = value + vehicle:getSellPrice()
			end
		end
	end
	return value
end

function VictoryPointsUtil.getTotalProductionValue(farmId, maxFillLevel)
	local value = 0
	local productionPoints = g_currentMission.productionChainManager:getProductionPointsForFarmId(farmId)
	maxFillLevel = maxFillLevel == Rule.MAX_FILL_LEVEL_DISABLED and math.huge or maxFillLevel
	for i, production in pairs(productionPoints) do
		--TODO: implement
	end
	return value
end

function VictoryPointsUtil.addFillTypeFactors(fillLevels, category, factorData)
	local orderedFillLevels = table.toList(fillLevels)

	table.sort(orderedFillLevels, function (a, b)
		return g_fillTypeManager:getFillTypeTitleByIndex(a) < g_fillTypeManager:getFillTypeTitleByIndex(b)
	end)

	for _, fillType in pairs(orderedFillLevels) do 
		factorData.name = g_fillTypeManager:getFillTypeNameByIndex(fillType)
		factorData.title = g_fillTypeManager:getFillTypeTitleByIndex(fillType)
		category:addElement(VictoryPoint.createFromXml(factorData, fillLevels[fillType]))
	end
end

function VictoryPointsUtil.getFillTypes()
	local fillTypes = table.copy(g_fillTypeManager:getFillTypes())
	for fillType, _ in pairs(VictoryPointManager.ignoredFillTypes)	 do 
		fillTypes[fillType] = nil
	end
	return fillTypes
end