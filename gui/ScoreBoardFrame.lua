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
	}
}

ScoreBoardFrame.translations = {
	goal = function(goal) return string.format("Goal: %d", goal) end,
	points = {
		"Money points: ",
		"Area points: ",
		"Total storage points: ",
	},
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
}

ScoreBoardFrame.colors = {
	move = {0, 0, 0, 0.35},
	default = {0.3140, 0.8069, 1.0000, 0.02}
}

local ScoreBoardFrame_mt = Class(ScoreBoardFrame, TabbedMenuFrameElement)

function ScoreBoardFrame.new(courseStorage,target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or ScoreBoardFrame_mt)
	self:registerControls(ScoreBoardFrame.CONTROLS)
	self.farmManager = g_farmManager
	self.challengeMod = g_challengeMod
	self.victoryPointManager = g_victoryPointManager
	self.farms = {}
	return self
end


function ScoreBoardFrame:onGuiSetupFinished()
	ScoreBoardFrame:superClass().onGuiSetupFinished(self)
	

	self.leftList:setDataSource(self)
	self.rightList:setDataSource(self)
end
function ScoreBoardFrame:onFrameOpen()
	g_victoryPointManager:update()
	self:updateLists()
	ScoreBoardFrame:superClass().onFrameOpen(self)
end
	
function ScoreBoardFrame:onFrameClose()
	ScoreBoardFrame:superClass().onFrameClose(self)
end

function ScoreBoardFrame:updateLists()
	self.farms = self:getValidFarms()
	self.leftList:reloadData()
	self.rightList:reloadData()
	self.goal:setText(self.translations.goal(g_victoryPointManager:getGoal()))
end

function ScoreBoardFrame:getNumberOfItemsInSection(list, section)
	if list == self.leftList then 
		return #self.farms
	end

	local ix = self.leftList:getSelectedIndexInSection()
	if ix == nil or #self.farms==0 then 
		return 0
	end
	local farmId = self:getCurrentFarmId()
	return farmId ~= nil and self.victoryPointManager:getNumberOfPointTypes(farmId) or 0
end


function ScoreBoardFrame:populateCellForItemInSection(list, section, index, cell)
	
	if list == self.leftList then
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
				--isVictoryGoalReached
		end
	else
		local id = self:getCurrentFarmId()
		if id then 
			local point = self.victoryPointManager:getPoints(id)[index]
			if point then
				cell:getAttribute("title"):setText(point:getTitle())

				cell:getAttribute("value"):setText(point:getText())

				cell:getAttribute("conversionValue"):setText(point:getFactorText())
			end
		end
	end
end

function ScoreBoardFrame:onListSelectionChanged(list, section, index)
	if list == self.leftList then 
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
	end
end