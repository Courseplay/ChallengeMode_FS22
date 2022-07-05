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
	NUM_SETTINGS_ADMIN = 2,
	NUM_LEFT_SECTIONS = 2
}

ScoreBoardFrame.translations = {
	goal = function(goal) return string.format(g_i18n:getText("CM_rightList_leftTitle"), goal) end,
	
	ruleTitle = g_i18n:getText("CM_leftList_ruleTitle"),
	adminPointsTitle = g_i18n:getText("CM_leftList_adminPointsTitle"),
	menuButtons = {
		adminLogin = g_i18n:getText("CM_menuBtn_admin_login"),
		adminLogout = g_i18n:getText("CM_menuBtn_admin_logout"),
		adminChangePassword = g_i18n:getText("CM_menuBtn_admin_changePassword"),
		change = g_i18n:getText("CM_menuBtn_change"),
		changeFarmVisibility = g_i18n:getText("CM_menuBtn_changeFarmVisibility")
	},
	dialogs = {
		admin = g_i18n:getText("CM_dialog_adminTitle"),
		adminChangePassword = g_i18n:getText("CM_dialog_adminChangePasswordTitle"),
		adminWrongPassword = g_i18n:getText("CM_dialog_adminWrongPassword"),
		value = g_i18n:getText("CM_dialog_changeTitle"),
	},
	leftSections = {
		"",
		g_i18n:getText("CM_leftList_section_two"),
	},
	
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
			inputAction = InputAction.MENU_ACCEPT,
			text = self.translations.menuButtons.adminLogin,
			callback = function ()
				self:onClickAdminLogin()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackDisabled = self.isAdminLoginButtonDisabled,
		},
		--- Logout admin button.
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACCEPT,
			text = self.translations.menuButtons.adminLogout,
			callback = function ()
				self:onClickAdminLogout()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackDisabled = self.isAdminLogoutButtonDisabled,
		},
		--- Change admin password.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_EXTRA_2,
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
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.translations.menuButtons.change,
			callback = function ()
				CmUtil.try(self.onClickChange, self)
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackDisabled = self.isChangeButtonDisabled,
		},
		--- Changes farm visibility.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_EXTRA_1,
			text = self.translations.menuButtons.changeFarmVisibility,
			callback = function ()
				self:onClickChangeFarmVisibility()
				self:updateMenuButtons()
			end,
			callbackDisabled = self.isAdminLogoutButtonDisabled,
		},
	}
	self.managers = {
		function (...)
			return self.victoryPointManager:getList(...)
		end,
		function (...)
			local sx, ix = self.leftList:getSelectedPath()
			return ix == 1 and self.ruleManager:getList() or self.victoryPointManager:getList()
		end,
	}


	self.numSections = {
		[self.leftList] = function() return self.NUM_LEFT_SECTIONS end,
		[self.rightList] = function() 
								local sx, ix = self.leftList:getSelectedPath()
								return self.managers[sx]():getNumberOfElements()
							end 
	}
	self.sectionTitles = {
		[self.leftList] = function(sx) 
			return self.translations.leftSections[sx] 
		end,
		[self.rightList] = function(rsx) 
			local sx, ix = self.leftList:getSelectedPath()
			return self.managers[sx]():getElement(rsx):getTitle()
		end 
	}
end

function ScoreBoardFrame:onFrameOpen()
	self:updateLists()
	self:updateMenuButtons()
	self:updateTitles()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.leftList)
	self:setSoundSuppressed(false)
	ScoreBoardFrame:superClass().onFrameOpen(self)
end
	
function ScoreBoardFrame:onFrameClose()
	ScoreBoardFrame:superClass().onFrameClose(self)
end
function ScoreBoardFrame:updateLists()
	self.victoryPointManager:update()
	self.farms = self:getValidFarms()
	self.leftList:reloadData()
	self.rightList:reloadData()
	self.goal:setText(self.translations.goal(self.victoryPointManager:getGoal()))
end

function ScoreBoardFrame:updateTitles()
	local sx, ix = self.leftList:getSelectedPath()
	local titles = self.managers[sx]():getTitles()
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
	return self.numSections[list]()
end

function ScoreBoardFrame:getTitleForSectionHeader(list, s)
	local text = self.sectionTitles[list](s)
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
			return self.isAdminModeActive and self.NUM_SETTINGS_ADMIN or self.NUM_SETTINGS
		end
	else
		local sx, ix = self.leftList:getSelectedPath()
		local farmId = self:getCurrentFarmId()
		local l = self.managers[sx](farmId)
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
		elseif index == 1 then
			cell:getAttribute("title"):setText(self.translations.ruleTitle)
			cell:getAttribute("icon"):setVisible(false)
		else 
			cell:getAttribute("title"):setText(self.translations.adminPointsTitle)
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
			if self.isAdminModeActive or self.challengeMod:getIsFarmVisible(farm.farmId) then
				table.insert(farms, farm)
				farmsById[farm.farmId] = farm
			end
		end
	end
	table.sort(farms, function(a, b)
		return  self.victoryPointManager:getTotalPoints(a.farmId) >  self.victoryPointManager:getTotalPoints(b.farmId)
	end)
	return farms, farmsById
end

function ScoreBoardFrame:getCurrentFarmId()
	local sx,ix = self.leftList:getSelectedPath()
	if sx ~= self.LEFT_SECTIONS.POINTS then 
		return
	end
	if sx == 1 and ix and self.farms[ix] then 
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
	local list = self.managers[sx](farmId)
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

function ScoreBoardFrame:onClickAdminLogin()
	self:openTextInputDialog(self.onTextInputAdminPassword, nil, self.translations.dialogs.admin, self.challengeMod:getDefaultAdminPassword())
end

function ScoreBoardFrame:onClickAdminLogout()
	self.isAdminModeActive = false
end
function ScoreBoardFrame:onClickAdminChangePassword()
	self:openTextInputDialog(self.onTextInputChangeAdminPassword, nil, self.translations.dialogs.adminChangePassword, self.challengeMod:getAdminPassword())
end

function ScoreBoardFrame:onClickChangeFarmVisibility()
	local farmId = self:getCurrentFarmId()
	if farmId == nil then 
		CmUtil.debug("No farm is selected!")
		return
	end
	self.challengeMod:changeFarmVisibility(farmId)
end

function ScoreBoardFrame:onClickChange()
	local sec,ix = self.rightList:getSelectedPath()
	local element = self:getElement(sec,ix)
	CmUtil.debug("ScoreBoardFrame onClickChange")
	if element then 
		if element:isTextInputAllowed() then
			self:openTextInputDialog(self.onTextInputChangeValue, element, element:getTitle())
		end
		element:onClick()
		self:updateLists()
	end
end

function ScoreBoardFrame:isAdminLoginButtonDisabled()
	return self.isAdminModeActive
end

function ScoreBoardFrame:isAdminLogoutButtonDisabled()
	return not self.isAdminModeActive
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
			self:updateLists()
		else 
			g_gui:showInfoDialog({
				text = string.format(self.translations.dialogs.adminWrongPassword, text)
			})
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
			self:updateLists()
		end
	end
end