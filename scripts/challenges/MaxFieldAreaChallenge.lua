
---@class MaxFieldAreaChallenge : Challenge
MaxFieldAreaChallenge = {
	nextUniqueId = 0,
	xmlAttributes = {
		fieldAreaSinceStart = "moneySinceStart",

	}
}
local MaxFieldAreaChallenge_mt = Class(MaxFieldAreaChallenge, Challenge)

function MaxFieldAreaChallenge.registerXmlSchema(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. MaxFieldAreaChallenge.xmlAttributes.fieldAreaSinceStart,
					 "Field area acquired since start off the challenge.", 0)
end

function MaxFieldAreaChallenge.new(isServer, name)
	---@type MaxFieldAreaChallenge
	local self = Challenge.new(isServer, name, MaxFieldAreaChallenge_mt)
	self.fieldAreaSinceStart = 0
	return self
end

function MaxFieldAreaChallenge:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.fieldAreaSinceStart)
end

function MaxFieldAreaChallenge:readStream(streamId, connection)
	self.fieldAreaSinceStart = streamReadFloat32(streamId)
end

function MaxFieldAreaChallenge:saveToXml(xmlFile, baseKey)
	xmlFile:setValue(baseKey .. self.xmlAttributes.fieldAreaSinceStart, self.fieldAreaSinceStart)
end

function MaxFieldAreaChallenge:loadFromXml(xmlFile, baseKey)
	self.fieldAreaSinceStart = xmlFile:getValue(baseKey .. self.xmlAttributes.fieldAreaSinceStart, 0)
end

