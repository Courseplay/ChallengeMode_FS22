VictoryPoint = {

}
local VictoryPoint_mt = Class(VictoryPoint, ScoreBoardElement)
---@class VictoryPoint : ScoreBoardElement
function VictoryPoint.new(value, factor, title, factorTextFunc, custom_mt)
	local self = ScoreBoardElement.new(title, custom_mt or VictoryPoint_mt)
	self.value = value
	self.factor = factor
	self.title = title
	if factorTextFunc then
		self.factorText = factorTextFunc(factor)
	end
	return self
end


function VictoryPoint:getValue()
	return self.value * self.factor
end

function VictoryPoint:getText()
	if self.factor then 
		return string.format("%.1f",self.value * self.factor)
	else 
		return string.format("%.1f",self.value)
	end
end

function VictoryPoint:getTitle()
	return self.title
end

function VictoryPoint:getFactorText()
	return self.factorText or ""
end

function VictoryPoint:__tostring()
	return string.format("title: %s, value*factor: %.1f", self.title, self.value * self.factor)
end