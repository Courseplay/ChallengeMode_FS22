VictoryPoint = {

}
local VictoryPoint_mt = Class(VictoryPoint)
---@class VictoryPoint
function VictoryPoint.new(value, factor, title, factorTextFunc, custom_mt)
	local self = setmetatable({}, custom_mt or VictoryPoint_mt)	
	self.value = value
	self.factor = factor
	self.title = title
	self.factorText = factorTextFunc(factor)

	return self
end


function VictoryPoint:getValue()
	return self.value * self.factor
end

function VictoryPoint:getText()
	return string.format("%.1f",self.value * self.factor)
end

function VictoryPoint:getTitle()
	return self.title
end

function VictoryPoint:getFactorText()
	return self.factorText
end

function VictoryPoint:__tostring()
	return string.format("title: %s, value*factor: %.1f", self.title, self.value * self.factor)
end