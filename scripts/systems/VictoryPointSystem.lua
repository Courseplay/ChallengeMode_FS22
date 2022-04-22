---@class VictoryPointSystem
VictoryPointSystem = {
	
}
local VictoryPointSystem_mt = Class(VictoryPointSystem)

function VictoryPointSystem.registerXmlSetupSchema(schema, baseKey)
	
end

function VictoryPointSystem.registerXmlSchema(schema, baseKey)
	
end

function VictoryPointSystem.new(isServer, name)
	---@type VictoryPointSystem
	local self = setmetatable({}, VictoryPointSystem_mt)
	self.isServer = isServer

	self.managers = {}
	self.managersByUserId = {}
	return self
end

function VictoryPointSystem:addPlayer(connection)
	local user, userId = CmUtil.getUniqueUserByConnection(connection)
	local manager = VictoryPointManager.new(self.isServer, user)
	table.insert(self.managers, manager)
	self.managersByUserId[userId] = manager
end

function VictoryPointSystem:removePlayer(connection)
	local user, userId = CmUtil.getUniqueUserByConnection(connection)
	local manager = self.managersByUserId[userId] 
	if manager then 
		for i=#self.managers, 1, -1 do 
			if self.managers[i] == manager then 
				table.remove(self.managers, i)
			end
		end
		manager:delete()
	end
	self.managersByUserId[userId] = nil
end

function VictoryPointSystem:writeStream(streamId, connection)
	
end

function VictoryPointSystem:readStream(streamId, connection)
	
end

function VictoryPointSystem:saveToXml(xmlFile, baseKey)
	
end

function VictoryPointSystem:loadFromXml(xmlFile, baseKey)
	
end
