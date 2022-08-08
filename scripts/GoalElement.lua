GoalElement = {}

local GoalElement_mt = Class(VictoryPoint, ScoreBoardElement)

function GoalElement.new(name, title, value, custom_mt)
    local self = ScoreBoardElement.new(name, title, custom_mt or GoalElement_mt)
    self.title = title
    self.value = value
    self.className = "GoalElement"

    return self
end

function GoalElement:getText()
    print("getValue")
    return "5678"
end

function GoalElement:getFactorText()
    return "Factor Text"
end

function GoalElement:onTextInput(value)
    print("onTextInput")
    g_victoryPointManager:setGoal(value)
end