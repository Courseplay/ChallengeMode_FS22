Rule = {}
local Rule_mt = Class(Rule, ScoreBoardElement)
---@class Rule : ScoreBoardElement
function Rule.new(name, default, title, valuesData, custom_mt)
	local self = ScoreBoardElement.new(name, title, custom_mt or Rule_mt)
	self.currentIx = default or 1
	self.title = title
	self.values = {}
	self.texts = {}
	if valuesData then
		for _, data in pairs(valuesData) do
			if data.name then
				Rule[data.name] = data.value
			end
			table.insert(self.values, data.value)
			local text = data.text
			if not text then
				text = data.value
			end
			table.insert(self.texts, text)
		end
	end
	return self
end

function Rule.createFromXml(data)
	return Rule.new(data.name, data.default, data.title, data.values)
end

function Rule:getText()
	if next(self.texts) ~= nil and self.texts[self.currentIx] then
		return self.texts[self.currentIx]
	end
	return tostring(self:getValue())
end

function Rule:getValue()
	return self.values[self.currentIx]
end

function Rule:onTextInput(value)

end

function Rule:isTextInputAllowed()
	return false
end

function Rule:onClick()
	self.currentIx = self.currentIx + 1
	if self.currentIx > #self.values then
		self.currentIx = 1
	end
	ChangeElementEvent.sendEvent(self, ChangeElementEvent.RULE)
end

function Rule:setSavedValue(value)
	if value ~= nil then
		self.currentIx = value
	end
end

function Rule:getValueToSave()
	return self.currentIx
end

function Rule:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self:getParent().id)
	streamWriteString(streamId, self.name)
	streamWriteUInt8(streamId, self.currentIx)
end

function Rule.readStream(categoryName, categoryId, name, value, ix)
	local category = g_ruleManager:getList():getElement(categoryId)
	local element = category:getElementByName(name)
	element:setSavedValue(ix)

	return element
end

function Rule:applyValues(staticCategory)
	local element = staticCategory:getElementByName(self.name)
	if element then
		self:setSavedValue(element:getValueToSave())
	end
end

----------------------------------------------------
--- Rule implementations
----------------------------------------------------

local function updateVehicleLeaseRule(screen, storeItem, vehicle, saleItem)
	screen.leaseButton:setVisible(screen.leaseButton:getIsVisible() and
		g_ruleManager:getGeneralRuleValue("leaseVehicle") ~= Rule.LEASE_VEHICLE_DEACTIVATED)
	screen.buttonsPanel:invalidateLayout()
end

ShopConfigScreen.updateButtons = Utils.appendedFunction(ShopConfigScreen.updateButtons, updateVehicleLeaseRule)

local function updateVehicleLeaseMissionRule(screen, superFunc, state, canLease)
	local function updateButtons()
		local acceptButtonIx = table.findListElementFirstIndex(screen.menuButtonInfo, screen.acceptButtonInfo)
		local leaseButtonIx = table.findListElementFirstIndex(screen.menuButtonInfo, screen.leaseButtonInfo)
		local farmId = g_currentMission:getFarmId()
		if acceptButtonIx ~= nil and farmId ~= nil then
			local maxReached = g_missionManager:hasFarmReachedMissionLimit(farmId)
			if maxReached then
				screen.menuButtonInfo[acceptButtonIx].disabled = true
				if leaseButtonIx ~= nil then
					screen.menuButtonInfo[leaseButtonIx].disabled = true
				end
			end
		end
		screen:setMenuButtonInfoDirty()
	end

	if g_ruleManager:getGeneralRuleValue("leaseVehicle") ~= Rule.LEASE_VEHICLE_ALLOWED then
		superFunc(screen, state, false)
		updateButtons()
		return
	end
	superFunc(screen, state, canLease)
	updateButtons()
end

InGameMenuContractsFrame.setButtonsForState = Utils.overwrittenFunction(InGameMenuContractsFrame.setButtonsForState,
	updateVehicleLeaseMissionRule)

local function updateMissionRules(mission, superFunc, ...)
	if not g_ruleManager:isMissionAllowed(mission) then
		return false
	end
	return superFunc(mission, ...)
end

AbstractMission.init = Utils.overwrittenFunction(AbstractMission.init, updateMissionRules)

local function updateMissionRules2(manager, dt, ...)
	for _, mission in ipairs(manager.missions) do
		if not g_ruleManager:isMissionAllowed(mission) then
			mission:delete()
		end
	end
end

MissionManager.updateMissions = Utils.appendedFunction(MissionManager.updateMissions, updateMissionRules2)

local function hasFarmReachedMissionLimit(manager, superFunc, farmId, ...)
	local maxMissions = g_ruleManager:getGeneralRuleValue("maxMissions")
	local total = 0
	for _, mission in ipairs(manager.missions) do
		if mission.farmId == farmId and
			(mission.status == AbstractMission.STATUS_RUNNING or mission.status == AbstractMission.STATUS_FINISHED) then
			total = total + 1
		end
	end
	return maxMissions <= total
end

MissionManager.hasFarmReachedMissionLimit = Utils.overwrittenFunction(MissionManager.hasFarmReachedMissionLimit,
	hasFarmReachedMissionLimit)

function Rule.getCanStartHelper(currentMission, superFunc, permission, ...)
	if permission == "hireAssistant" and
		g_ruleManager:getGeneralRuleValue("maxHelpers") <= #currentMission.aiSystem.activeJobVehicles then
		return false
	end

	return superFunc(currentMission, permission, ...)
end

function Rule.updateLoanRule(frame)
	local limit = g_ruleManager:getGeneralRuleValue("creditLimit")
	frame.borrowButtonInfo.disabled = frame.borrowButtonInfo.disabled or frame.playerFarm.loan >= limit
	frame:setMenuButtonInfoDirty()

end

InGameMenuFinancesFrame.updateFinancesLoanButtons = Utils.appendedFunction(InGameMenuFinancesFrame.updateFinancesLoanButtons
	, Rule.updateLoanRule)

function Rule.updateAnimalHusbandryLimitRules(husbandry, superFunc, ...)
	if husbandry.spec_husbandryAnimals then
		local animalType = husbandry.spec_husbandryAnimals.animalType
		local husbandryList = g_currentMission.husbandrySystem:getPlaceablesByFarm(nil)
		local animalTypeList = {}
		for i, p in pairs(husbandryList) do
			if p:getAnimalTypeIndex() == animalType.typeIndex then
				table.insert(animalTypeList, p)
			end
		end
		local rule = g_ruleManager:getAnimalHusbandryLimitByName(animalType.name)
		if rule then
			if rule:getValue() <= #animalTypeList then
				return false, g_i18n:getText("warning_tooManyHusbandries")
			end
		end
	end
	return superFunc(husbandry, ...)
end

PlaceableHusbandry.getCanBePlacedAt = Utils.overwrittenFunction(PlaceableHusbandry.getCanBePlacedAt,
	Rule.updateAnimalHusbandryLimitRules)
PlaceableHusbandry.canBuy = Utils.overwrittenFunction(PlaceableHusbandry.canBuy, Rule.updateAnimalHusbandryLimitRules)
