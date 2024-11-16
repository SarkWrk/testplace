local catmullRomPath = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies"):WaitForChild("CRSplineModules"):WaitForChild("CatmullRomPath"))

game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("DroneDirections").OnClientEvent:Connect(function(drone : Model, positions : {number : Vector3}, droneSpeed : number, dronePathSmoothening : number)
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

    local totalTime = travelDistance/droneSpeed -- s

    local inc = 0

    for i = 0, 1, (1/(totalTime) * (1/dronePathSmoothening)) do
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
            task.wait((1/(totalTime) * (1/dronePathSmoothening)))
        end
    end

    game:GetService("Debris"):AddItem(drone, 2)
    
    for _, v in pairs(drone:GetChildren()) do
        if v:IsA("Part") then
            v.Transparency = 1
        end
    end
end)
