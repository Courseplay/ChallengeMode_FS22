VictoryPoint = {
	MONEY_TEXT =
	function(money)
		return string.format("%.2f%s/%s", g_i18n:getCurrency(money), g_i18n:getCurrencySymbol(true), g_i18n:getText("unit_pointsShort"))
	end,
	AREA_TEXT = function(area)
		return string.format("%.2f%s/%s", g_i18n:getArea(area), g_i18n:getAreaUnit(), g_i18n:getText("unit_pointsShort"))
	end,
	VOLUME_TEXT = function(liters)
		return string.format("%.2f%s/%s", g_i18n:getFluid(liters), g_i18n:getText("unit_literShort"), g_i18n:getText("unit_pointsShort"))
	end,
	ANIMAL_TEXT = function (numberOfAnimals)
		return string.format("%.2f%s/%s", numberOfAnimals, g_i18n:getText("unit_piecesShort"), g_i18n:getText("unit_pointsShort"))
	end
}
local VictoryPoint_mt = Class(VictoryPoint, ScoreBoardElement)
---@class VictoryPoint : ScoreBoardElement
function VictoryPoint.new(name, value, factor, title, inputText, unitTextFunc, dependency, animalNamePlural, custom_mt)
	local self = ScoreBoardElement.new(name, title, custom_mt or VictoryPoint_mt)
	self.value = value
	self.factor = factor
	self.title = title
	self.inputText = inputText
	self.dependency = dependency
	self.unitTextFunc = unitTextFunc
	self.animalNamePlural = animalNamePlural
	if unitTextFunc then
		self.factorText = self[unitTextFunc](factor)
	end
	self.staticElement = nil
	return self
end

function VictoryPoint.createFromXml(data, value)
	return VictoryPoint.new(data.name, value, data.default, data.title, data.inputText, data.unitTextFunc, data.dependency, data.animalNamePlural)
end

function VictoryPoint:getValue()
	if self.staticElement == nil and not self.dependency then
		return 0
	end
	if self.value == nil then
		CmUtil.debug("Victory point value is nil: %s", self.name)
		printCallstack()
		return 0
	end
	-- division by 0 is not allowed
	if self.factor == 0 then
		return 0
	end
	return self.value / self.factor
end

function VictoryPoint:count()
	if self.dependency then
		return 0
	end
	return self:getValue()
end

function VictoryPoint:getFactor()
	return self.factor or 0
end

function VictoryPoint:setFactor(newFactor)
	self.factor = newFactor
end

function VictoryPoint:getText()
	if not self.staticElement and not self.dependency then
		return ""
	end
	return string.format("%.1f", self:getValue())
end

function VictoryPoint:getTitle()
	return self.title
end

function VictoryPoint:getInputText()
	if self.animalNamePlural ~= nil then
		return self.inputText:format(self.animalNamePlural)
	end
	return self.inputText:format(self.title)
end

function VictoryPoint:getFactorText()
	if not self.dependency then
		if self.unitTextFunc then
			return self[self.unitTextFunc](self.factor)
		else
			return self.factor
		end
	end
	return ""
end

function VictoryPoint:onTextInput(value)
	local v = tonumber(value)
	if v ~= nil then
		local element = self.staticElement and self.staticElement or self
		element:setFactor(v)
		ChangeElementEvent.sendEvent(element, ChangeElementEvent.POINT)
	end
end

function VictoryPoint:isTextInputAllowed()
	return not self.dependency
end

function VictoryPoint:clone(farmId, farm)

end

function VictoryPoint:__tostring()
	return string.format("title: %s, value/factor: %.1f", self.title, self.value / self.factor)
end

function VictoryPoint:setSavedValue(value)
	if value ~= nil then
		self.factor = value
	end
end

function VictoryPoint:getValueToSave()
	return self.factor
end

function VictoryPoint:applyValues(staticCategory)
	local element = staticCategory:getElementByName(self.name)
	if element then
		self:setFactor(element:getFactor())
		self.staticElement = element
	end
end

function VictoryPoint:writeStream(streamId, connection)
	streamWriteString(streamId, self:getParent():getName())
	streamWriteString(streamId, self.name)
	streamWriteFloat32(streamId, self:getFactor())
end

function VictoryPoint.readStream(categoryName, categoryId, name, value, ix)
	local element = g_victoryPointManager:getList():getElementByName(categoryName, name)
	element:setFactor(value)
	return element
end
