workspace.Rig.AI.npc.CoreScripts.AI:WaitForChild("Shot").Event:Connect(function()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9114727096"
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Wait()
	game:GetService("Debris"):AddItem(sound, 0)
end)