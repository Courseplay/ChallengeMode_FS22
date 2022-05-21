Rule = {

}
local Rule_mt = Class(Rule, ScoreBoardElement)
---@class Rule : ScoreBoardElement
function Rule.new(name, default, title, valuesData, custom_mt)
	local self = ScoreBoardElement.new(name, title, custom_mt or Rule_mt)
	self.currentIx = default or 1
	self.title = title
	self.values = {}
	self.texts = {}
	if valuesData then
		for i, data in pairs(valuesData) do 
			if data.name then
				Rule[data.name] = data.value
			end
			table.insert(self.values, data.value)
			table.insert(self.texts, data.text)
		end
	end
	return self
end

function Rule.createFromXml(data)
	return Rule.new(data.name, data.default, data.title, data.values)
end

function Rule:getText()
	if next(self.texts) ~= nil and self.texts[self.currentIx] then 
		return self.texts[self.currentIx]
	end
	return tostring(self.values[self.currentIx])
end

function Rule:onTextInput(value)
		
end

function Rule:isTextInputAllowed()
	return false
end

function Rule:onClick()
	self.currentIx = self.currentIx + 1 
	if self.currentIx > #self.values then 
		self.currentIx = 1
	end
end

function Rule:setSavedValue(value)
	if value ~= nil then
		self.currentIx = value
	end
end

function Rule:getValueToSave()
	return self.currentIx
end
