ChallengeSettingsFrame = {
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

ChallengeSettingsFrame.translations = {
	attributes = {
		"Total Points: ",
		"Money Points: ",
		"Storage Points: ",
		"Area Points: ",
	},
}

ChallengeSettingsFrame.colors = {
	move = {0, 0, 0, 0.35},
	default = {0.3140, 0.8069, 1.0000, 0.02}
}

local ChallengeSettingsFrame_mt = Class(ChallengeSettingsFrame, TabbedMenuFrameElement)

function ChallengeSettingsFrame.new(courseStorage,target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or ChallengeSettingsFrame_mt)
	self:registerControls(ChallengeSettingsFrame.CONTROLS)
	self.farmManager = g_farmManager
	self.farms = {}
	return self
end


function ChallengeSettingsFrame:onGuiSetupFinished()
	ChallengeSettingsFrame:superClass().onGuiSetupFinished(self)
	

	self.leftList:setDataSource(self)
	self.rightList:setDataSource(self)
end
function ChallengeSettingsFrame:onFrameOpen()
	self:updateLists()
	ChallengeSettingsFrame:superClass().onFrameOpen(self)
end
	
function ChallengeSettingsFrame:onFrameClose()
	ChallengeSettingsFrame:superClass().onFrameClose(self)
end

function ChallengeSettingsFrame:updateLists()
	self.farms = self:getValidFarms()
	self.leftList:reloadData()
	self.rightList:reloadData()
end

function ChallengeSettingsFrame:getNumberOfItemsInSection(list, section)
	if list == self.leftList then 
		return #self.farms
	end

	local ix = self.leftList:getSelectedIndexInSection()
	if ix == nil or #self.farms==0 then 
		return 0
	end
	return ChallengeMod.numberOfPointAttributes
end


function ChallengeSettingsFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.leftList then
		cell:getAttribute("icon"):setImageUVs(nil, unpack(GuiUtils.getUVs(self.farms[index]:getIconUVs())))
		cell:getAttribute("icon"):setImageColor(nil, unpack(self.farms[index]:getColor()))
		cell:getAttribute("title"):setText(self.farms[index].name)
	else
		cell:getAttribute("title"):setText(self.translations.attributes[index])
		local id = self:getCurrentFarmId()
		if id then 
			cell:getAttribute("value"):setText(string.format("%.1f", g_challengeMod:getPointsForFarmId(id)[index]))
		end
	end
end

function ChallengeSettingsFrame:onListSelectionChanged(list, section, index)
	if list == self.leftList then 
		self.rightList:reloadData()
	end
end

function ChallengeSettingsFrame:getValidFarms()
	local farms, farmsById = {}, {}
	for i, farm in pairs(self.farmManager:getFarms()) do 
		if CmUtil.isValidFarm(farm.farmId, farm) then 
			table.insert(farms, farm)
			farmsById[farm.farmId] = farm
		end
	end
	return farms, farmsById
end

function ChallengeSettingsFrame:getCurrentFarmId()
	local ix = self.leftList:getSelectedIndexInSection()
	if ix and self.farms[ix] then 
		return self.farms[ix].farmId
	end
end