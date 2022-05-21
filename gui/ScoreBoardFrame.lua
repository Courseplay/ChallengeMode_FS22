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
		GOAL = "goal",
		RIGHT_LIST_MIDDLE_TITLE = "rightList_middleTitle",
		RIGHT_LIST_RIGHT_TITLE = "rightList_rightTitle"
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
		POINTS = 1,
		SETTINGS = 2
	},
	NUM_SETTINGS = 1,
	NUM_LEFT_SECTIONS = 2
}

ScoreBoardFrame.translations = {
	goal = function(goal) return string.format(g_i18n:getText("CM_rightList_leftTitle"), goal) end,
	
	ruleTitle = g_i18n:getText("CM_leftList_ruleTitle"),
	
	menuButtons = {
		admin = g_i18n:getText("CM_menuBtn_admin"),
		adminChangePassword = g_i18n:getText("CM_menuBtn_admin_changePassword"),
		change = g_i18n:getText("CM_menuBtn_change"),
	},
	dialogs = {
		admin = g_i18n:getText("CM_dialog_adminTitle"),
		adminChangePassword = g_i18n:getText("CM_dialog_adminChangePasswordTitle"),
		value = g_i18n:getText("CM_dialog_changeTitle")
	},
	leftSections = {
		"",
		g_i18n:getText("CM_leftList_section_two")
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
function ScoreBoardFrame.new(target, custom_mt)
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
		{
			inputAction = InputAction.MENU_BACK,
		},
		--- Login as admin button.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.translations.menuButtons.admin,
			callback = function ()
				self:onClickAdmin()
				self:updateMenuButtons()
			end,
			callbackDisabled = self.isAdminButtonDisabled,
		},
		--- Change admin password.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.translations.menuButtons.adminChangePassword,
			callback = function ()
				self:onClickAdminChangePassword()
				self:updateMenuButtons()
			end,
			callbackDisabled = self.isAdminChangePasswordButtonDisabled,
		},
		--- Changes a value button.
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_EXTRA_1,
			text = self.translations.menuButtons.change,
			callback = function ()
				self:onClickChange()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackDisabled = self.isChangeButtonDisabled,
		}
	}
	self.managers = {
		self.victoryPointManager,
		self.ruleManager
	}


	self.numSections = {
		[self.leftList] = function(ix) return self.NUM_LEFT_SECTIONS end,
		[self.rightList] = function(ix) 
								return self.managers[ix]:getList():getNumberOfElements()
							end 
	}
	self.sectionTitles = {
		[self.leftList] = function(ix, sx) return self.translations.leftSections[sx] end,
		[self.rightList] = function(ix, sx) 
			return self.managers[ix]:getList():getElement(sx):getTitle()
		end 
	}
end

function ScoreBoardFrame:onFrameOpen()
	self.victoryPointManager:update()
	self:updateLists()
	self:updateMenuButtons()
	self:updateTitles()
	ScoreBoardFrame:superClass().onFrameOpen(self)
end
	
function ScoreBoardFrame:onFrameClose()
	ScoreBoardFrame:superClass().onFrameClose(self)
end

function ScoreBoardFrame:updateLists()
	self.farms = self:getValidFarms()
	self.leftList:reloadData()
	self.rightList:reloadData()
	self.goal:setText(self.translations.goal(self.victoryPointManager:getGoal()))
end

function ScoreBoardFrame:updateTitles()
	local sx, ix = self.leftList:getSelectedPath()
	local titles = self.managers[sx]:getList():getTitles()
	self.rightList_middleTitle:setText(titles[2])
	self.rightList_rightTitle:setText(titles[3])
end

function ScoreBoardFrame:updateMenuButtons()
	self.menuButtonInfo = {}
	for i, btn in pairs(self.menuButtons) do 
		if btn.callbackDisabled == nil or not btn.callbackDisabled(self) then
			table.insert(self.menuButtonInfo, btn)
		end
	end
	self:setMenuButtonInfoDirty()
end

function ScoreBoardFrame:getNumberOfSections(list)
	local sx, ix = self.leftList:getSelectedPath()
	return self.numSections[list](sx)
end

function ScoreBoardFrame:getTitleForSectionHeader(list, s)
	local sx, ix = self.leftList:getSelectedPath()
	local text = self.sectionTitles[list](sx, s)
	if text == "" then 
		return nil
	end
	return text
end

function ScoreBoardFrame:getNumberOfItemsInSection(list, section)
	if list == self.leftList then
		if section == self.LEFT_SECTIONS.POINTS then 
			return #self.farms
		else
			return self.NUM_SETTINGS
		end
	else
		local sx, ix = self.leftList:getSelectedPath()
		local farmId = self:getCurrentFarmId()
		local l = self.managers[sx]:getList(farmId)
		if l == nil then 
			CmUtil.debug("Categories for not found %d", section)
			printCallstack()
			return 0
		end
		return l:getNumberOfElements(section)
	end
end


function ScoreBoardFrame:populateCellForItemInSection(list, section, index, cell)
	
	if list == self.leftList then
		if section == self.LEFT_SECTIONS.POINTS then 
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
	self:updateMenuButtons()
	self:updateTitles()
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
		CmUtil.debug("Current farm id not found for %s.", tostring(ix))
		printCallstack()
	end
end

function ScoreBoardFrame:getElement(section, index)
	if section == nil or index == nil then 
		CmUtil.debug("Index or section is nil (%s|%s).", tostring(section), tostring(index))
		printCallstack()
		return
	end
	local sx, ix = self.leftList:getSelectedPath()
	local farmId = self:getCurrentFarmId()
	local list = self.managers[sx]:getList(farmId)
	if list == nil then 
		CmUtil.debug("Element not found for (%s|%s).", tostring(section), tostring(index))
		printCallstack()
		return
	end
	return list:getElement(section,index)
end

----------------------------------------------------
--- Button callbacks
----------------------------------------------------

function ScoreBoardFrame:onClickAdmin()
	self:openTextInputDialog(self.onTextInputAdminPassword, nil, self.translations.dialogs.admin, self.challengeMod:getDefaultAdminPassword())
end

function ScoreBoardFrame:onClickAdminChangePassword()
	self:openTextInputDialog(self.onTextInputChangeAdminPassword, nil, self.translations.dialogs.adminChangePassword, self.challengeMod:getAdminPassword())
end


function ScoreBoardFrame:onClickChange()
	local sec,ix = self.rightList:getSelectedPath()
	local element = self:getElement(sec,ix)
	if element then 
		if element:isTextInputAllowed() then
			self:openTextInputDialog(self.onTextInputChangeValue, element, element:getTitle())
		end
		element:onClick()
		self:updateLists()
	end
end

function ScoreBoardFrame:isAdminButtonDisabled()
	return self.isAdminModeActive
end

function ScoreBoardFrame:isAdminChangePasswordButtonDisabled()
	return not self.isAdminModeActive
end

function ScoreBoardFrame:isChangeButtonDisabled()
	return not self.isAdminModeActive
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
	if clickOk then 
		if text == self.challengeMod:getAdminPassword() then 
			self.isAdminModeActive = true
			self:updateMenuButtons()
		end
	end
end

function ScoreBoardFrame:onTextInputChangeAdminPassword(text, clickOk)
	if clickOk then 
		self.challengeMod:changeAdminPassword(text)
	end
end

function ScoreBoardFrame:onTextInputChangeValue(text, clickOk, element)
	if clickOk then 
		if text ~= nil and element ~= nil then
			element:onTextInput(text)
			self.victoryPointManager:update()
			self:updateLists()
		end
	end
end