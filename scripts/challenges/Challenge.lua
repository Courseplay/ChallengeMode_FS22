
---@class Challenge
Challenge = {
	nextUniqueId = 0,
	xmlAttributes = {
		victoryPointModifier = "#victoryPointModifier",
		victoryPointGoal = "#victoryPointModifier",
		className = "#className",
		name = "#name"
	},
	classByName = {
		MaxMoneyChallenge = MaxMoneyChallenge,
		MaxFruitStorageChallenge = MaxFruitStorageChallenge,
		MaxFieldAreaChallenge = MaxFieldAreaChallenge
	}
}
local Challenge_mt = Class(Challenge)

function Challenge.registerXmlSetupSchema(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. Challenge.xmlAttributes.victoryPointModifier, "Victory point modifier", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. Challenge.xmlAttributes.victoryPointGoal, "Victory goal")
	schema:register(XMLValueType.STRING, baseKey .. Challenge.xmlAttributes.className, "Class name")
	schema:register(XMLValueType.STRING, baseKey .. Challenge.xmlAttributes.name, "Name")
end

function Challenge.registerXmlSchema(schema, baseKey)
	MaxFieldAreaChallenge.registerXmlSchema(schema, baseKey)
	MaxFruitStorageChallenge.registerXmlSchema(schema, baseKey)
	MaxMoneyChallenge.registerXmlSchema(schema, baseKey)
end

function Challenge.createFromSetup(xmlFile, baseKey, isServer)
	local className = xmlFile:getValue(baseKey .. Challenge.xmlAttributes.className)
	local name = xmlFile:getValue(baseKey .. Challenge.xmlAttributes.name)
	if className then 
		---@type Challenge
		local challenge = Challenge.classByName[className].new(isServer, name)
		challenge:loadSetup(xmlFile, baseKey)
		return challenge
	else 
		CmUtil.debug("class name was not found!")
	end
end

function Challenge.new(isServer, name, customMt)
	---@type Challenge
	local self = setmetatable({}, customMt or Challenge_mt)
	self.isServer = isServer
	self.name = name
	self.id = self:getNextId()
	self.victoryPointModifier = 1
	self.victoryPointGoal = nil
	return self
end

function Challenge:loadSetup(xmlFile, baseKey)
	self.victoryPointModifier = xmlFile:getValue(baseKey .. self.xmlAttributes.victoryPointModifier, 1)
	self.victoryPointGoal = xmlFile:getValue(baseKey .. self.xmlAttributes.victoryPointGoal)
end

function Challenge:getNextId()
	local id = Challenge.nextUniqueId
	Challenge.nextUniqueId = id + 1 
	return id
end

function Challenge:getName()
	return self.name
end

function Challenge:getId()
	return self.id
end

function Challenge:writeStream(streamId, connection)
	--- override
end

function Challenge:readStream(streamId, connection)
	--- override
end

function Challenge:saveToXml(xmlFile, baseKey)
	--- override
end

function Challenge:loadFromXml(xmlFile, baseKey)
	--- override
end

function Challenge:reset()
	
end

function Challenge:update(dt)
	--- override
end

function Challenge:getVictoryPointModifier()
	return self.victoryPointModifier
end

function Challenge:getVictoryPointGoal()
	return self.victoryPointGoal
end

function Challenge:getHasVictoryPointGoal()
	return self.victoryPointGoal ~= nil
end

function Challenge:getCompletionStatus()
	--- override
end