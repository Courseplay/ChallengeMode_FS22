PayToSpyEvent = {}
PayToSpyEvent_mt = Class(PayToSpyEvent, Event)

InitEventClass(PayToSpyEvent, "PayToSpyEvent")

function PayToSpyEvent.emptyNew()
    return Event.new(PayToSpyEvent_mt)
end

function PayToSpyEvent.new(money, farmId)
    local self = PayToSpyEvent.emptyNew()

    self.money = money
    self.farmId = farmId

    return self
end

function PayToSpyEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.money)
    streamWriteInt8(streamId, self.farmId)
end

function PayToSpyEvent:readStream(streamId, connection)
    self.money = streamReadInt32(streamId)
    self.farmId = streamReadInt8(streamId)

    self:run(connection)
end

function PayToSpyEvent: run(connection)
    if not connection:getIsServer() then
        g_currentMission:addMoney(self.money, self.farmId, MoneyType.OTHER, true, true)

        g_server:broadcastEvent(self, true)
    end
end