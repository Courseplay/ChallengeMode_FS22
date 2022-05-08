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
	},
}

ScoreBoardFrame.translations = {
	attributes = {
		"Money Points: ",
		"Storage Points: ",
		"Area Points: ",
	},
	factors = {
		function (money)
			return string.format("%f/%s", g_i18n:getCurrency(money), g_i18n:getCurrencySymbol(true))
		end,
		function (liters)
			return string.format("%f/%s", g_i18n:getFluid(liters), g_i18n:getText("unit_literShort"))
		end,
		function (area)
			return string.format("%f/%s", g_i18n:getArea(area), g_i18n:getAreaUnit())
		end
	}
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
	self.farms = {}
	return self
end


function ScoreBoardFrame:onGuiSetupFinished()
	ScoreBoardFrame:superClass().onGuiSetupFinished(self)
	

	self.leftList:setDataSource(self)
	self.rightList:setDataSource(self)
end
function ScoreBoardFrame:onFrameOpen()
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
end

function ScoreBoardFrame:getNumberOfItemsInSection(list, section)
	if list == self.leftList then 
		return #self.farms
	end

	local ix = self.leftList:getSelectedIndexInSection()
	if ix == nil or #self.farms==0 then 
		return 0
	end
	return ChallengeMod.numberOfPointAttributes
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
			cell:getAttribute("value"):setText(string.format("%.1f", self.challengeMod:getTotalPointsForFarmId(self.farms[index].farmId)))
		end
	else
		local id = self:getCurrentFarmId()
		cell:getAttribute("title"):setText(self.translations.attributes[index])
		if id then 
			cell:getAttribute("value"):setText(string.format("%.1f",  self.challengeMod:getPointsForFarmId(id)[index]))

			cell:getAttribute("conversionValue"):setText(self.translations.factors[index](self.challengeMod:getPointFactors()[index]))
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
		return  self.challengeMod:getTotalPointsForFarmId(a.farmId) >  self.challengeMod:getTotalPointsForFarmId(b.farmId)
	end)
	return farms, farmsById
end

function ScoreBoardFrame:getCurrentFarmId()
	local ix = self.leftList:getSelectedIndexInSection()
	if ix and self.farms[ix] then 
		return self.farms[ix].farmId
	end
end