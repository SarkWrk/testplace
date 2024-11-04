game:GetService("Players").PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(2)
		local gun = game:GetService("ServerStorage").Gun:Clone()
		gun.Parent = character
	end)
end)