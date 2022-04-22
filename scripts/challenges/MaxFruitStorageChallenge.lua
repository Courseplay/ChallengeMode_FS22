
---@class MaxFruitStorageChallenge : Challenge
MaxFruitStorageChallenge = {
	nextUniqueId = 0,
	xmlAttributes = {
		literSinceStart = "literSinceStart",

	}
}
local MaxFruitStorageChallenge_mt = Class(MaxFruitStorageChallenge, Challenge)

function MaxFruitStorageChallenge.registerXmlSchema(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. MaxFruitStorageChallenge.xmlAttributes.literSinceStart,
					 "Money change since start off the challenge.", 0)
end

function MaxFruitStorageChallenge.new(isServer, name)
	---@type MaxFruitStorageChallenge
	local self = Challenge.new(isServer, name, MaxFruitStorageChallenge_mt)
	self.literStoredSinceStart = 0
	return self
end

function MaxFruitStorageChallenge:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.literStoredSinceStart)
end

function MaxFruitStorageChallenge:readStream(streamId, connection)
	self.literStoredSinceStart = streamReadFloat32(streamId)
end

function MaxFruitStorageChallenge:saveToXml(xmlFile, baseKey)
	xmlFile:setValue(baseKey .. self.xmlAttributes.literSinceStart, self.literStoredSinceStart)
end

function MaxFruitStorageChallenge:loadFromXml(xmlFile, baseKey)
	self.literStoredSinceStart = xmlFile:getValue(baseKey .. self.xmlAttributes.literSinceStart, 0)
end

