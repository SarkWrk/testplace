local squash_handler = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("Squash_Handler"))

local bulletComponent = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("BulletComponent"):WaitForChild("BulletComponent"))
local promises = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("Promise"))

local activeBullets: { [number]: { ["lookdirection"]: Vector3 } } = {}
local totalActiveBullets = 0
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local maxIndex = 65535
local start = 0

type BulletInfo = {
	Damage : number,
	Enemy : {string},
	IgnoreTagged : {string},
	MoveTowards : CFrame,
	BulletDrop : number,
	DistanceTimeOut : number,
	Speed : number,
	Pierce : number,
	PierceDamageLoss : number,
	StartPosition : Vector3
}

local function SendToClients(
	sendData: {
		Index: number,
		PierceAmount: number?,
		Position: Vector3?,
		EndPosition: Vector3?,
		Speed: number?,
		Rotation: Vector3?,
		ID: number?,
	})

	local createdPacket = {}

	local index_cursor = squash_handler.cursor()
	squash_handler.weapon_stuffs.server_bullet_creation.Index.ser(index_cursor, sendData.Index)
	createdPacket.Index = squash_handler.tobuffer(index_cursor)

	if sendData.PierceAmount then
		local pierce_cursor = squash_handler.cursor()
		squash_handler.weapon_stuffs.server_bullet_creation.PierceAmount.ser(pierce_cursor, sendData.PierceAmount)
		createdPacket.PierceAmount = squash_handler.tobuffer(pierce_cursor)
	end

	if sendData.Position then
		local position_cursor = squash_handler.cursor()
		squash_handler.weapon_stuffs.server_bullet_creation.Position.ser(position_cursor, {
			X = sendData.Position.X,
			Y = sendData.Position.Y,
			Z = sendData.Position.Z,
		})
		createdPacket.Position = squash_handler.tobuffer(position_cursor)
	end

	if sendData.EndPosition then
		local end_position_cursor = squash_handler.cursor()
		squash_handler.weapon_stuffs.server_bullet_creation.EndPosition.ser(end_position_cursor, {
			X = sendData.EndPosition.X,
			Y = sendData.EndPosition.Y,
			Z = sendData.EndPosition.Z,
		})
		createdPacket.EndPosition = squash_handler.tobuffer(end_position_cursor)
	end

	if sendData.Speed then
		local speed_cursor = squash_handler.cursor()
		squash_handler.weapon_stuffs.server_bullet_creation.Speed.ser(speed_cursor, sendData.Speed)
		createdPacket.Speed = squash_handler.tobuffer(speed_cursor)
	end

	if sendData.Rotation then
		local rotation_cursor = squash_handler.cursor()
		squash_handler.weapon_stuffs.server_bullet_creation.Rotation.ser(rotation_cursor, {
			X = sendData.Rotation.X,
			Y = sendData.Rotation.Y,
			Z = sendData.Rotation.Z,
		})
		createdPacket.Rotation = squash_handler.tobuffer(rotation_cursor)
	end

	if sendData.ID then
		local id_cursor = squash_handler.cursor()
		squash_handler.weapon_stuffs.server_bullet_creation.ID.ser(id_cursor, sendData.ID)
		createdPacket.ID = squash_handler.tobuffer(id_cursor)
	end

	game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Weapon_Stuff"):FireAllClients(squash_handler.prefix_ser(2), createdPacket)
end

local function OpenIndexFinder(): number
	local function Indexor(startIndex: number, endIndex: number, iterator: number?): number?
		local increment = iterator or 1

		for i = startIndex, endIndex, increment do
			if activeBullets[i] == nil then
				return i
			end
		end

		return nil
	end

	local number

	if start == 0 then
		start = 1
		number = Indexor(1, maxIndex, 1)

		while number == nil do
			task.wait()
			number = Indexor(1, maxIndex, 1)
		end
	elseif start == 1 then
		start = 0

		number = Indexor(maxIndex, 1, -1)

		while number == nil do
			task.wait()
			number = Indexor(maxIndex, 1, -1)
		end
	end

	return number
end

local function BulletCreation(info: BulletInfo, player: Player?)
	return promises.new(function(resolve, _, onCancel)
		-- Create an index in activeBullets to track the bullet thaheartbeat:Disconnect(t has been fired
		local index = OpenIndexFinder()
		local bullet = bulletComponent.new(info.Damage, info.Enemy, info.IgnoreTagged, info.MoveTowards, info.BulletDrop, info.DistanceTimeOut, info.Speed, info.Pierce, info.PierceDamageLoss, info.StartPosition)
		
		coroutine.resume(coroutine.create(function()
			bullet:START()
		end))

		local playerId

		if not player then
			playerId = 0
		else
			playerId = player.UserId
		end

		activeBullets[index] = { lookdirection = helper.Conversions.CFrameAnglesToVector3(bullet.move_towards) }

		local heartbeat: RBXScriptConnection

		totalActiveBullets += 1

		local endPosition: Vector3 = info.StartPosition + info.MoveTowards.LookVector * info.DistanceTimeOut

		local travelTime: number = helper.NumberManipulation.Delta(info.StartPosition, endPosition) / info.Speed

		local pierce_amount = table.maxn(bullet.parts_pierced)

		-- Prepares some data to be sent to the client for bullet creation
		local sendInformation = {}
		sendInformation.Index = index
		sendInformation.PierceAmount = pierce_amount
		sendInformation.Position = info.StartPosition
		sendInformation.EndPosition = endPosition - Vector3.new(0, travelTime * info.BulletDrop, 0)
		sendInformation.Speed = info.Speed
		sendInformation.Rotation = helper.Conversions.CFrameAnglesToVector3((info.MoveTowards * CFrame.Angles(0, math.rad(90), 0)))
		sendInformation.ID = playerId

		task.synchronize()
		SendToClients(sendInformation)

		-- Monitor the bullet for specific information
		heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
			activeBullets[index].lookdirection = helper.Conversions.CFrameAnglesToVector3(bullet.look_direction)

			if table.maxn(bullet.parts_pierced) ~= pierce_amount then
				pierce_amount = table.maxn(bullet.parts_pierced)

				SendToClients({ Index = index, PierceAmount = pierce_amount})
			end

			-- When the bullet is destroyed, tell the client to also destroy the bullet
			if bullet.to_destroy == true then
				bullet:Destroy()
				bullet = nil

				totalActiveBullets -= 1

				SendToClients({ Index = index})

				activeBullets[index] = nil

				heartbeat:Disconnect()

				resolve()
			end
		end)

		onCancel(function()
			heartbeat:Disconnect()
			SendToClients({ Index = index})
		end)
	end)
end

function ClientBulletCreation(info: BulletInfo, player: Player)
	helper.Promises.PromiseHandler(BulletCreation, false, info, player):ExceptionHandler()
end

function ServerBulletCreation(info: BulletInfo)
	-- Throttle the server from creating more bullets than this amount
	if totalActiveBullets > 1000 then
		return
	end

	helper.Promises.PromiseHandler(BulletCreation, false, info):ExceptionHandler()
end

script.Parent:BindToMessage("ServerCreate", ServerBulletCreation)
script.Parent:BindToMessage("ClientCreate", ClientBulletCreation)
