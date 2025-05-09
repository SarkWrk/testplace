local tracker : {[number] : {Part : Part, Tween : Tween, InRemovalProcess : boolean}} = {}

local squash_handler = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("Squash_Handler"))

local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local bulletsFolder = Instance.new("Folder")
bulletsFolder.Name = "Bullets"
bulletsFolder.Parent = workspace
local cachedBulletsFolder = Instance.new("Folder")
cachedBulletsFolder.Name = "CachedBullets"
cachedBulletsFolder.Parent = game:GetService("ReplicatedStorage")

-- Initial and final colours to change the bullet's trail by when piercing objects
local colours = {
	start = {
		initial = {
			r = 255,
			g = 0,
			b = 127,
		},
		final = {
			r = 85,
			g = 255,
			b = 255,
		}
	},
	finish = {
		initial = {
			r = 175,
			g = 127,
			b = 37,
		},
		final = {
			r = 159,
			g = 182,
			b = 57,
		}
	}
}

colours.delta = {
	initial = {
		r = helper.NumberManipulation.Delta(colours.start.initial.r, colours.finish.initial.r),
		g = helper.NumberManipulation.Delta(colours.start.initial.g, colours.finish.initial.g),
		b = helper.NumberManipulation.Delta(colours.start.initial.b, colours.finish.initial.b),
	},
	final = {
		r = helper.NumberManipulation.Delta(colours.start.final.r, colours.finish.final.r),
		g = helper.NumberManipulation.Delta(colours.start.final.g, colours.finish.final.g),
		b = helper.NumberManipulation.Delta(colours.start.final.b, colours.finish.final.b),
	},
}

-- Table automatically filled out
local bullet_pierce_colours = {}

local total_values = 5

colours.delta.adjusted = {
	initial = {
		r = colours.delta.initial.r/(total_values-1),
		g = colours.delta.initial.g/(total_values-1),
		b = colours.delta.initial.b/(total_values-1),
	},
	final = {
		r = colours.delta.final.r/(total_values-1),
		g = colours.delta.final.g/(total_values-1),
		b = colours.delta.final.b/(total_values-1),
	}
}

for i = 0, total_values-1 do
	local new_colours = {
		initial = {
			r = colours.start.initial.r + (i * colours.delta.adjusted.initial.r),
			g = colours.start.initial.g + (i * colours.delta.adjusted.initial.g),
			b = colours.start.initial.b + (i * colours.delta.adjusted.initial.b),
		},
		final = {
			r = colours.start.final.r + (i * colours.delta.adjusted.final.r),
			g = colours.start.final.g + (i * colours.delta.adjusted.final.g),
			b = colours.start.final.b + (i * colours.delta.adjusted.final.b),
		},
	}

	bullet_pierce_colours[i] = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(new_colours.initial.r, new_colours.initial.g, new_colours.initial.b)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(new_colours.final.r, new_colours.final.g, new_colours.final.b))
	})
end


function RemoveBullet(index : number) : nil
	local bullet_entry = tracker[index]

	if bullet_entry ~= nil then
		if bullet_entry.Part then
			bullet_entry.InRemovalProcess = true
			bullet_entry.Part.Transparency = 1

			local bullet_position = bullet_entry.Part.Position

			bullet_entry.Tween:Cancel()

			bullet_entry.Part.Position = bullet_position

			local trail = bullet_entry.Part:FindFirstChild("Trail1") :: Trail
			local lifetime = trail.Lifetime
			
			task.wait(lifetime)

			if bullet_entry.InRemovalProcess == true then
				bullet_entry.Part.Parent = cachedBulletsFolder
				bullet_entry.InRemovalProcess = false
			end
		end
	end

	return nil
end

function ChangingBulletPhysicalProperties(index : number)
	local bullet_entry = tracker[index]

	bullet_entry.InRemovalProcess = false
	bullet_entry.Part.Transparency = 0
end

--[[
Receives bullet data from the server.

If there is only an index as a value, the bullet will be "deleted" (cached).

If there is more filled out data than the index, then changes will be made to the bullet if the required data for those changes are present.
]]
game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Weapon_Stuff").OnClientEvent:Connect(function(prefix: buffer, payload: {})
	local decoded_prefix: string = squash_handler.prefix_key.WeaponStuff[tostring(squash_handler.prefix_des(prefix))]

	if decoded_prefix:lower() ~= string.lower("ServerBulletCreation") then
		return
	end

	local data = {}

	for index, value: buffer in pairs(payload) do
		data[index] = squash_handler.weapon_stuffs.server_bullet_creation[index].des(squash_handler.frombuffer(value))
	end
	local only_index_has_value = true

	for _index, _value in pairs(data) do
		if _index == "Index" then
			continue
		end

		if _value ~= nil then
			only_index_has_value = false
			break
		end
	end
	
	if only_index_has_value == true then
		RemoveBullet(data.Index)

		return
	end

	local bullet
	
	if tracker[data.Index] then
		if tracker[data.Index].Part then
			bullet = tracker[data.Index].Part
		end
	end
	
	if bullet == nil then
		tracker[data.Index] = {Part = nil, Tween = nil, InRemovalProcess = false}
		bullet = game:GetService("ReplicatedStorage").Bullet:Clone()
		bullet.Name = data.Index
		tracker[data.Index].Part = bullet
	end
	
	if data.ID then
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
	end

	if data.PierceAmount then
		local trail1 = bullet:FindFirstChild("Trail1") :: Trail
		local trail2 = bullet:FindFirstChild("Trail2") :: Trail

		trail1.Color = bullet_pierce_colours[data.PierceAmount]
		trail2.Color = bullet_pierce_colours[data.PierceAmount]
	end
	
	local position: Vector3?
	local endPosition: Vector3?
	local rotation: Vector3?

	if data.Position then
		if data.Position.X and data.Position.Y and data.Position.Z then
			position = Vector3.new(data.Position.X, data.Position.Y, data.Position.Z)
		end
	end
	
	if data.EndPosition then
		if data.EndPosition.X and data.EndPosition.Y and data.EndPosition.Z then
			endPosition = Vector3.new(data.EndPosition.X, data.EndPosition.Y, data.EndPosition.Z)
		end
	end
	
	if data.Rotation then
		if data.Rotation.X and data.Rotation.Y and data.Rotation.Z then
			rotation = Vector3.new(data.Rotation.X, data.Rotation.Y, data.Rotation.Z)
		end
	end

	if position and rotation then
		ChangingBulletPhysicalProperties(data.Index)

		bullet.CFrame = helper.Conversions.Vector3ToCFrame(position, rotation)
	end

	if position and endPosition and data.Speed then
		if tracker[data.Index].Tween then
			tracker[data.Index].Tween:Cancel()
		end

		ChangingBulletPhysicalProperties(data.Index)

		tracker[data.Index].Tween = game:GetService("TweenService"):Create(bullet, TweenInfo.new(helper.NumberManipulation.Delta(position, endPosition)/data.Speed, Enum.EasingStyle.Linear), {Position = endPosition})

		tracker[data.Index].Tween:Play()
		tracker[data.Index].Tween.Completed:Connect(function()
			RemoveBullet(data.Index)
		end)
	end
end)