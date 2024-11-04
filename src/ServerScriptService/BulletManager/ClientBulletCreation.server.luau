task.wait(1)

local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local promises = require(game:GetService("ReplicatedStorage"):WaitForChild("roblox-lua-promise"):WaitForChild("Promise"))
local playerData = game:GetService("SharedTableRegistry"):GetSharedTable("TrackedPlayerData")

local function TryToCreateBullet(data, player : Player)
	return promises.new(function(resolve)
		local playerModel = player.Character

		if playerModel then
			if playerModel:GetAttribute("Armed") == true then
				local position = Vector3.new(data.PositionX, data.PositionY, data.PositionZ)
				local rotation = Vector3.new(data.RotationX, data.RotationY, data.RotationZ)
		
				local fixed = helper.Conversions.Vector3ToCFrame(position, rotation)
		
				if (playerModel.Head.Position - fixed.Position).Magnitude <= 5 and playerData[player.Name]["Health"] > 0 then
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

					resolve()
				end
			end
		end
	end)
end

local function ChangePlayerArmedStatus(data : boolean, player : Player)
	return promises.new(function(resolve)
		local playerModel = player.Character

		if playerModel then
			if data == true then
				playerModel:SetAttribute("Armed", true)
			else
				playerModel:SetAttribute("Armed", false)
			end

			resolve()
		end
	end)
end

packets.ArmClient.ArmClient.listen(function(data, player)
	promises.retry(ChangePlayerArmedStatus, 10, data, player)
end)

packets.CBulletCreation.ClientBulletCreation.listen(function(data, player)
	promises.retry(TryToCreateBullet, 10, data, player)
end)
