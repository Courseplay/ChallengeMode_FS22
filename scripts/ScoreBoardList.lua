
ScoreBoardList = {}

local ScoreBoardList_mt = Class(ScoreBoardList)
---@class ScoreBoardList
function ScoreBoardList.new(name, titles, elements, custom_mt)
	local self = setmetatable({}, custom_mt or ScoreBoardList_mt)	
	self.titles = titles
	self.name = name
	self.elements = elements or {}
	self.nameToIndex = {}

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
		self.nameToIndex[element:getName()] = ix
	else
		table.insert(self.elements, element)
		self.nameToIndex[element:getName()] = #self.elements
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

function ScoreBoardList:getElementIndexByName(name)
	return self.nameToIndex[name]
end

function ScoreBoardList:setElementByName(name, newCategory)
	for ix, element in pairs(self.elements) do
		if element:getName() == name then
			self.elements[ix] = newCategory
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

function ScoreBoardList:clone()
	local list = ScoreBoardList.new(self.name, self.title)

	for _, element in pairs(self.elements) do
		local e = element:clone()
		list:addElement(e)
	end

	return list
end

--- Combines all specified elements into newElement and add newElement to self.elements
--- @param newElement ScoreBoardCategory
--- @param ... string names of all elements to combine
function ScoreBoardList:mergeElements(newElement, ...)
	for _, name in pairs({...}) do
		local idx = self:getElementIndexByName(name)
		local element = self:getElementByName(name)
		for _, elem in pairs(element:getElements()) do
			newElement:addElement(elem)
		end

		self.elements[idx] = nil
		self.nameToIndex[name] = nil
	end
	self:addElement(newElement)
end