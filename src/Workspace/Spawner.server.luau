local startingPosition = Vector3.new(-29.399, 0.003, -198.199)
local cloner = workspace.Goals.Goal1

script:SetAttribute("Max", 30)

local clones = 0
local num = #workspace.Goals:GetChildren()

while task.wait() do
	if clones < script:GetAttribute("Max") then
		clones += 1
		num += 1
		local a = cloner:Clone()
		a.Name = "Goal"..num
		a:PivotTo(CFrame.new(startingPosition) + Vector3.new(math.random(50, 100), 0, math.random(50, 100)))
		a:SetAttribute("Defense", math.random(0, 90))
		a.Parent = workspace.Goals
		
		--coroutine.resume(coroutine.create(function()
		--	while task.wait() do
		--		task.wait(Random.new():NextNumber(3, 5))
		--		if a:GetAttribute("Armed") == false then
					a:SetAttribute("Armed", true)
		--		else
		--			a:SetAttribute("Armed", false)
		--		end
		--	end
		--end))
	end
	
	for _, v in pairs(workspace.Goals:GetChildren()) do
		if #v:GetChildren() == 0 then
			v:Destroy()
			continue
		end
		
		if v:FindFirstChild("Humanoid") then
			if v.Humanoid.Health <= 0 then
				clones -= 1
				v:Destroy()
			end
		end
	end
end