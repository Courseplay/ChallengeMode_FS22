ScoreBoardFrame = {
	CONTROLS = {
		HEADER = "header",
		MAIN_BOC = "mainBox",
		LEFT_COLUMN = "leftColumn",
		RIGHT_COLUMN = "rightColumn",
		LEFT_LIST = "leftList",
		RIGHT_LIST = "rightList",
		LEFT_COLUMN_HEADER ="leftColumnHeader",
		RIGHT_COLUMN_HEADER = "rightColumnHeader",
		GOAL = "goal"
	},
	COLOR = {
		GREEN = {
			0, 1, 0, 1
		},
		WHITE = {
			1, 1, 1, 1
		}
	},
	LEFT_SECTIONS = {
		VictoryPoints = 1,
		Settings = 2
	},
	RIGHT_SECTIONS = {
		Points = {
			points = 1, 
			fillTypeStoragePoints = 2
		},
		Settings ={
			rule = 1, 
			missionRules = 2
		},
	},
	NUM_SETTINGS = 1
}

ScoreBoardFrame.translations = {
	goal = function(goal) return string.format("Goal: %d", goal) end,
	points = {
		"Money points: ",
		"Area points: ",
		"Total storage points: ",
	},
	rules = {
		"Helper limit: ",
		"Lease vehicles: "
	},
	leaseVehicleRule = {
		[0] = "Deactivated",
		[1] = "Only shop vehicles",
		[2] = "Activated"
	},
	missionRule = {
		"Deactivated",
		"Activated",
	},
	ruleTitle = "Rules",
	factors = {
		function (money)
			return string.format("%f/%s", g_i18n:getCurrency(money), g_i18n:getCurrencySymbol(true))
		end,
		function (area)
			return string.format("%f/%s", g_i18n:getArea(area), g_i18n:getAreaUnit())
		end,
		function (liters)
			return string.format("%f/%s", g_i18n:getFluid(liters), g_i18n:getText("unit_literShort"))
		end
	},
	menuButtons = {
		admin ="admin login",
		change = "change value"
	},
	dialogs = {
		admin = "Admin pw",
		value = "Value"
	},
	leftSections = {
		"",
		"Settings"
	},
	rightSections = {
		{
			"",
			"Fill types"
		},
		{
			"",
			"Missions"
		},
	},
}

ScoreBoardFrame.colors = {
	move = {0, 0, 0, 0.35},
	default = {0.3140, 0.8069, 1.0000, 0.02}
}

local ScoreBoardFrame_mt = Class(ScoreBoardFrame, TabbedMenuFrameElement)
---@class ScoreBoardFrame
---@field private rightList SmoothListElement
---@field private leftList SmoothListElement
function ScoreBoardFrame.new(courseStorage,target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or ScoreBoardFrame_mt)
	self:registerControls(ScoreBoardFrame.CONTROLS)
	self.farmManager = g_farmManager
	self.challengeMod = g_challengeMod
	self.victoryPointManager = g_victoryPointManager
	self.ruleManager = g_ruleManager
	self.farms = {}
	self.isAdminModeActive = false
	return self
end


function ScoreBoardFrame:onGuiSetupFinished()
	ScoreBoardFrame:superClass().onGuiSetupFinished(self)
	

	self.leftList:setDataSource(self)
	self.rightList:setDataSource(self)

	self.menuButtons = {
		--- Login as admin button.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_ACTIVATE,
			text = g_i18n:getText(self.translations.menuButtons.admin),
			callback = function ()
				self:onClickAdmin()
				self:updateMenuButtons()
			end,
			callbackDisabled = self.isAdminButtonDisabled,
		},
		--- Changes a value button.
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACTIVATE,
			text = g_i18n:getText(self.translations.menuButtons.change),
			callback = function ()
				self:onClickChange()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackDisabled = self.isChangeButtonDisabled,
		}
	}
end

function ScoreBoardFrame:onFrameOpen()
	g_victoryPointManager:update()
	self:updateLists()
	self:updateMenuButtons()
	ScoreBoardFrame:superClass().onFrameOpen(self)
end
	
function ScoreBoardFrame:onFrameClose()
	ScoreBoardFrame:superClass().onFrameClose(self)
end

function ScoreBoardFrame:updateLists()
	self.farms = self:getValidFarms()
	self.rules = self.ruleManager:getRules()
	self.missionRules = self.ruleManager:getMissionRules()
	self.leftList:reloadData()
	self.rightList:reloadData()
	self.goal:setText(self.translations.goal(g_victoryPointManager:getGoal()))
end

function ScoreBoardFrame:updateMenuButtons()
--[[
	self.menuButtonInfo = {}
	for i, btn in pairs(self.menuButtons) do 
		if btn.callbackDisabled == nil or not btn.callbackDisabled(self) then
			table.insert(self.menuButtonInfo, btn)
		end
	end
	self:setMenuButtonInfoDirty()
	]]--
end

function ScoreBoardFrame:getNumberOfSections(list)
	return 2
end

function ScoreBoardFrame:getTitleForSectionHeader(list, s)
	if list == self.leftList then 
		local text = self.translations.leftSections[s]
		if text == "" then 
			return nil
		end
		return text
	else
		local sx, ix = self.leftList:getSelectedPath()
		local text = self.translations.rightSections[sx][s]
		if text == "" then 
			return nil
		end
		return text
	end
end

function ScoreBoardFrame:getNumberOfItemsInSection(list, section)
	if list == self.leftList then
		if section == self.LEFT_SECTIONS.VictoryPoints then 
			return #self.farms
		else
			return self.NUM_SETTINGS
		end
	else
		local sx, ix = self.leftList:getSelectedPath()
		if sx == self.LEFT_SECTIONS.VictoryPoints then 
			local farmId = self:getCurrentFarmId()
			if #self.farms==0 or farmId == nil then 
				return 0
			end
			if section == self.RIGHT_SECTIONS.Points.points then 
				return #self.victoryPointManager:getPoints(farmId)
			else
				return #self.victoryPointManager:getFillTypeStoragePoints(farmId)
			end
		else
			if section == self.RIGHT_SECTIONS.Settings.rule then 
				return #self.rules
			else
				return #self.missionRules
			end
		end
	end
end


function ScoreBoardFrame:populateCellForItemInSection(list, section, index, cell)
	
	if list == self.leftList then
		if section == self.LEFT_SECTIONS.VictoryPoints then 
			if self.farms[index] then
				if self.farms[index]:getIconUVs() ~= nil then
					cell:getAttribute("icon"):setImageUVs(nil, unpack(GuiUtils.getUVs(self.farms[index]:getIconUVs())))
				end
				if self.farms[index]:getColor() ~= nil then
					cell:getAttribute("icon"):setImageColor(nil, unpack(self.farms[index]:getColor()))
				end
				cell:getAttribute("title"):setText(self.farms[index].name)
				cell:getAttribute("value"):setText(string.format("%.1f", self.victoryPointManager:getTotalPoints(self.farms[index].farmId)))
				if self.victoryPointManager:isVictoryGoalReached(self.farms[index].farmId) then
					cell:getAttribute("value"):setTextColor(unpack(self.COLOR.GREEN))
				else 
					cell:getAttribute("value"):setTextColor(unpack(self.COLOR.WHITE))
				end
			end
		else
			cell:getAttribute("title"):setText(self.translations.ruleTitle)
			cell:getAttribute("icon"):setVisible(false)
		end
	else
		local element = self:getElement(section, index)
		if element then
			cell:getAttribute("title"):setText(element:getTitle())

			cell:getAttribute("value"):setText(element:getText())

			cell:getAttribute("conversionValue"):setText(element:getFactorText())
		end
	end
end

function ScoreBoardFrame:onListSelectionChanged(list, section, index)
	if list == self.leftList then 
		--self.leftList:reloadData()
		self.rightList:reloadData()
	end
end

function ScoreBoardFrame:getValidFarms()
	local farms, farmsById = {}, {}
	for i, farm in pairs(self.farmManager:getFarms()) do 
		if CmUtil.isValidFarm(farm.farmId, farm) then 
			table.insert(farms, farm)
			farmsById[farm.farmId] = farm
		end
	end
	table.sort(farms, function(a, b)
		return  self.victoryPointManager:getTotalPoints(a.farmId) >  self.victoryPointManager:getTotalPoints(b.farmId)
	end)
	return farms, farmsById
end

function ScoreBoardFrame:getCurrentFarmId()
	local ix = self.leftList:getSelectedIndexInSection()
	if ix and self.farms[ix] then 
		return self.farms[ix].farmId
	else 
		CmUtil.debug("Current farm id not found for %d.", tostring(ix))
		printCallstack()
	end
end

function ScoreBoardFrame:getElement(section, index)
	local sx, ix = self.leftList:getSelectedPath()
	if sx == self.LEFT_SECTIONS.VictoryPoints then
		local element
		local farmId = self:getCurrentFarmId()
		if farmId then
			if section == self.RIGHT_SECTIONS.Points.points then
				element = self.victoryPointManager:getPoints(farmId)[index]
			else
				element = self.victoryPointManager:getFillTypeStoragePoints(farmId)[index]
			end
			--CmUtil.debug("Element found(%s) at %d.", element:getTitle(), index)
		end
		return element
	else
		if section == self.RIGHT_SECTIONS.Settings.rule then
			return self.rules[index]
		else
			return self.missionRules[index]
		end
	end
end

function ScoreBoardFrame:getNumberOfItemsInRightListSection(section)
	local num = 0
	local farmId = self:getCurrentFarmId()
	if farmId ~= nil then
		if section == self.RIGHT_SECTIONS.Points.rule then 
			num = #self.victoryPointManager:getPoints(farmId)
		else
			num = #self.victoryPointManager:getFillTypeStoragePoints(farmId)
		end
	end 	
	return num
end

----------------------------------------------------
--- Button callbacks
----------------------------------------------------

function ScoreBoardFrame:onClickAdmin()
	self:openTextInputDialog(self.onTextInputAdminPassword, nil, "")
end

function ScoreBoardFrame:onClickChange(item)
	local ix = self.rightList:getSelectedIndexInSection()
	if ix then
		local element = self:getElement(ix)
		self:openTextInputDialog(self.onTextInputChangeValue, ix, "")
	end
end

function ScoreBoardFrame:isAdminButtonDisabled()
	return false
end

function ScoreBoardFrame:isChangeButtonDisabled()
	return false
end

----------------------------------------------------
--- Dialogs
----------------------------------------------------

function ScoreBoardFrame:openTextInputDialog(callbackFunc, args, title, ...)
	if ... ~= nil then 
		title = string.format(title, ...)
	end
	g_gui:showTextInputDialog({
		disableFilter = true,
		callback = callbackFunc,
		target = self,
		defaultText = "",
		dialogPrompt = title,
		imePrompt = title,
		maxCharacters = 50,
		confirmText = g_i18n:getText("button_ok"),
		args = args
	})
end

function ScoreBoardFrame:onTextInputAdminPassword(text, clickOk)
	
end

function ScoreBoardFrame:onTextInputChangeValue(text, clickOk, ix)
	
end