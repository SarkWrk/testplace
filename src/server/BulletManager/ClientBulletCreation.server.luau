local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local playerData = game:GetService("SharedTableRegistry"):GetSharedTable("TrackedPlayerData")

local squash_handler = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("Squash_Handler"))

local ignoredTagsDictionary = require(game:GetService("ServerStorage"):WaitForChild("Dictionaries"):WaitForChild("TeamTagNames"))

local log_debug_information = false

game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Weapon_Stuff").OnServerEvent:Connect(function(player, prefix: buffer, payload: buffer)
	local playerModel = player.Character

	if not playerModel then
		print(player.Name .. " has no player model ~ " .. debug.traceback("", 2))
		return
	end

	local success, number_prefix = pcall(function()
		return squash_handler.prefix_des(prefix)
	end)

	if not success then
		return
	end

	local decoded_prefix: string = squash_handler.prefix_key.WeaponStuff[tostring(number_prefix)]

	if decoded_prefix:lower() == string.lower("ArmClient") then
		local player_armed_status = playerModel:GetAttribute("Armed")
	
		if log_debug_information == true then
			print(player.Name .. "'s current armed status: " .. tostring(player_armed_status) .. " | New armed status: " .. tostring(not player_armed_status))
		end
	
		if player_armed_status == nil then
			player_armed_status = false
		end
	
		playerModel:SetAttribute("Armed", not player_armed_status)

	elseif decoded_prefix:lower() == string.lower("ClientBulletCreation") then
		if playerModel:GetAttribute("Armed") ~= true then
			return
		end

		local data = squash_handler.weapon_stuffs.client_bullet_creation.des(squash_handler.frombuffer(payload))
	
		local position
		local rotation

		success, position = pcall(function()
			return Vector3.new(data.PositionX, data.PositionY, data.PositionZ)
		end)
		
		if not success then
			return
		end

		success, rotation = pcall(function()
			return Vector3.new(data.RotationX, data.RotationY, data.RotationZ)
		end)

		if not success then
			return
		end
	
		local fixed = helper.Conversions.Vector3ToCFrame(position, rotation)
	
		if (playerModel.Head.Position - fixed.Position).Magnitude > 5 then
			return
		end
	
		if playerData[player.Name]["Health"] <= 0 then
			return
		end
	
		local tags = game:GetService("CollectionService"):GetAllTags()
		local allowed_tags = {}
		local blocked_tags = {}
	
		-- Blacklist
		if ignoredTagsDictionary.ListType == true then
			for _, tag in pairs(tags) do
				if table.find(ignoredTagsDictionary.List, tag) then
					table.insert(blocked_tags, tag)
	
					continue
				end
	
				table.insert(allowed_tags, tag)
			end
		-- Whitelist
		else
			for _, tag in pairs(tags) do
				if table.find(ignoredTagsDictionary.List, tag) then
					table.insert(allowed_tags, tag)
	
					continue
				end
	
				table.insert(blocked_tags, tag)
			end
		end
	
		local player_team_tags = playerModel:GetTags()
	
		for _, tag in pairs(player_team_tags) do
			table.insert(blocked_tags, tag)
		end
	
		for _, tag in pairs(blocked_tags) do
			if table.find(allowed_tags, tag) then
				table.remove(allowed_tags, table.find(allowed_tags, tag))
			end
		end
	
		script.Parent:SendMessage("ClientCreate", {
			Damage = 10,
			Enemy = allowed_tags,
			IgnoreTagged = blocked_tags,
			MoveTowards = fixed,
			BulletDrop = 1,
			DistanceTimeOut = 25000,
			Speed = 100,
			Pierce = 3,
			PierceDamageLoss = 0,
			StartPosition = position,
		}, player)
	end
end)
