--# selene: allow(mixed_table)

local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local vide = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("vide"):WaitForChild("src"))
-- local vide_utils = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("pretty-vide-utils"):WaitForChild("out"))

local createFunctions = {}

local function CalculateTextSize(props : {Text : string, textSize : number}) : UDim2
    local amountOfLineBreaks = #string.split(props.Text, "<br />")

    return UDim2.new(1, 0, 0,  (amountOfLineBreaks + 1) * props.textSize)
end

function createFunctions.ScrollingFrame()
    return vide.create "ScrollingFrame" {
        Size = UDim2.fromScale(0.2, 1),
        Position = UDim2.fromScale(0.8, 0),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(1, 1, 0),
        ScrollBarThickness = 3,
        CanvasSize = UDim2.fromScale(0, 5),

        vide.create "UIListLayout" {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 5)
        },
    }
end

function createFunctions.IncomingInformation(props)
    return vide.create "TextLabel" {
        Text = props.Text,
        TextSize = props.FontSize,
        Font = props.FontFace,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        AutoLocalize = false,
        TextWrapped = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 2,
        BorderMode = Enum.BorderMode.Outline,

        Size = CalculateTextSize({
            Text = props.Text, 
            textSize = props.FontSize
        })
    }
end

function createFunctions.ScreenGUI()
    return vide.create "ScreenGui" {
        Name = "Information2.0",
    }
end

local screenGUI = createFunctions.ScreenGUI()

screenGUI.Parent = game:GetService("Players").LocalPlayer.PlayerGui

local scrollingFrame = createFunctions.ScrollingFrame()

scrollingFrame.Parent = screenGUI

packets.SendPositionalInformation.SendPositionalInformation.listen(function(message)
    local informationLabel = createFunctions.IncomingInformation({
        Text = message,
        FontFace = Enum.Font.JosefinSans,
        FontSize = 14,
    })

    informationLabel.Parent = scrollingFrame

    task.wait(0.05)

    if informationLabel.TextFits == false then
        local inc = 0
        while informationLabel.TextFits == false do
            inc += 1

            informationLabel.Size = UDim2.new(1, 0, 0, informationLabel.Size.Y.Offset + 1)

            if inc % 50 == 0 then
                task.wait()
            end
        end

        informationLabel.Size = UDim2.new(1, 0, 0, informationLabel.Size.Y.Offset + 5)
    end
end)

local lastCanvasPosition
local scrolledTimes = 0

while (scrollingFrame.CanvasPosition.Y == 0) or (scrollingFrame.CanvasPosition ~= lastCanvasPosition) do
    lastCanvasPosition = scrollingFrame.CanvasPosition
    scrolledTimes += 1

    scrollingFrame.CanvasPosition +=Vector2.new(0, 10 * scrolledTimes)
    task.wait()
end
