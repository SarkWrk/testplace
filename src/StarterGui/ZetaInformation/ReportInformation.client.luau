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
baseTextLabel.TextXAlignment = Enum.TextXAlignment.Left

local function CreateBox(message)
    local textLabel = baseTextLabel:Clone()

    local amountOfLineBreaks = #string.split(message, "<br />")

    textLabel.Size = UDim2.fromOffset(maxLabelSize, amountOfLineBreaks * textSize + textSize)
    textLabel.Text = message
    textLabel.RichText = true
    textLabel.Parent = script.Parent.Information

    while task.wait() do
        if textLabel.TextFits == true then
            break
        end
        textLabel.Size = UDim2.fromOffset(textLabel.Size.X.Offset, textLabel.Size.Y.Offset + textSize)
    end
end

packets.SendPositionalInformation.SendPositionalInformation.listen(function(message)
    CreateBox(message)
end)

while task.wait() do
    script.Parent.Information.CanvasPosition = Vector2.new(0, 10000)
    if script.Parent.Information.CanvasPosition ~= Vector2.new(0, 0) then
        break
    end
end
