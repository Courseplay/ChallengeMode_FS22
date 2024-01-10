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
				totalFillLevels[fillType] = math.min(totalFillLevels[fillType] + v, maxFillLevel)
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
			totalFillLevels[fillType] = math.min(totalFillLevels[fillType] + fillLevel, maxFillLevel)
		end
	end

	local objectStorages = table.filter(g_currentMission.placeableSystem.placeables, function (placeable)
        return SpecializationUtil.hasSpecialization(PlaceableObjectStorage, placeable.specializations)
    end)
	-- add support for object storage (giants variant)
	for _, placeable in pairs(objectStorages) do
        local objectStorageSpec = placeable.spec_objectStorage

        for _, abstractObject in pairs(objectStorageSpec.storedObjects) do
			local palletObject = abstractObject.palletAttributes
			if palletObject ~= nil and palletObject.ownerFarmId == farmId then
                if totalFillLevels[palletObject.fillType] == nil then
                    totalFillLevels[palletObject.fillType] = 0
                end
                totalFillLevels[palletObject.fillType] = math.min(totalFillLevels[palletObject.fillType] + palletObject.fillLevel, maxFillLevel)
            end
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
			baleFillLevels[object.fillType] = math.min(baleFillLevels[object.fillType] + object.fillLevel, maxFillLevel)
		end
	end

    local objectStorages = table.filter(g_currentMission.placeableSystem.placeables, function (placeable)
        return SpecializationUtil.hasSpecialization(PlaceableObjectStorage, placeable.specializations)
    end)
	-- add support for object storage (giants variant)
	for _, placeable in pairs(objectStorages) do
        local objectStorageSpec = placeable.spec_objectStorage

        for _, abstractObject in pairs(objectStorageSpec.storedObjects) do
			local baleObject = abstractObject.baleAttributes
			if baleObject ~= nil and baleObject.farmId == farmId and not baleObject.isMissionBale then
                if baleFillLevels[baleObject.fillType] == nil then
                    baleFillLevels[baleObject.fillType] = 0
                end
                baleFillLevels[baleObject.fillType] = math.min(baleFillLevels[baleObject.fillType] + baleObject.fillLevel, maxFillLevel)
            end
        end
	end
	return baleFillLevels
end

function VictoryPointsUtil.getPalletAmount(farmId, maxFillLevel, totalFillLevels)
	if farmId == nil then
		return VictoryPointsUtil.getFillTypes()
	end
	maxFillLevel = maxFillLevel == Rule.MAX_FILL_LEVEL_DISABLED and math.huge or maxFillLevel
	for _, object in pairs(g_currentMission.vehicles) do
		if object.spec_pallet and object:getOwnerFarmId(farmId) == farmId then
			local fillUnitIndex = object.spec_pallet.fillUnitIndex
			local fillLevel = object:getFillUnitFillLevel(fillUnitIndex)
			local fillType = object:getFillUnitFillType(fillUnitIndex)
			if totalFillLevels[fillType] == nil then
				totalFillLevels[fillType] = 0
			end
			totalFillLevels[fillType] = math.min(totalFillLevels[fillType] + fillLevel, maxFillLevel)
		end
	end
	return totalFillLevels
end

function VictoryPointsUtil.getAnimalAmount(farmId, maxNumberOfAnimals)
	if farmId == nil then
		return VictoryPointsUtil.getAnimalTypes()
	end

	local numberOfAnimals = {}
	for _, animalType in pairs(g_currentMission.animalSystem:getTypes()) do
		local backupFunction = function ()
			local animalTypeIndex = animalType.typeIndex
			local husbandries = {}

			for _, placeable in pairs(g_currentMission.husbandrySystem:getPlaceablesByFarm(farmId)) do
				if placeable:getAnimalTypeIndex() == animalTypeIndex then
					table.insert(husbandries, placeable)
				end
			end

			return husbandries
		end
		--needed because giants function is buggy. maybe after a patch it will work as intended
		--but until then the backup function will be used.
		--Ive coded it this way so that giants' function will be used if it works without having to update our code.
		local husbandries = {xpcall(function ()
			return g_currentMission.husbandrySystem:getPlaceablesByFarm(farmId, animalType)
		end, backupFunction)}

		for _, husbandry in pairs(husbandries[2]) do
			local clusters = husbandry:getClusters()
			local numberOfAnimalsInHusbandary = 0

			-- sums up each cluster that can reproduce itself. this is needed because each animal with a different age is stored in a different cluster.
			for _, cluster in pairs(clusters) do
				local animalSubType = g_currentMission.animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())

				if cluster:getAge() >= animalSubType.reproductionMinAgeMonth then
					numberOfAnimalsInHusbandary = numberOfAnimalsInHusbandary + cluster:getNumAnimals()
				end
			end

			numberOfAnimals[animalType] = math.min((numberOfAnimals[animalType] or 0) + numberOfAnimalsInHusbandary, maxNumberOfAnimals)
		end
	end

	return numberOfAnimals
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

function VictoryPointsUtil.addAnimalTypeFactors(numberOfAnimals, category, factorData)
	local orderedAnimalTypes = table.toList(numberOfAnimals)
	local animalSystem = g_currentMission.animalSystem

	table.sort(orderedAnimalTypes, function (a, b)
			if type(a) == "number" then
			a = g_currentMission.animalSystem:getSubTypeByIndex(a)
			end
			if type(b) == "number" then
			b = g_currentMission.animalSystem:getSubTypeByIndex(b)
			end

		return a.name < b.name
	end)

	for _, animalType in pairs(orderedAnimalTypes) do
		--while loading the savegame animalType is a number, but when im ingame and open the CM frame then animalType is a table.
		--I don't know why but this is a workaround
		if type(animalType) == "number" then
			animalType = g_currentMission.animalSystem:getTypeByIndex(animalType)
		end
		--every animal type must have at least 1 sub type so this is always valid
		local subTypeIndex = animalType.subTypes[1]
		local subType = animalSystem:getSubTypeByIndex(subTypeIndex)
		factorData.name = animalType.name
		-- Assumption: All sub type fill types are named the same (like giants did)
		factorData.title = g_fillTypeManager:getFillTypeTitleByIndex(subType.fillTypeIndex)
		factorData.animalNamePlural = g_i18n:getText(string.format("animalName_plural_%s", string.lower(animalType.name)))
		category:addElement(VictoryPoint.createFromXml(factorData, numberOfAnimals[animalType]))
	end
end

function VictoryPointsUtil.getFillTypes()
	local fillTypes = table.copy(g_fillTypeManager:getFillTypes())
	for fillType, _ in pairs(VictoryPointManager.ignoredFillTypes) do
		fillTypes[fillType] = nil
	end
	return fillTypes
end

function VictoryPointsUtil.getAnimalTypes()
	return table.copy(g_currentMission.animalSystem:getTypes())
end