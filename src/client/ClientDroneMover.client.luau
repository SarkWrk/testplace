local catmullRomPath = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("CRSplineModules"):WaitForChild("CatmullRomPath"))
local squash_handler = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies other"):WaitForChild("Squash_Handler"))

game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("DroneDirections").OnClientEvent:Connect(function(prefix: buffer, drone : Model, payload: buffer)
    local decoded_prefix: string = squash_handler.prefix_key.DroneDirections[tostring(squash_handler.prefix_des(prefix))]

    if decoded_prefix:lower() ~= string.lower("DroneMovement") then
        return
    end

    local data = squash_handler.drone_directions.drone_movement.des(squash_handler.frombuffer(payload))

    local positions = {}

    for index, componenets in pairs(data.positions) do
        positions[index] = Vector3.new(componenets.X, componenets.Y, componenets.Z)
    end

    local path = catmullRomPath.fromPoints(positions, 0)

    task.wait()

    for _, v in pairs(drone:GetChildren()) do
        if v:IsA("Part") then
            if v:FindFirstChildOfClass("Trail") then
                v:FindFirstChildOfClass("Trail").Enabled = false
            end
        end
    end

    local travelDistance = path.Length -- studs

    local totalTime = travelDistance/data.drone_speed -- s

    local inc = 0

    for i = 0, 1, (1/(totalTime) * (1/data.drone_path_smoothening)) do
        drone:PivotTo(CFrame.new(path:Position(i)))

        if inc == 0 then
            inc += 1
        elseif inc == 1 then
            for _, v in pairs(drone:GetChildren()) do
                if v:IsA("Part") then
                    if v:FindFirstChildOfClass("Trail") then
                        v:FindFirstChildOfClass("Trail").Enabled = true
                    end
                end
            end
        end

        if i ~= 1 then
            task.wait((1/(totalTime) * (1/data.drone_path_smoothening)))
        end
    end

    game:GetService("Debris"):AddItem(drone, 2)
    
    for _, v in pairs(drone:GetChildren()) do
        if v:IsA("Part") then
            v.Transparency = 1
        end
    end
end)
