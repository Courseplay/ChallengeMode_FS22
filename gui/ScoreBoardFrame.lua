ScoreBoardFrame = {
	CONTROLS = {
		HEADER = "header",
		MAIN_BOC = "mainBox",
		LEFT_COLUMN = "leftColumn",
		RIGHT_COLUMN = "rightColumn",
		CHANGELOG_COLUMN = "changelogColumn",
		LEFT_LIST = "leftList",
		RIGHT_LIST = "rightList",
		CHANGELOG_LIST = "changelogList",
		LEFT_COLUMN_HEADER = "leftColumnHeader",
		RIGHT_COLUMN_HEADER = "rightColumnHeader",
		GOAL = "goal",
		RIGHT_LIST_MIDDLE_TITLE = "rightList_middleTitle",
		RIGHT_LIST_RIGHT_TITLE = "rightList_rightTitle",
		CHANGELOG_LEFT_TITLE = "changelogList_leftTitle",
		CHANGELOG_MIDDLE_TITLE = "changelogList_middleTitle",
		CHANGELOG_RIGHT_TITLE = "changelogList_rightTitle"
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
		changeFarmVisibility = g_i18n:getText("CM_menuBtn_changeFarmVisibility"),
		showChangelog = g_i18n:getText("CM_menuBtn_showChangelog"),
		hideChangelog = g_i18n:getText("CM_menuBtn_hideChangelog"),
		addPoints = g_i18n:getText("CM_menuBtn_addPoints")
	},
	dialogs = {
		admin = g_i18n:getText("CM_dialog_adminTitle"),
		adminChangePassword = g_i18n:getText("CM_dialog_adminChangePasswordTitle"),
		adminWrongPassword = g_i18n:getText("CM_dialog_adminWrongPassword"),
		value = g_i18n:getText("CM_dialog_changeTitle"),
		newGoal = g_i18n:getText("CM_dialog_newGoal")
	},
	leftSections = {
		"",
		g_i18n:getText("CM_leftList_section_two"),
	},
	changelogSections = {
		g_i18n:getText("CM_changelogList_userName"),
		g_i18n:getText("CM_changelogList_date"),
		g_i18n:getText("CM_changelogList_addedPoints")
	}

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
	self.showChangelog = false
	self.selectedList = self.leftList

	return self
end

function ScoreBoardFrame:onGuiSetupFinished()
	ScoreBoardFrame:superClass().onGuiSetupFinished(self)

	self.leftList:setDataSource(self)
	self.rightList:setDataSource(self)

	-- Save the current selected list to decide which buttons will be shown and which not
	local orig = self.leftList.onFocusEnter
	function self.leftList.onFocusEnter(...)
		orig(...)

		self:onFocusEnterList(self.leftList)
	end

	orig = self.rightList.onFocusEnter
	function self.rightList.onFocusEnter(...)
		orig(...)

		self:onFocusEnterList(self.rightList)
	end

	orig = self.changelogList.onFocusEnter
	function self.changelogList.onFocusEnter(...)
		orig(...)

		self:onFocusEnterList(self.changelogList)
	end

	self.menuButtons = {
		{
			inputAction = InputAction.MENU_BACK,
		},
		--- Login as admin button.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_ACCEPT,
			text = self.translations.menuButtons.adminLogin,
			callback = function()
				self:onClickAdminLogin()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isAdminLogoutButtonDisabled,
		},
		--- Logout admin button.
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACCEPT,
			text = self.translations.menuButtons.adminLogout,
			callback = function()
				self:onClickAdminLogout()
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isAdminLoginButtonDisabled,
		},
		--- Change admin password.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_EXTRA_2,
			text = self.translations.menuButtons.adminChangePassword,
			callback = function()
				self:onClickAdminChangePassword()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isAdminLoginButtonDisabled,
		},
		--- Changes a value button.
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.translations.menuButtons.change,
			callback = function()
				CmUtil.try(self.onClickChange, self)
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isChangeButtonEnabled,
		},
		--- Shows dialog to add points to selected farm
		{
			profile = "buttonSelect",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.translations.menuButtons.addPoints,
			callback = function()
				CmUtil.try(self.onClickAddPoints, self)
				self:updateMenuButtons()
				self:updateLists()
			end,
			callbackEnabled = self.isAddPointsButtonEnabled,
		},
		--- Changes farm visibility.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_EXTRA_1,
			text = self.translations.menuButtons.changeFarmVisibility,
			callback = function()
				self:onClickChangeFarmVisibility()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isAddPointsButtonEnabled,
		},
		--- Show all point changes for the selected farm.
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_CANCEL,
			text = self.translations.menuButtons.showChangelog,
			callback = function ()
				self:onClickShowChangelog()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isShowChangelogButtonEnabled
		},
		--- Hide point changes for selected farm
		{
			profile = "buttonActivate",
			inputAction = InputAction.MENU_CANCEL,
			text = self.translations.menuButtons.hideChangelog,
			callback = function ()
				self:onClickHideChangelog()
				self:updateMenuButtons()
			end,
			callbackEnabled = self.isHideChangelogButtonEnabled
		}
	}
	self.managers = {
		function(...)
			return self.victoryPointManager:getList(...)
		end,
		function(...)
			local sx, ix = self.leftList:getSelectedPath()
			return ix == 1 and self.ruleManager:getList() or self.victoryPointManager:getList()
		end,
	}

	self.numSections = {
		[self.leftList] = function() return self.NUM_LEFT_SECTIONS end,
		[self.rightList] = function()
			local sx, ix = self.leftList:getSelectedPath()
			return self.managers[sx]():getNumberOfElements()
		end,
		[self.changelogList] = function ()
			return 1
		end
	}
	self.sectionTitles = {
		[self.leftList] = function(sx)
			return self.translations.leftSections[sx]
		end,
		[self.rightList] = function(rsx)
			local sx, ix = self.leftList:getSelectedPath()
			return self.managers[sx]():getElement(rsx):getTitle()
		end,
		[self.changelogList] = function (sx)
			return self.translations.changelogSections[sx]
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
	self.goal:setText(self.translations.goal(self.victoryPointManager:getGoal()))
	self.rightList_middleTitle:setText(titles[2])
	self.rightList_rightTitle:setText(titles[3])
end

function ScoreBoardFrame:updateMenuButtons()
	self.menuButtonInfo = {}
	for i, btn in pairs(self.menuButtons) do
		if btn.callbackEnabled == nil and btn.callbackEnabled(self) then
			table.insert(self.menuButtonInfo, btn)
		end
	end
	self:setMenuButtonInfoDirty()

	self.goal:setDisabled(not g_challengeMod.isAdminModeActive, false)

	self.goal.overlay.alpha = 0
	self.goal.textDisabledColor = self.goal.textColor
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
			return g_challengeMod.isAdminModeActive and self.NUM_SETTINGS_ADMIN or self.NUM_SETTINGS
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
			if self.farms[index] then -- and self.farms[index].farmId == g_currentMission.player.farmId then
				if self.farms[index]:getIconUVs() ~= nil then
					cell:getAttribute("icon"):setImageUVs(nil, unpack(GuiUtils.getUVs(self.farms[index]:getIconUVs())))
				end
				if self.farms[index]:getColor() ~= nil then
					cell:getAttribute("icon"):setImageColor(nil, unpack(self.farms[index]:getColor()))
				end
				cell:getAttribute("title"):setText(self.farms[index].name)
				cell:getAttribute("value"):setText(string.format("%.1f",
					self.victoryPointManager:getTotalPoints(self.farms[index].farmId)))
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
		if not self.showChangelog then
			self.rightList:reloadData()
		else
			self.changelogList:reloadData()
		end
	end
	self:updateMenuButtons()
	self:updateTitles()
end

function ScoreBoardFrame:onFocusEnterList(list)
	if self.selectedList ~= nil then 
		self.selectedList:clearElementSelection()
	end
	self.selectedList = list

	if list == self.leftList and list:getSelectedSection() ~= 1 then
		self.showChangelog = false

		self:updateMenuButtons()
	end
end

function ScoreBoardFrame:onDoubleClickCallback(list, section, index, cell)
	print("double clicked cell")
end

function ScoreBoardFrame:getValidFarms()
	local farms, farmsById = {}, {}
	for i, farm in pairs(self.farmManager:getFarms()) do
		if CmUtil.isValidFarm(farm.farmId, farm) then
			if g_challengeMod.isAdminModeActive or self.challengeMod:getIsFarmVisible(farm.farmId) then
				table.insert(farms, farm)
				farmsById[farm.farmId] = farm
			end
		end
	end
	table.sort(farms, function(a, b)
		return self.victoryPointManager:getTotalPoints(a.farmId) > self.victoryPointManager:getTotalPoints(b.farmId)
	end)
	return farms, farmsById
end

function ScoreBoardFrame:getCurrentFarmId()
	local sx, ix = self.leftList:getSelectedPath()
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

	return list:getElement(section, index)
end

function ScoreBoardFrame:updateRightColumn()
	self.rightColumn:setVisible(not self.showChangelog)
	self.changelogColumn:setVisible(self.showChangelog)
end

----------------------------------------------------
--- Button callbacks
----------------------------------------------------

function ScoreBoardFrame:onClickAdminLogin()
	self:openTextInputDialog(self.onTextInputAdminPassword, nil, self.translations.dialogs.admin,
		self.challengeMod:getDefaultAdminPassword())
end

function ScoreBoardFrame:onClickAdminLogout()
	g_challengeMod.isAdminModeActive = false
end

function ScoreBoardFrame:onClickAdminChangePassword()
	self:openTextInputDialog(self.onTextInputChangeAdminPassword, nil, self.translations.dialogs.adminChangePassword,
		self.challengeMod:getAdminPassword())
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
	local sec, ix = self.rightList:getSelectedPath()
	local element = self:getElement(sec, ix)
	CmUtil.debug("ScoreBoardFrame onClickChange")
	if element then
		if element:isTextInputAllowed() then
			self:openTextInputDialog(self.onTextInputChangeValue, element, element:getInputText())
		end
		element:onClick()
		self:updateLists()
	end
end

function ScoreBoardFrame:onClickAddPoints()
	if self.selectedList ~= self.leftList or self.selectedList:getSelectedSection() ~= self.LEFT_SECTIONS.POINTS then
		print("Error: Can't change points of no farm")
		return
	end

	local farmId = self:getCurrentFarmId()
	self:showAddPointsDialog(farmId)
end

function ScoreBoardFrame:onClickSetGoal()
	self:openTextInputDialog(self.onTextInputChangeGoal, nil, self.translations.dialogs.newGoal)
end

function ScoreBoardFrame:onClickShowChangelog()
	self.showChangelog = true

	self:updateRightColumn()
end

function ScoreBoardFrame:onClickHideChangelog()
	self.showChangelog = false

	self:updateRightColumn()
end

function ScoreBoardFrame:isAdminLoginButtonDisabled()
	return g_challengeMod.isAdminModeActive
end

function ScoreBoardFrame:isAdminLogoutButtonDisabled()
	return not g_challengeMod.isAdminModeActive
end

function ScoreBoardFrame:isAdminChangePasswordButtonDisabled()
	return not g_challengeMod.isAdminModeActive
end

function ScoreBoardFrame:isChangeButtonEnabled()
	return g_challengeMod.isAdminModeActive and self.selectedList == self.rightList
end

function ScoreBoardFrame:isAddPointsButtonEnabled()
	return g_challengeMod.isAdminModeActive and self.selectedList == self.leftList and self.selectedList:getSelectedSection() == self.LEFT_SECTIONS.POINTS
end

function ScoreBoardFrame:isShowChangelogButtonEnabled()
	return not self.showChangelog and self.selectedList == self.leftList and self.selectedList:getSelectedSection() == self.LEFT_SECTIONS.POINTS
end

function ScoreBoardFrame:isHideChangelogButtonEnabled()
	return self.showChangelog
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

function ScoreBoardFrame:showAddPointsDialog(farmId)
	local dialog = g_gui.guis.AddPointsDialog

	if dialog ~= nil then
		dialog.target:setCallback(self.onTextInputAddPoints, self, farmId)

		g_gui:showDialog("AddPointsDialog")
	end
end

function ScoreBoardFrame:onTextInputAdminPassword(text, clickOk)
	if clickOk then
		if text == self.challengeMod:getAdminPassword() then
			g_challengeMod.isAdminModeActive = true
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

function ScoreBoardFrame:onTextInputAddPoints(points, reason, clickOk, farmId)
	if clickOk then
		local point = CmUtil.createAdditionalPoint(points, g_currentMission.playerNickname, reason)

		g_victoryPointManager:addAdditionalPoint(farmId, point)
		self:updateLists()
	end
end

function ScoreBoardFrame:onTextInputChangeGoal(text, clickOk)
	if clickOk then
		self.victoryPointManager:setGoal(tonumber(text))
		self:updateTitles()
		self:updateLists()
		self:updateMenuButtons()
		self.goal.overlayState = GuiOverlay.STATE_NORMAL
	end
end