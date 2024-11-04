local rig = script.Parent.Parent -- The rig
local humanoid = rig.Humanoid -- The humanoid

script:SetAttribute("Walkspeed", 16)

humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) -- Stops the rig from falling down
script.Parent.Parent.PrimaryPart:SetNetworkOwner(nil) -- Ensures the client never the owner

-- Fires the RigDied BindableEvent when Humanoid.Died fires
humanoid.Died:Connect(function()
	-- Tells all other CoreScripts to stop functioning
	script.Parent.RigDied:Fire()
	script:SetAttribute("Shutoff", true)
	
	-- Waits until all the scripts have added the "Shutoff" attribute with a "true" value
	while task.wait() do
		local allShutDown = true
		for _, v : Instance in pairs(script.Parent:GetChildren()) do
			if v:IsA("Script") then
				if v:GetAttribute("Shutoff") == true then
					continue
				else
					if v.Enabled == true then
						allShutDown = false
					end
				end
			end
		end
		if allShutDown == true then
			break
		end
	end
	
	warn("All scripts have ended.")
	
	game:GetService("Debris"):AddItem(rig, 0)
end)

game:GetService("RunService").Heartbeat:Connect(function()
	rig.Humanoid.WalkSpeed = script:GetAttribute("Walkspeed")
end)