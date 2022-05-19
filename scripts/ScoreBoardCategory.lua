
ScoreBoardCategory = {}

local ScoreBoardElement_mt = Class(ScoreBoardCategory)
---@class ScoreBoardCategory
function ScoreBoardCategory.new(name, title, elements, custom_mt)
	local self = setmetatable({}, custom_mt or ScoreBoardElement_mt)	
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

function ScoreBoardCategory:addElement(element, ix)
	if ix ~= nil then 
		table.insert(self.elements, ix, element)
	else
		table.insert(self.elements, element)
	end
	element:setCategory(self)
end

function ScoreBoardCategory:getElement(index)
	return self.elements[index]
end

function ScoreBoardCategory:getElementByName(name)
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

function ScoreBoardCategory:onTextInput(value)
		
end

function ScoreBoardCategory:isTextInputAllowed()
	return false
end

function ScoreBoardCategory:onClick()
		
end

function ScoreBoardCategory:saveToXMLFile(xmlFile, baseXmlKey)
	for i, element in ipairs(self.elements) do 
		xmlFile:setValue(baseXmlKey .. "#name", self.name)
		element:saveToXMLFile(xmlFile, string.format("%s.Element(%d)", baseXmlKey, i-1))
	end
end

function ScoreBoardCategory:loadFromXMLFile(xmlFile, baseXmlKey)
	xmlFile:iterate(baseXmlKey .. ".Element", function (ix, key)
		local name = xmlFile:getValue(key .. "#name")
		if name then
			local element = self:getElementByName(name)
			if element then 
				element:loadFromXMLFile(xmlFile, key)
			end
		end
	end)
end

function ScoreBoardCategory:count()
	local value = 0
	for _, element in pairs(self.elements) do 
		value = value + element:getValue()
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

function ScoreBoardCategory:applyValues(staticCategory)
	for i, element in ipairs(self.elements) do 
		element:applyValues(staticCategory)
	end	
end