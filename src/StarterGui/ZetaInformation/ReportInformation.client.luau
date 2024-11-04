local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("Packets"))

local textSize = 15
local textFont = Enum.Font.JosefinSans

local maxLabelSize = script.Parent.Information.AbsoluteCanvasSize.X

local baseTextLabel = Instance.new("TextLabel")
baseTextLabel.Font = textFont
baseTextLabel.TextSize = textSize
baseTextLabel.AutoLocalize = false
baseTextLabel.TextWrapped = true
baseTextLabel.RichText = true

packets.SendPositionalInformation.SendPositionalInformation.listen(function(message)
    print("Recieved message: ", message)
    local textLabel = baseTextLabel:Clone()

    local amountOfLineBreaks = #string.split(message, "<br />")

    textLabel.Size = UDim2.fromOffset(maxLabelSize, amountOfLineBreaks * 15 + 15)
    textLabel.Text = message
    textLabel.RichText = true
    textLabel.Parent = script.Parent.Information
end)

for _ = 1, 5 do
    script.Parent.Information.CanvasPosition = Vector2.new(0, 10000)
    task.wait(1)
end
