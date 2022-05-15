---@class CmUtil
CmUtil = {
	debugActive = false
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
