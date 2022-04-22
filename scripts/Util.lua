---@class CmUtil
CmUtil = {
	debugActive = true
}

function CmUtil.debug(str, ...)
	if CmUtil.debugActive then
		print(string.format("ChallengeMode: "..str, ...))
	end
end

function CmUtil.getUniqueUserByConnection(connection)
	return g_currentMission.userManager:getUserByConnection(connection), g_currentMission.userManager:getUniqueUserIdByConnection(connection)
end