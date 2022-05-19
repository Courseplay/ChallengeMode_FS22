---@class CmUtil
CmUtil = {
	debugActive = true
}

function CmUtil.debug(str, ...)
	if CmUtil.debugActive then
		print(string.format("ChallengeMode: "..str, ...))
	end
end

function CmUtil.debugSparse(...)
	if g_updateLoopIndex % 501 == 0 then 
		CmUtil.debug(...)
	end
end

function CmUtil.getUniqueUserByConnection(connection)
	return g_currentMission.userManager:getUserByConnection(connection), g_currentMission.userManager:getUniqueUserIdByConnection(connection)
end

function CmUtil.isValidFarm(farmId, farm)
	return true --not farm.isSpectator
end

--- Registers a config xml schema.
---@param xmlSchema table
---@param baseXmlKey string
function CmUtil.registerConfigXmlSchema(xmlSchema, baseXmlKey)

	xmlSchema:register(XMLValueType.STRING, baseXmlKey .. "#leftTitle", "Page title left")
	xmlSchema:register(XMLValueType.STRING, baseXmlKey .. "#middleTitle", "Page title middle")
	xmlSchema:register(XMLValueType.STRING, baseXmlKey .. "#rightTitle", "Page title right")

	local cKey =  string.format("%s.Category(?)", baseXmlKey)
	xmlSchema:register(XMLValueType.STRING, cKey .. "#name", "Category name")
	xmlSchema:register(XMLValueType.STRING, cKey .. "#title", "Category title")

	local eKey = string.format("%s.Element(?)", cKey)
	xmlSchema:register(XMLValueType.STRING, eKey .. "#name", "Element name")
	xmlSchema:register(XMLValueType.INT, eKey  .. "#default", "Element default value")
	xmlSchema:register(XMLValueType.STRING, eKey .. "#title", "Element title")
	xmlSchema:register(XMLValueType.STRING, eKey .. "#genericFunc", "Element generic func")
	xmlSchema:register(XMLValueType.STRING, eKey .. "#unitTextFunc", "Element unit text func")
	xmlSchema:register(XMLValueType.STRING, eKey .. "#dependency", "Element dependency on category")

	local vKey = string.format("%s.Values.Value(?)", eKey)
	xmlSchema:register(XMLValueType.INT, vKey, "Value")
	xmlSchema:register(XMLValueType.STRING, vKey .. "#name", "Value name")
	xmlSchema:register(XMLValueType.STRING, vKey .. "#text", "Value text")

end

--- Loads the config values.
---@param xmlFile table
---@param baseXmlKey string
---@return table
function CmUtil.loadConfigCategories(xmlFile, baseXmlKey)
	local categories = {}
	local titles = {
		xmlFile:getValue(baseXmlKey .. "#leftTitle",""),
		xmlFile:getValue(baseXmlKey .. "#middleTitle",""),
		xmlFile:getValue(baseXmlKey .. "#rightTitle","")
	}
	local baseKey = string.format("%s.Category", baseXmlKey)
	xmlFile:iterate(baseKey, function (ix, categoryKey)
		local category = {
			name = xmlFile:getValue(categoryKey .. "#name"),
			title = xmlFile:getValue(categoryKey .. "#title"),
			elements = {}
		}
		xmlFile:iterate(string.format("%s.Element", categoryKey), function (ix, elementKey)
			local element = {
				name = xmlFile:getValue(elementKey .. "#name"),
				default = xmlFile:getValue(elementKey .. "#default"),
				title = xmlFile:getValue(elementKey .. "#title"),
				genericFunc = xmlFile:getValue(elementKey .. "#genericFunc"),
				unitTextFunc = xmlFile:getValue(elementKey .. "#unitTextFunc"),
				dependency = xmlFile:getValue(elementKey .. "#dependency")
			}
			local values = {}
			xmlFile:iterate(string.format("%s.Values.Value", elementKey), function (ix, valueKey)
				local value = {
					value = xmlFile:getValue(valueKey, 1),
					name = xmlFile:getValue(valueKey .. "#name"),
					text = xmlFile:getValue(valueKey .. "#text"),
				}
				table.insert(values, value)
			end)
			element.values = values
			table.insert(category.elements, element)
		end)
		table.insert(categories, category)
	end)
	
	return categories, titles
end

function CmUtil.getCategoryByName(categories, name)
	for i, category in pairs(categories) do 
		if category:getName() == name then 
			return category
		end
	end
end

function CmUtil.fixInGameMenuPage(frame, pageName, image, position, predicateFunc)

	if predicateFunc == nil then 
		predicateFunc = function () return true end
	end

	local inGameMenu = g_gui.screenControllers[InGameMenu]

	-- remove all to avoid warnings
	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end

	inGameMenu:registerControls({pageName})
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

	inGameMenu:exposeControlsAsFields(pageName)
	if position ~= nil then
		for i = 1, #inGameMenu.pagingElement.elements do
			local child = inGameMenu.pagingElement.elements[i]
			if child == inGameMenu[pageName] then
				table.remove(inGameMenu.pagingElement.elements, i)
				table.insert(inGameMenu.pagingElement.elements, position, child)
				break
			end
		end

		for i = 1, #inGameMenu.pagingElement.pages do
			local child = inGameMenu.pagingElement.pages[i]
			if child.element == inGameMenu[pageName] then
				table.remove(inGameMenu.pagingElement.pages, i)
				table.insert(inGameMenu.pagingElement.pages, position, child)
				break
			end
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	inGameMenu:addPageTab(inGameMenu[pageName],image.path, GuiUtils.getUVs(image.uvs))
	inGameMenu[pageName]:applyScreenAlignment()
	inGameMenu[pageName]:updateAbsolutePosition()
	if position ~= nil then
		for i = 1, #inGameMenu.pageFrames do
			local child = inGameMenu.pageFrames[i]
			if child == inGameMenu[pageName] then
				table.remove(inGameMenu.pageFrames, i)
				table.insert(inGameMenu.pageFrames, position, child)
				break
			end
		end
	end

	inGameMenu:rebuildTabList()
end