MarkStartVehicleEvent = {}

MarkStartVehicleEvent_mt = Class(MarkStartVehicleEvent, Event)

function MarkStartVehicleEvent.emptyNew()
    return Event.new(MarkStartVehicleEvent_mt)
end

function MarkStartVehicleEvent.new(vehicle, isStartVehicle)
    local self = MarkStartVehicleEvent.emptyNew()
    self.vehicle = vehicle
    self.isStartVehicle = isStartVehicle

    return self
end

function MarkStartVehicleEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isStartVehicle = streamReadBool(streamId)

    self:run(connection)
end

function MarkStartVehicleEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isStartVehicle)
end

function MarkStartVehicleEvent:run(connection)
    self.vehicle.isStartVehicle = self.isStartVehicle
end

function MarkStartVehicleEvent.sendEvent(...)
    if g_server ~= nil then
        g_server:broadcastEvent(MarkStartVehicleEvent.new(...))
    else
        g_client:getServerConnection():sendEvent(MarkStartVehicleEvent.new(...))
    end
end