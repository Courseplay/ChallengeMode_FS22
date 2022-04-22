---@class ChallengeSystem
ChallengeSystem = {
	
}
local ChallengeSystem_mt = Class(ChallengeSystem)

function ChallengeSystem.registerXmlSetupSchema(schema, baseKey)
	
end

function ChallengeSystem.registerXmlSchema(schema, baseKey)
	
end

function ChallengeSystem.new(isServer, name)
	---@type ChallengeSystem
	local self = setmetatable({}, ChallengeSystem_mt)
	self.isServer = isServer
	return self
end


function ChallengeSystem:writeStream(streamId, connection)
	
end

function ChallengeSystem:readStream(streamId, connection)
	
end

function ChallengeSystem:saveToXml(xmlFile, baseKey)
	
end

function ChallengeSystem:loadFromXml(xmlFile, baseKey)
	
end
