
---@class Rule
Rule = {
	nextUniqueId = 0,
	xmlAttributes = {
		enabled = "#enabled",
		className = "#className",
		name = "#name"
	},
	classByName = {
		MaxMoneyChallenge = MaxMoneyChallenge,
		MaxFruitStorageChallenge = MaxFruitStorageChallenge,
		MaxFieldAreaChallenge = MaxFieldAreaChallenge
	}
}
local Rule_mt = Class(Rule)

function Rule.registerXmlSetupSchema(schema, baseKey)
	schema:register(XMLValueType.BOOL, baseKey .. Rule.xmlAttributes.enabled, "Is the rule enabled ?", false)
	schema:register(XMLValueType.STRING, baseKey .. Rule.xmlAttributes.className, "class name")
	schema:register(XMLValueType.STRING, baseKey .. Rule.xmlAttributes.name, "name")
end

function Rule.registerXmlSchema(schema, baseKey)
	schema:register(XMLValueType.BOOL, baseKey .. Rule.xmlAttributes.enabled, "Is the rule enabled ?", false)
end

function Rule.createFromSetup(xmlFile, baseKey, isServer)
	local className = xmlFile:getValue(baseKey .. Rule.xmlAttributes.className)
	local name = xmlFile:getValue(baseKey .. Rule.xmlAttributes.name)
	if className then 
		---@type Rule
		local rule = Rule.classByName[className].new(isServer, name)
		rule:loadSetup(xmlFile, baseKey)
		return rule
	else 
		CmUtil.debug("class name was not found!")
	end
end

function Rule.new(isServer, name, customMt)
	---@type Rule
	local self = setmetatable({}, customMt or Rule_mt)
	self.isServer = isServer
	self.name = name
	self.id = self:getNextId()
	self.enabled = false
	return self
end

function Rule:loadSetup(xmlFile, baseKey)
	self.enabled = xmlFile:getValue(baseKey .. self.xmlAttributes.enabled, false)
end

function Rule:getNextId()
	local id = Rule.nextUniqueId
	Rule.nextUniqueId = id + 1 
	return id
end

function Rule:getName()
	return self.name
end

function Rule:getId()
	return self.id
end

function Rule:isDisabled()
	return not self.enabled
end

function Rule:isEnabled()
	return self.enabled
end

function Rule:writeStream(streamId, connection)
	streamWriteBool(streamId, self.enabled)
end

function Rule:readStream(streamId, connection)
	self.enabled = streamReadBool(streamId)
end

function Rule:saveToXml(xmlFile, baseKey)
	xmlFile:setValue(baseKey .. self.xmlAttributes.enabled, self.enabled)
end

function Rule:loadFromXml(xmlFile, baseKey)
	self.enabled = xmlFile:getValue(baseKey .. self.xmlAttributes.enabled, false)
end
