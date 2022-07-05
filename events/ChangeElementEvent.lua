ChangeElementEvent = {
	TYPES = {
		VictoryPoint,
		Rule,
	},
	SEND_NUM_BITS = 2,
	POINT = 1,
	RULE = 2
}
local ChangeElementEvent_mt = Class(ChangeElementEvent, Event)

InitEventClass(ChangeElementEvent, "ChangeElementEvent")

function ChangeElementEvent.emptyNew()
	return Event.new(ChangeElementEvent_mt)
end
---@class ChangeElementEvent
function ChangeElementEvent.new(element, type)
	local self = ChangeElementEvent.emptyNew()
	self.element = element
	self.type = type
	return self
end

function ChangeElementEvent:readStream(streamId, connection)
	local type = streamReadUIntN(streamId, self.SEND_NUM_BITS)
	CmUtil.debug("ChangeElementEvent readStream type: %s", type)
	local function getElement()
		local e = self.TYPES[type].readStream(streamId, connection)
		return e
	end
	local element = CmUtil.try(getElement)
	self:run(connection, element, type)
end

function ChangeElementEvent:writeStream(streamId, connection)
	CmUtil.debug("ChangeElementEvent writeStream type: %s ", self.type)
	streamWriteUIntN(streamId, self.type, self.SEND_NUM_BITS)
	self.element:writeStream(streamId, connection)
end

function ChangeElementEvent:run(connection, element, type)
	if not connection:getIsServer() then
		g_server:broadcastEvent(ChangeElementEvent.new(element, type), nil, connection)
	end
end

function ChangeElementEvent.sendEvent(element, type)
	if g_server ~= nil then
		g_server:broadcastEvent(ChangeElementEvent.new(element, type))
	else
		g_client:getServerConnection():sendEvent(ChangeElementEvent.new(element, type))
	end
end
