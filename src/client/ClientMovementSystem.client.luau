local userInputService = game:GetService("UserInputService")
local player : Player = game:GetService("Players").LocalPlayer
local character = player.Character
local humanoid : Humanoid = character:WaitForChild("Humanoid")

local function Sprint(state : number) : nil
	if state == 1 then
		humanoid.WalkSpeed += 6
	else
		humanoid.WalkSpeed -= 6
	end

	return nil
end

userInputService.InputBegan:Connect(function(input : InputObject)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		
		Sprint(1)
		
		while userInputService:IsKeyDown(input.KeyCode) == true do
			task.wait()
		end
		
		Sprint(0)
	end
end)