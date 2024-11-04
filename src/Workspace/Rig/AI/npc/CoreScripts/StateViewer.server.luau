local rig = script.Parent.Parent
local AIScript = script.Parent.AI
local animatorScript = script.Parent.AnimatorScript
local died = false

local highlight = Instance.new("Highlight")

local fillRed, fillGreen, fillBlue = 0, 0 ,0
local borderRed, borderGreen, borderBlue = 255, 255, 255

highlight.Parent = rig

local idled = false
local walking = false
local canSeeEnemy = false

script.Parent.RigDied.Event:Connect(function()
	died = true
end)

while task.wait() do
	if died == true then
		break
	end
	
	fillRed, fillGreen, fillBlue = 0, 0, 0
	borderRed, borderGreen, borderBlue = 255, 255, 255
	
	walking = AIScript:GetAttribute("Moving")
	idled = not AIScript:GetAttribute("InCycle")
	canSeeEnemy = AIScript:GetAttribute("CanSeeEnemy")
	
	if walking == true then
		if animatorScript:GetAttribute("WalkAnimation") == true then
			fillRed, fillGreen, fillBlue = 0, 255, 255
		else
			fillRed, fillGreen, fillBlue = 255/3, 255, 255
		end
	else
		if idled == false then
			fillRed, fillGreen, fillBlue = 255/3, 0, 0
		else
			fillRed, fillGreen, fillBlue = 0, 0, 0
		end
	end
	
	if canSeeEnemy == true then
		fillRed, fillGreen, fillBlue = 0, 0, 127
	end
	
	if script.Parent.AI:GetAttribute("Armed") == true then
		borderRed -= 25
		borderGreen -= 255
		borderBlue -= 100
	end
	
	highlight.FillColor = Color3.fromRGB(fillRed, fillGreen, fillBlue)
	highlight.OutlineColor = Color3.fromRGB(borderRed, borderBlue, borderGreen)
end

script:SetAttribute("Shutoff", true)