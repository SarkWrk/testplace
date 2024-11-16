local _bytenet = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("ByteNet"):WaitForChild("ByteNet"))
local bulletComponent = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("BulletComponent"):WaitForChild("BulletComponent"))
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local promises = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("roblox-lua-promise"):WaitForChild("Promise"))

local activeBullets: { [number]: { ["lookdirection"]: Vector3 } } = {}
local totalActiveBullets = 0
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local maxIndex = 65535
local start = 0

local function SendToClients(
	sendData: {
		Index: number,
		Position: Vector3?,
		EndPosition: Vector3?,
		Speed: number?,
		Rotation: Vector3?,
		ID: number?,
	})

	local createdPacket = {}

	createdPacket.Index = sendData.Index

	if sendData.Position then
		createdPacket.PositionX = sendData.Position.X
		createdPacket.PositionY = sendData.Position.Y
		createdPacket.PositionZ = sendData.Position.Z
	end

	if sendData.EndPosition then
		createdPacket.EndPositionX = sendData.EndPosition.X
		createdPacket.EndPositionY = sendData.EndPosition.Y
		createdPacket.EndPositionZ = sendData.EndPosition.Z
	end

	if sendData.Speed then
		createdPacket.Speed = sendData.Speed
	end

	if sendData.Rotation then
		createdPacket.RotationX = sendData.Rotation.X
		createdPacket.RotationY = sendData.Rotation.Y
		createdPacket.RotationZ = sendData.Rotation.Z
	end

	if sendData.ID then
		createdPacket.ID = sendData.ID
	end

	packets.SBulletCreation.BulletCreation.sendToAll(createdPacket)
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

local function BulletCreation(info: {Damage : number, Enemy : {string}, IgnoreTagged : {string}, MoveTowards : CFrame, BulletDrop : number, DistanceTimeOut : number, Speed : number, Pierce : number, PierceDamageLoss : number, StartPosition : Vector3}, player: Player?)
	return promises.new(function(resolve, _, onCancel)
		-- Create an index in activeBullets to track the bullet thaheartbeat:Disconnect(t has been fired
		local index = OpenIndexFinder()
		local bullet = bulletComponent.interface.New(info)
		local playerId

		if not player then
			playerId = 0
		else
			playerId = player.UserId
		end

		activeBullets[index] = { lookdirection = helper.Conversions.CFrameAnglesToVector3(bullet.Information.MoveTowards) }

		local heartbeat: RBXScriptConnection

		totalActiveBullets += 1

		local endPosition: Vector3 = info.StartPosition + info.MoveTowards.LookVector * info.DistanceTimeOut

		local travelTime: number = helper.NumberManipulation.Delta(info.StartPosition, endPosition) / info.Speed

		-- Prepares some data to be sent to the client for bullet creation
		local sendInformation = {}
		sendInformation.Index = index
		sendInformation.Position = info.StartPosition
		sendInformation.EndPosition = endPosition - Vector3.new(0, travelTime * info.BulletDrop, 0)
		sendInformation.Speed = info.Speed
		sendInformation.Rotation = helper.Conversions.CFrameAnglesToVector3((info.MoveTowards * CFrame.Angles(0, math.rad(90), 0)))
		sendInformation.ID = playerId

		task.synchronize()
		helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(SendToClients, true, sendInformation))

		-- Monitor the bullet for specific information
		heartbeat = game:GetService("RunService").Heartbeat:ConnectParallel(function()
			activeBullets[index].lookdirection = helper.Conversions.CFrameAnglesToVector3(bullet.Variable.LookDirection)

			-- When the bullet is destroyed, tell the client to also destroy the bullet
			if bullet.Variable.ToDestroy == true then
				totalActiveBullets -= 1

				task.synchronize()

				SendToClients({ Index = index })

				activeBullets[index] = nil

				heartbeat:Disconnect()
			end
		end)

		onCancel(function()
			heartbeat:Disconnect()
		end)

		resolve()
	end)
end

function ClientBulletCreation(info: {Damage : number, Enemy : {string}, IgnoreTagged : {string}, MoveTowards : CFrame, BulletDrop : number, DistanceTimeOut : number, Speed : number, Pierce : number, PierceDamageLoss : number, StartPosition : Vector3}, player: Player)
	helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(BulletCreation, false, info, player), false)
end

function ServerBulletCreation(info: {Damage : number, Enemy : {string}, IgnoreTagged : {string}, MoveTowards : CFrame, BulletDrop : number, DistanceTimeOut : number, Speed : number, Pierce : number, PierceDamageLoss : number, StartPosition : Vector3})
	-- Throttle the server from creating more bullets than this amount
	if totalActiveBullets > 1000 then
		return
	end

	helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(BulletCreation, false, info), false)
end

script.Parent:BindToMessage("ServerCreate", ServerBulletCreation)
script.Parent:BindToMessage("ClientCreate", ClientBulletCreation)
