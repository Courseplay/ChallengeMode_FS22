
ScoreBoardCategory = {}

local ScoreBoardCategory_mt = Class(ScoreBoardCategory)
---@class ScoreBoardCategory
function ScoreBoardCategory.new(name, title, elements, custom_mt)
	local self = setmetatable({}, custom_mt or ScoreBoardCategory_mt)	
	self.title = title
	self.name = name
	self.elements = elements or {}
	return self
end

function ScoreBoardCategory.registerXmlSchema(xmlSchema, baseXmlKey)
	xmlSchema:register(XMLValueType.STRING, baseXmlKey .. ".Category(?)#name", "Category name")
	ScoreBoardElement.registerXmlSchema(xmlSchema, baseXmlKey .. ".Category(?)")
end

function ScoreBoardCategory:getTitle()
	return self.title
end

function ScoreBoardCategory:getName()
	return self.name
end

function ScoreBoardCategory:setParent(parent, id)
	self.parent = parent
	self.id = id
end

function ScoreBoardCategory:getParent()
	return self.parent
end

function ScoreBoardCategory:addElement(element, ix)
	if ix ~= nil then 
		table.insert(self.elements, ix, element)
	else
		table.insert(self.elements, element)
	end
	element:setParent(self, ix or #self.elements)
end

function ScoreBoardCategory:getElement(index)
	return index ~= nil and self.elements[index] or self
end

function ScoreBoardCategory:getElementByName(name)
	if name == nil then
		return self
	end
	for _, element in pairs(self.elements) do
		if element:getName() == name then
			return element
		end
	end
end

function ScoreBoardCategory:getElements()
	return self.elements
end

function ScoreBoardCategory:getNumberOfElements()
	return #self.elements
end

function ScoreBoardCategory:clear()
	self.elements = {}
end

function ScoreBoardCategory:onTextInput(value)
end

function ScoreBoardCategory:isTextInputAllowed()
	return false
end

function ScoreBoardCategory:onClick()
end

function ScoreBoardCategory:saveToXMLFile(xmlFile, baseXmlKey, ix)
	local baseKey = string.format("%s.Category(%d)", baseXmlKey, ix)
	xmlFile:setValue(baseKey .. "#name", self.name)
	for i, element in ipairs(self.elements) do 
		element:saveToXMLFile(xmlFile, baseKey, i-1)
	end
end

function ScoreBoardCategory.loadFromXMLFile(list, xmlFile, baseXmlKey)
	xmlFile:iterate(baseXmlKey .. ".Category", function (ix, key)
		local name = xmlFile:getValue(key .. "#name")
		if name then
			local category = list:getElementByName(name)
			if category then 
				ScoreBoardElement.loadFromXMLFile(category, xmlFile, key)
			end
		end
	end)
end

function ScoreBoardCategory:count()
	local value = 0
	for _, element in pairs(self.elements) do
		value = value + element:count()
	end
	return value
end

function ScoreBoardCategory:clone(...)
	local category = ScoreBoardCategory.new(self.name, self.title)
	for i, element in ipairs(self.elements) do 
		local e = element:clone(...)
		category:addElement(e)
	end
	return category
end

function ScoreBoardCategory.cloneCategories(list, ...)
	local newList = {}
	for i, category in ipairs(list) do 
		local c = category:clone(...)
		table.insert(newList, c)
	end
	return newList
end

function ScoreBoardCategory:applyValues(staticList)
	local element = staticList:getElementByName(self.name)
	if element then
		for i, e in ipairs(self.elements) do
			e:applyValues(element)
		end
	end
end

function ScoreBoardCategory:writeStream(streamId, ...)
	streamWriteUInt8(streamId, #self.elements)
	for i, element in ipairs(self.elements) do
		streamWriteString(streamId, element:getName())
		element:writeJoinStream(streamId, ...)
	end
end

function ScoreBoardCategory:readStream(streamId, ...)
	for i= 1, streamReadUInt8(streamId) do
		local elementName = streamReadString(streamId)
		local e = self:getElementByName(elementName)
		e:readJoinStream(streamId, ...)
	end
end