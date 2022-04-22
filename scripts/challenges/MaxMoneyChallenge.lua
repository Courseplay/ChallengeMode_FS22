
---@class MaxMoneyChallenge : Challenge
MaxMoneyChallenge = {
	nextUniqueId = 0,
	xmlAttributes = {
		moneySinceStart = "moneySinceStart",

	}
}
local MaxMoneyChallenge_mt = Class(MaxMoneyChallenge, Challenge)

function MaxMoneyChallenge.registerXmlSchema(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. MaxMoneyChallenge.xmlAttributes.moneySinceStart,
					 "Money change since start off the challenge.", 0)
end

function MaxMoneyChallenge.new(isServer, name)
	---@type MaxMoneyChallenge
	local self = Challenge.new(isServer, name, MaxMoneyChallenge_mt)
	self.moneySinceStart = 0
	return self
end

function MaxMoneyChallenge:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.moneySinceStart)
end

function MaxMoneyChallenge:readStream(streamId, connection)
	self.moneySinceStart = streamReadInt32(streamId)
end

function MaxMoneyChallenge:saveToXml(xmlFile, baseKey)
	xmlFile:setValue(baseKey .. self.xmlAttributes.moneySinceStart, self.moneySinceStart)
end

function MaxMoneyChallenge:loadFromXml(xmlFile, baseKey)
	self.moneySinceStart = xmlFile:getValue(baseKey .. self.xmlAttributes.moneySinceStart, 0)
end

