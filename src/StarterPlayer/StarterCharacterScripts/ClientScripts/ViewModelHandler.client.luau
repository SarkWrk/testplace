local viewModel = game:GetService("ReplicatedStorage").ViewModel:Clone()
local currentCamera = workspace.CurrentCamera
local animator = viewModel.AnimationController.Animator
local character = game:GetService("Players").LocalPlayer.Character
local hasGun = false
local hasMelee = false

local gunAnimations : {
	Safety : AnimationTrack,
	Unsafety : AnimationTrack,	
}
	=
{
	Safety = nil,
	Unsafety = nil,
}

viewModel.Parent = workspace

local stepped = game:GetService("RunService").PreRender:Connect(function()
	viewModel.Head.CFrame = currentCamera.CFrame
end)

game:GetService("Players").LocalPlayer.Character.Humanoid.Died:Connect(function()
	stepped:Disconnect()
	viewModel:Destroy()
end)

character.ChildAdded:Connect(function(child)
	if child:HasTag("Gun") then
		local handle : Motor6D = child:FindFirstChild("Handle")

		child.Parent = viewModel
		handle.Part1 = viewModel.RightHand
		
		if handle then
			local animations : Folder = child.Animations
			
			hasMelee = false
			hasGun = true
			
			gunAnimations.Safety = animator:LoadAnimation(animations:FindFirstChild("Safety"))
			gunAnimations.Unsafety = animator:LoadAnimation(animations:FindFirstChild("Unsafety"))
			
			gunAnimations.Safety:Play()
		end
	elseif child:HasTag("Melee") then
		hasGun = false
		hasMelee = true
	end
end)


script.Parent.ClientCombatScript:GetAttributeChangedSignal("Safety"):Connect(function()
	if gunAnimations.Safety and gunAnimations.Unsafety then
		if script.Parent.ClientCombatScript:GetAttribute("Safety") == true then
			gunAnimations.Unsafety:Stop()
			gunAnimations.Safety:Play()
		else
			gunAnimations.Safety:Stop()
			gunAnimations.Unsafety:Play()
		end
	end
end)


while task.wait() do
	for _, part in pairs(viewModel:GetChildren()) do
		if part:IsA("Part") then
			part.CanCollide = false
			part.CastShadow = false
		end
	end
end