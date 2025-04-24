require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("ByteNet"))

local bulletComponent = require(game:GetService("ServerStorage"):WaitForChild("Components"):WaitForChild("BulletComponent"):WaitForChild("BulletComponent"))
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("ByteNetPackets"))
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

	createdPacket.Index = sendData.Index

	if sendData.PierceAmount then
		createdPacket.PierceAmount = sendData.PierceAmount
	end

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

	packets.BulletCreation.ServerBulletCreation.sendToAll(createdPacket)
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

		local pierce_amount = table.maxn(bullet.Variable.PartsPierced)

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
			activeBullets[index].lookdirection = helper.Conversions.CFrameAnglesToVector3(bullet.Variable.LookDirection)

			if table.maxn(bullet.Variable.PartsPierced) ~= pierce_amount then
				pierce_amount = table.maxn(bullet.Variable.PartsPierced)

				SendToClients({ Index = index, PierceAmount = pierce_amount})
			end

			-- When the bullet is destroyed, tell the client to also destroy the bullet
			if bullet.Variable.ToDestroy == true then
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
