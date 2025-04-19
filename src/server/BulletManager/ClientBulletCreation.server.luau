require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("ByteNet"):WaitForChild("ByteNet"))

local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local playerData = game:GetService("SharedTableRegistry"):GetSharedTable("TrackedPlayerData")

local ignoredTagsDictionary = require(game:GetService("ServerStorage"):WaitForChild("Dictionaries"):WaitForChild("TeamTagNames"))

packets.ArmClient.ArmClient.listen(function(data, player)
	local playerModel = player.Character

	if not playerModel then
		print(player.Name .. " has no player model ~ " .. debug.traceback("", 2))
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
		Pierce = 0,
		PierceDamageLoss = 0,
		StartPosition = position,
	}, player)
end)
