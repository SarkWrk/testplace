local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local promises = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("roblox-lua-promise"):WaitForChild("Promise"))
local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local camera = workspace.CurrentCamera
local mouseDown = false
local safetyOff = false
local lastFired = 0
local setArmedManually = false

function SendBulletInformation()
	return promises.new(function(resolve)
		local cameraRotationX, cameraRotationY, cameraRotationZ = camera.CFrame:ToEulerAnglesXYZ()
	
		packets.CBulletCreation.ClientBulletCreation.send({
			PositionX = camera.CFrame.Position.X,
			PositionY = camera.CFrame.Position.Y,
			PositionZ = camera.CFrame.Position.Z,
			RotationX = cameraRotationX,
			RotationY = cameraRotationY,
			RotationZ = cameraRotationZ,
		})
		lastFired = tick()

		resolve()
	end)
end

function SendArmedInformation(status : boolean)
	return promises.new(function(resolve)
		packets.ArmClient.ArmClient.send(status)
		safetyOff = status

		resolve()
	end)
end

game:GetService("UserInputService").InputBegan:Connect(function(input : InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = true
		
		if safetyOff == false then
			task.wait(0.15)
			
			if mouseDown == false then
				return
			end
			
			helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(SendArmedInformation, true, true))
		end
		
		helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(SendBulletInformation, false), true)
		
		task.wait(0.15)
		
		while mouseDown == true do
			helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(SendBulletInformation, false), true)
			task.wait(0.1)
		end
		
	elseif input.KeyCode == Enum.KeyCode.R then
		if safetyOff == false then
			setArmedManually = true
			helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(SendArmedInformation, false, true))
		else
			helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(SendArmedInformation, false, false))
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
		helper.Promises.ExceptionHandler(helper.Promises.PromiseHandler(SendArmedInformation, true, false))
	end
	
	script:SetAttribute("Safety", not safetyOff)
end