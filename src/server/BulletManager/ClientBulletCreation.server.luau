require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("ByteNet"))
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("ByteNetPackets"))

local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local playerData = game:GetService("SharedTableRegistry"):GetSharedTable("TrackedPlayerData")

local ignoredTagsDictionary = require(game:GetService("ServerStorage"):WaitForChild("Dictionaries"):WaitForChild("TeamTagNames"))

local log_debug_information = false

packets.ArmClient.ArmClient.listen(function(_, player)
	local playerModel = player.Character

	if not playerModel then
		print(player.Name .. " has no player model ~ " .. debug.traceback("", 2))
		return
	end

	local player_armed_status = playerModel:GetAttribute("Armed")

	if log_debug_information == true then
		print(player.Name .. "'s current armed status: " .. tostring(player_armed_status) .. " | New armed status: " .. tostring(not player_armed_status))
	end

	if player_armed_status == nil then
		player_armed_status = false
	end

	playerModel:SetAttribute("Armed", not player_armed_status)
end)

packets.BulletCreation.ClientBulletCreation.listen(function(data, player)
	local playerModel = player.Character

	if not playerModel then
		print(player.Name .. " has no model ~ " .. debug.traceback("", 2))
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
end)
