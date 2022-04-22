---@class Manager
Manager = {
	modName = g_currentModName,
	modDir = g_currentModDirectory,
	---@type table<i,Manager>
	managers = {}
}
local Manager_mt = Class(Manager)
function Manager.new(isServer, user, customMt)
	---@type Manager
	local self = setmetatable({}, customMt or Manager_mt)
	self.user = user
	self.isServer = isServer

	table.insert(Manager.managers, self)
	return self
end


function Manager:writeStream(streamId, connection, objects)
	for i, obj in ipairs(objects) do 
		obj:writeStream(streamId, connection)
	end
end

function Manager:readStream(streamId, connection, objects)
	for i, obj in ipairs(objects) do 
		obj:readStream(streamId, connection)
	end
end

function Manager:saveToXml(xmlFile, baseKey, objects)
	for i, obj in ipairs(objects) do 
		obj:saveToXml(xmlFile, baseKey)
	end
end

function Manager:loadFromXml(xmlFile, baseKey, objects)
	for i, obj in ipairs(objects) do 
		obj:loadFromXml(xmlFile, baseKey)
	end
end

function Manager:delete()
	
end