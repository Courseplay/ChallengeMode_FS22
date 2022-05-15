ScoreBoardElement = {

}
local ScoreBoardElement_mt = Class(ScoreBoardElement)
---@class ScoreBoardElement
function ScoreBoardElement.new(title, custom_mt)
	local self = setmetatable({}, custom_mt or ScoreBoardElement_mt)	
	self.title = title

	return self
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