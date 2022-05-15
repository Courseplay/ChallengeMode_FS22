Rule = {

}
local Rule_mt = Class(Rule, ScoreBoardElement)
---@class Rule : ScoreBoardElement
function Rule.new(value, title, texts, custom_mt)
	local self = ScoreBoardElement.new(title, custom_mt or Rule_mt)
	self.value = value
	self.title = title
	self.texts = texts
	return self
end


function Rule:getText()
	if self.texts then 
		if self.texts[self.value] then 
			return self.texts[self.value]
		end
		if self.value == true then 
			return self.texts[1]
		elseif self.value == false then 
			return self.texts[0]
		end
	end
	return tostring(self.value)
end
