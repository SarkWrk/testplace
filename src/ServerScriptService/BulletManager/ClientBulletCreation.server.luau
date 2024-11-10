task.wait(1)

local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local playerData = game:GetService("SharedTableRegistry"):GetSharedTable("TrackedPlayerData")

packets.ArmClient.ArmClient.listen(function(data, player)
	local playerModel = player.Character

	if not playerModel then
		return
	end
	
	if data == true then
		playerModel:SetAttribute("Armed", true)
	else
		playerModel:SetAttribute("Armed", false)
	end
end)

packets.CBulletCreation.ClientBulletCreation.listen(function(data, player)
	local playerModel = player.Character

	if not playerModel then
		return
	end

	if playerModel:GetAttribute("Armed") ~= true then
		return
	end

	local position = Vector3.new(data.PositionX, data.PositionY, data.PositionZ)
	local rotation = Vector3.new(data.RotationX, data.RotationY, data.RotationZ)

	local fixed = helper.Conversions.Vector3ToCFrame(position, rotation)

	if (playerModel.Head.Position - fixed.Position).Magnitude > 5 then
		return
	end

	if playerData[player.Name]["Health"] <= 0 then
		return
	end

	script.Parent:SendMessage("ClientCreate", {
		Damage = 10,
		Enemy = { "AI", "Goal" },
		IgnoreTagged = { "Bullet", "Visualiser" },
		MoveTowards = fixed,
		BulletDrop = 1,
		DistanceTimeOut = 25000,
		Speed = 100,
		Pierce = 0,
		PierceDamageLoss = 0,
		StartPosition = position,
	}, player)
end)
