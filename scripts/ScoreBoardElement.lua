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

function ScoreBoardElement:getName()
	return self.name	
end

function ScoreBoardElement:setCategory(category)
	self.category = category	
end

function ScoreBoardElement:onTextInput(value)
		
end

function ScoreBoardElement:isTextInputAllowed()
	return false
end

function ScoreBoardElement:onClick()
		
end

function ScoreBoardElement:saveToXMLFile(xmlFile, baseXmlKey)
	
end

function ScoreBoardElement:loadFromXMLFile(xmlFile, baseXmlKey)
	
end
