AddPointsDialog = {}

AddPointsDialog_mt = Class(AddPointsDialog, YesNoDialog)
AddPointsDialog.CONTROLS = {
    DIALOG_ELEMENT = "dialogElement",
    POINTS_INPUT = "pointsInput",
    REASON_INPUT = "reasonInput"
}

local function NO_CALLBACK() end

function AddPointsDialog.new(target, custom_mt)
    local self = YesNoDialog.new(target, custom_mt or AddPointsDialog_mt)

    self:registerControls(AddPointsDialog.CONTROLS)

    self.onTextEntered = NO_CALLBACK
    self.extraInputDisableTime = 0

    return self
end

function AddPointsDialog:onOpen()
    AddPointsDialog:superClass().onOpen(self)

    self.extraInputDisableTime = 100
    FocusManager:setFocus(self.pointsInput)
    self.pointsInput.blockTime = 0
    self.pointsInput:onFocusActive()

    if self.pointsInput.imeActive or self.reasonInput.imeActive then
        if self.yesButton ~= nil then
            self.yesButton:setVisible(false)
        end

        if self.noButton ~= nil then
            self.noButton:setVisible(false)
        end
    end
end

function AddPointsDialog:onClose()
    AddPointsDialog:superClass().onClose(self)

    self.
end