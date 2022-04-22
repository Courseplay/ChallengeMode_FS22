---@class RuleSystem
RuleSystem = {
	
}
local RuleSystem_mt = Class(RuleSystem)

function RuleSystem.registerXmlSetupSchema(schema, baseKey)
	
end

function RuleSystem.registerXmlSchema(schema, baseKey)
	
end

function RuleSystem.new(isServer)
	---@type RuleSystem
	local self = setmetatable({}, RuleSystem_mt)
	self.isServer = isServer
	return self
end


function RuleSystem:writeStream(streamId, connection)
	
end

function RuleSystem:readStream(streamId, connection)
	
end

function RuleSystem:saveToXml(xmlFile, baseKey)
	
end

function RuleSystem:loadFromXml(xmlFile, baseKey)
	
end
