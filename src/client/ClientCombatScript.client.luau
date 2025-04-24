require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("ByteNet"))
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("ByteNetPackets"))

local promises = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("Promise"))
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local camera = workspace.CurrentCamera
local mouseDown = false
local safetyOff = false
local lastFired = 0
local setArmedManually = false

local log_debug_information = false

function SendBulletInformationPromise()
	return promises.new(function(resolve)
		local cameraRotationX, cameraRotationY, cameraRotationZ = camera.CFrame:ToEulerAnglesXYZ()
	
		packets.BulletCreation.ClientBulletCreation.send({
			PositionX = camera.CFrame.Position.X,
			PositionY = camera.CFrame.Position.Y,
			PositionZ = camera.CFrame.Position.Z,
			RotationX = cameraRotationX,
			RotationY = cameraRotationY,
			RotationZ = cameraRotationZ,
		})
		lastFired = tick()

		resolve("Sent request to fire bullet.")
	end)
end

function SendArmedInformationPromise()
	return promises.new(function(resolve)
		packets.ArmClient.ArmClient.send(nil)

		resolve("Sent request to change Armed status to: " .. tostring(safetyOff) .. ".")
	end)
end

function SendBulletInformation()
	if log_debug_information == true then
		print("Called SendBulletInformation.")
	end

	helper.Promises.PromiseHandler(SendBulletInformationPromise, true):ExceptionHandler(log_debug_information)
end

function SendArmedInformation()
	if log_debug_information == true then
		print("Called SendArmedInformation.")
	end

	safetyOff = not game:GetService("Players").LocalPlayer.Character:GetAttribute("Armed")
	helper.Promises.PromiseHandler(SendArmedInformationPromise, false):ExceptionHandler(log_debug_information)
end

game:GetService("UserInputService").InputBegan:Connect(function(input : InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = true
		
		if safetyOff == false then
			task.wait(0.15)
			
			if mouseDown == false then
				return
			end
			
			SendArmedInformation()
		end

		SendBulletInformation()
		
		task.wait(0.15)
		
		while mouseDown == true do
			SendBulletInformation()
			task.wait(0.1)
		end

	elseif input.KeyCode == Enum.KeyCode.R then
		if safetyOff == false then
			setArmedManually = true
			SendArmedInformation()
		else
			SendArmedInformation()
			setArmedManually = false
		end
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input : InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = false
	end
end)

while task.wait() do
	if safetyOff == true and tick()-lastFired >= 0.5 and mouseDown == false and setArmedManually == false then
		SendArmedInformation()
	end
end