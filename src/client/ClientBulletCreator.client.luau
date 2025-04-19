local tracker : {[number] : {Part : Part, Tween : Tween}} = {}
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local bulletsFolder = Instance.new("Folder")
bulletsFolder.Name = "Bullets"
bulletsFolder.Parent = workspace
local cachedBulletsFolder = Instance.new("Folder")
cachedBulletsFolder.Name = "CachedBullets"
cachedBulletsFolder.Parent = game:GetService("ReplicatedStorage")

function RemoveBullet(index : number) : nil
	if tracker[index] ~= nil then
		if tracker[index].Part then
			tracker[index].Part.Parent = cachedBulletsFolder
			tracker[index].Tween:Cancel()
		end
	end

	return nil
end

packets.SBulletCreation.BulletCreation.listen(function(data)
	if data.Speed == nil and data.EndPositionX == nil and data.PositionX == nil then
		RemoveBullet(data.Index)
	elseif data.Speed then
		
		local bullet

		local position: Vector3 = Vector3.new(data.PositionX, data.PositionY, data.PositionZ)
		local endPosition: Vector3 = Vector3.new(data.EndPositionX, data.EndPositionY, data.EndPositionZ)
		local rotation: Vector3 = Vector3.new(data.RotationX, data.RotationY, data.RotationZ)
		
		if tracker[data.Index] then
			if tracker[data.Index].Part then
				bullet = tracker[data.Index].Part
			end
		end
		
		if bullet == nil then
			tracker[data.Index] = {Part = nil, Tween = nil}
			bullet = game:GetService("ReplicatedStorage").Bullet:Clone()
			bullet.Name = data.Index
			tracker[data.Index].Part = bullet
		else
			tracker[data.Index].Tween:Cancel()
		end
		
		if data.ID == game:GetService("Players").LocalPlayer.UserId then
			coroutine.resume(coroutine.create(function()
				task.wait(5/data.Speed)
				bullet.Parent = bulletsFolder
			end))
		else
			bullet.Trail1.Enabled = true
			bullet.Trail2.Enabled = true
			bullet.Parent = bulletsFolder
		end
		bullet.CFrame = helper.Conversions.Vector3ToCFrame(position, rotation)

		tracker[data.Index].Tween = game:GetService("TweenService"):Create(bullet, TweenInfo.new(helper.NumberManipulation.Delta(position, endPosition)/data.Speed, Enum.EasingStyle.Linear), {Position = endPosition})
		
		tracker[data.Index].Tween:Play()
		tracker[data.Index].Tween.Completed:Connect(function()
			RemoveBullet(data.Index)
		end)
	else
		warn("Setting '" .. data.Setting .. "' not registered.")
	end
end)