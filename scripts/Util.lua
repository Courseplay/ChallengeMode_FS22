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