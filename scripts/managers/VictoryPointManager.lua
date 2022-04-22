
---@class VictoryPointManager : Manager
VictoryPointManager = {
	modName = g_currentModName,
	modDir = g_currentModDirectory,
}
VictoryPointManager.xmlRootKey = "VictoryPointManager"
VictoryPointManager.baseKey = VictoryPointManager.xmlRootKey .. "VictoryPoints"

local VictoryPointManager_mt = Class(VictoryPointManager, Manager)

function VictoryPointManager.registerXmlSetupSchema()
	VictoryPointManager.xmlSetupSchema = XMLSchema.new("VictoryPointManagerSetupXmlSchema")
	Challenge.registerXmlSetupSchema(VictoryPointManager.xmlSetupSchema, VictoryPointManager.baseKey .. "(?)")
end

function VictoryPointManager.registerXmlSchema(schema, baseKey)
	Challenge.registerXmlSetupSchema(schema, baseKey .. VictoryPointManager.baseKey .. "(?)")
end

function VictoryPointManager.new(isServer, user, customMt)
	---@type VictoryPointManager
	local self = Manager.new(isServer, user, customMt or VictoryPointManager_mt)
	
	self.points = 0
	return self
end

function VictoryPointManager:writeStream(streamId, connection)
	
end

function VictoryPointManager:readStream(streamId, connection)
	
end

function VictoryPointManager:saveToXml(xmlFile, baseKey)

end

function VictoryPointManager:loadFromXml(xmlFile, baseKey)
	
end

