
ScoreBoardList = {}

local ScoreBoardList_mt = Class(ScoreBoardList)
---@class ScoreBoardList
function ScoreBoardList.new(name, titles, elements, custom_mt)
	local self = setmetatable({}, custom_mt or ScoreBoardList_mt)	
	self.titles = titles
	self.name = name
	self.elements = elements or {}
	return self
end

function ScoreBoardList:getTitles()
	return self.titles
end

function ScoreBoardList:getName()
	return self.name
end

function ScoreBoardList.registerXmlSchema(xmlSchema, baseXmlKey)
	xmlSchema:register(XMLValueType.STRING, baseXmlKey .. ".List(?)#name", "List name")
	ScoreBoardCategory.registerXmlSchema(xmlSchema, baseXmlKey .. ".List(?)")
end

function ScoreBoardList:saveToXMLFile(xmlFile, baseXmlKey, ix)
	local baseKey = string.format("%s.List(%d)", baseXmlKey, ix)
	xmlFile:setValue(baseKey .. "#name", self.name)
	for i, element in ipairs(self.elements) do 
		element:saveToXMLFile(xmlFile, baseKey, i-1)
	end
end

function ScoreBoardList.loadFromXMLFile(manager, xmlFile, baseXmlKey)
	xmlFile:iterate(baseXmlKey .. ".List", function (ix, key)
		local name = xmlFile:getValue(key .. "#name")
		if name then
			local list = manager:getListByName(name)
			if list then 
				ScoreBoardCategory.loadFromXMLFile(list, xmlFile, key)
			end
		end
	end)
end

function ScoreBoardList:writeStream(...)
	for i, element in ipairs(self.elements) do 
		element:writeStream(...)
	end
end

function ScoreBoardList:readStream(...)
	for i, element in ipairs(self.elements) do 
		element:readStream(...)
	end
end

function ScoreBoardList:addElement(element, ix)
	if ix ~= nil then 
		table.insert(self.elements, ix, element)
	else
		table.insert(self.elements, element)
	end
	element:setParent(self, ix or #self.elements)
end

function ScoreBoardList:getElement(index, ...)
	return self.elements[index]:getElement(...)
end

function ScoreBoardList:getElementByName(name, ...)
	for _, element in pairs(self.elements) do 
		if element:getName() == name then 
			return element:getElementByName(...)
		end
	end
end

function ScoreBoardList:getElements()
	return self.elements
end

function ScoreBoardList:getNumberOfElements(index)
	return index~=nil and self.elements[index]:getNumberOfElements() or #self.elements
end

function ScoreBoardList:count()
	local value = 0
	for _, element in pairs(self.elements) do 
		value = value + element:count()
	end
	return value
end

function ScoreBoardList:applyValues(staticList)
	for i, element in ipairs(self.elements) do 
		element:applyValues(staticList)
	end	
end
