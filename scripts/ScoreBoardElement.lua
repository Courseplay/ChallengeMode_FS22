ScoreBoardElement = {

}
local ScoreBoardElement_mt = Class(ScoreBoardElement)
---@class ScoreBoardElement
function ScoreBoardElement.new(name, title, custom_mt)
	local self = setmetatable({}, custom_mt or ScoreBoardElement_mt)	
	self.title = title
	self.name = name
	return self
end

function ScoreBoardElement.registerXmlSchema(xmlSchema, baseXmlKey)
	xmlSchema:register(XMLValueType.STRING, baseXmlKey .. ".Element(?)#name", "Element name")
	xmlSchema:register(XMLValueType.FLOAT, baseXmlKey .. ".Element(?)", "Element value")
end

function ScoreBoardElement:getText()
	return ""
end

function ScoreBoardElement:getTitle()
	return self.title
end

function ScoreBoardElement:getFactorText()
	return ""
end

function ScoreBoardElement:getValueToSave()
	
end

function ScoreBoardElement:setSavedValue(value)
	
end

function ScoreBoardElement:getName()
	return self.name	
end

function ScoreBoardElement:setParent(parent, id)
	self.parent = parent
	self.id = id
end

function ScoreBoardElement:getParent(parent)
	return self.parent
end

function ScoreBoardElement:onTextInput(value)
		
end

function ScoreBoardElement:isTextInputAllowed()
	return false
end

function ScoreBoardElement:onClick()
		
end

function ScoreBoardElement:saveToXMLFile(xmlFile, baseXmlKey, ix)
	local key = string.format("%s.Element(%d)", baseXmlKey, ix)
	xmlFile:setValue(key .. "#name", self.name)
	xmlFile:setValue(key, self:getValueToSave())
end

function ScoreBoardElement.loadFromXMLFile(category, xmlFile, baseXmlKey)
	xmlFile:iterate(baseXmlKey .. ".Element", function (ix, key)
		local name = xmlFile:getValue(key .. "#name")
		if name then
			local element = category:getElementByName(name)
			if element then 
				element:setSavedValue(xmlFile:getValue(key))
			end
		end
	end)
end

function ScoreBoardElement:applyValues()

end

function ScoreBoardElement:writeJoinStream(streamId, connection)
	if not self.dependency then 
		streamWriteFloat32(streamId, self:getValueToSave())
	end
end

function ScoreBoardElement:readJoinStream(streamId, connection)
	if not self.dependency then 
		self:setSavedValue(streamReadFloat32(streamId))
	end
end