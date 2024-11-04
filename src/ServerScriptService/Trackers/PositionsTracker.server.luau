local collectionservice = game:GetService("CollectionService")
local tagInformation = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("PositionsTrackerTagList"))
local tagsList = collectionservice:GetAllTags()
local catmullRomPath = require(game:GetService("ReplicatedStorage"):WaitForChild("CRSplineModules"):WaitForChild("CatmullRomPath"))
local droneModel: Model = game:GetService("ServerStorage"):WaitForChild("Drone")
local helperModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local debrisService = game:GetService("Debris")
local keyInformation = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("MissionImportantPositions")).TestPlace
local random = Random.new()
local packets = require(game:GetService("ReplicatedStorage"):WaitForChild("ByteNet"):WaitForChild("Packets"))
local promises = require(game:GetService("ReplicatedStorage"):WaitForChild("roblox-lua-promise"):WaitForChild("Promise"))

local dronePathSmoothening = 100
local droneSpeed = 100

local wantedTags = {}
local positionalInformation = game:GetService("SharedTableRegistry"):GetSharedTable("PositionsTrackerTable")

for _, tag : string in pairs(tagsList) do
    if not table.find(tagInformation.UnwantedTagsd, tag) then
        table.insert(wantedTags, tag)
    end
end

--[[
Creates and parents trails to each "Blade" on the drone model.
]]
local function SetupDroneTrail(drone : Model)
    local success, warning = pcall(function()
        for _, v in pairs(drone:GetChildren()) do
            if v:IsA("Part") and v.Name == "Blade" then
                local attachment0 = Instance.new("Attachment")
                local attachment1 = Instance.new("Attachment")

                attachment0.Name = "0"
                attachment1.Name = "1"

                local choice = random:NextInteger(0, 1)

                if choice == 1 then
                    attachment0.Position = Vector3.new(0.5, 0.5, 0.5)
                    attachment1.Position = Vector3.new(-0.5, -0.5, -0.5)
                else
                    attachment0.Position = Vector3.new(0.5, -0.5, -0.5)
                    attachment1.Position = Vector3.new(-0.5, 0.5, 0.5)
                end

                local trail = Instance.new("Trail")

                local trailStartColour = Color3.new(1, 1, 1)
                local trailPost_StartColour = Color3.new(1, 1, 1)
                local trailPre_EndColour = Color3.new(0, 0, 0)
                local trailEndcolour = Color3.new(0, 0, 0)
                local trailStartTransparency = 0.5
                local trailEndTransparency = 0.1
                local trailStartWidth = 0.7
                local trailEndWidth = 0

                trail.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, trailStartColour),
                ColorSequenceKeypoint.new(0.3, trailPost_StartColour),
                ColorSequenceKeypoint.new(0.75, trailPre_EndColour),
                ColorSequenceKeypoint.new(1, trailEndcolour)
                })
                trail.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, trailStartTransparency),
                NumberSequenceKeypoint.new(1, trailEndTransparency)
                })
                trail.WidthScale = NumberSequence.new({
                NumberSequenceKeypoint.new(0, trailStartWidth),
                NumberSequenceKeypoint.new(0.5, trailStartWidth),
                NumberSequenceKeypoint.new(1, trailEndWidth)
                })
                trail.LightInfluence = 0

                trail.Attachment0 = attachment0
                trail.Attachment1 = attachment1

                attachment0.Parent = v
                attachment1.Parent = v
                trail.Parent = v
            end
        end
    end)

    if not success then
        warn("Could not set-up trails for drone. Error message: " .. warning)
    end
end

local function SortPositionTable(positionalData : {[Instance] : Vector3}, startPosition : Vector3?)
    local positionTable = {}  

    for _, position in pairs(positionalData) do
        positionTable[table.maxn(positionTable) + 1] = position + Vector3.new(0, 2.5, 0)
    end
    local newPositionTable = {}

    local orderedDistances

    if startPosition then
        orderedDistances = helperModule.TableManipulation.OrderRelativeTable(helperModule.TableManipulation.CreateRelativeTable(positionTable, startPosition))
    else
        orderedDistances = helperModule.TableManipulation.OrderRelativeTable(helperModule.TableManipulation.CreateRelativeTable(positionTable))
    end

    for i : number, subtable : {Distance : number, Index : number} in pairs(orderedDistances) do
        newPositionTable[i] = positionTable[subtable.Index]

        if i % 15 == 0 then
            task.wait()
        end
    end

    if startPosition then
        table.remove(newPositionTable, table.find(newPositionTable, startPosition))
    end

    return newPositionTable
end

local function  FlyDrone(data : {{["Position"] : Vector3, ["Instance"] : Instance}})
    local droneStartingPOsitions = workspace.DroneStartPositions:GetChildren()
    local startingPart : Part = droneStartingPOsitions[math.random(1, #workspace.DroneStartPositions:GetChildren())]
    local startingPosition : Vector3 = startingPart.Position

    local positionalData = {}

    for _, v in pairs(data) do
        positionalData[v.Instance] = v.Position
    end

    local sortedPositions = SortPositionTable(positionalData, startingPosition)

    if table.maxn(sortedPositions) == 0 then
        return
    end

    local fixedPositionalData = {}

    local function InsertStartPosition(times :number)
        for _ = 1, times do
            table.insert(fixedPositionalData, startingPosition)
        end
    end

    InsertStartPosition(2)

    for _, position in pairs(sortedPositions) do
        table.insert(fixedPositionalData, position)
    end

    InsertStartPosition(2)

    task.synchronize()

    local drone = droneModel:Clone()
    
    SetupDroneTrail(drone)

    local path = catmullRomPath.fromPoints(fixedPositionalData, 0)

    local travelDistance = path.Length -- studs

    local totalTime = travelDistance/droneSpeed -- s

    drone.Parent = workspace.Drones

    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("DroneDirections"):FireAllClients(drone, fixedPositionalData, droneSpeed, dronePathSmoothening)

    task.wait(totalTime)

    coroutine.resume(coroutine.create(function()
        debrisService:AddItem(drone, 2)
    end))

    task.desynchronize()
end

local function PositionTableIndexedByInstancePathName(positionTable)
    local updatedPositionalTable = {}

    for _, v : {["Position"] : Vector3, ["Instance"] : Instance} in pairs(positionTable) do
        local instancePath = v.Instance:GetFullName()

        if updatedPositionalTable[instancePath] ~= nil then
            warn("Duplicate entries in positionTable (PositionTableIndexedByInstancePathName). New instances of the same index are dropped.")
        else
            updatedPositionalTable[instancePath] = v.Position
        end
    end

    return updatedPositionalTable
end

local function ReportLocations(positions : {[string] : Vector3}, tag : string)
    return promises.new(function(resolve)
        local output = "Trouvé " .. tag .. ".e(s) à :"
        local addToTotalSpace = 10
    
        for part: string, position in pairs(positions) do
            local locatedAtPosition = ""
            local splitString = part:split(".")
            local name = splitString[table.maxn(splitString)]
            local lenName = name:len()
    
            for _ = 1, math.clamp(addToTotalSpace-lenName, 0, math.huge) do
                name = name .. " "
            end
    
            for location : string, info : {Vector : Vector3, Range : number} in pairs(keyInformation) do
                if location ~= "Origine" then
                    local a = (position-info.Vector).Magnitude
    
                    if a <= info.Range then
                        locatedAtPosition = location
                    end
                end
            end
    
            if locatedAtPosition == "" then
                local relAlt, altExp = helperModule.NumberManipulation.Truncater((Vector3.new(0, position.Y, 0)-Vector3.new(0, keyInformation.Origine.Y, 0)).Magnitude, 3)
                local relDist, distExp = helperModule.NumberManipulation.Truncater((Vector3.new(position.X, 0, position.Z)-Vector3.new(keyInformation.Origine.X, 0, keyInformation.Origine.Z)).Magnitude, 3)

                output = output .. "<br />" .. name .. " à alt. rel. : <i>" .. relAlt * 10 .. "e" .. altExp - 1
                .. "</i> et dist. rel. : <i>" .. relDist * 10 .. distExp - 1 .. "</i>."
            else
                output = output .. "<br />" .. name .. " à <i>" .. locatedAtPosition .. "</i>."
            end
        end
    
        packets.SendPositionalInformation.SendPositionalInformation.sendToAll(output)

        resolve("Sent")
    end)
end

local function FindPosition(tag : string) : {{["Position"] : Vector3, ["Instance"] : Instance}}
    task.desynchronize()
    local positionalTable = {}

    local instances = collectionservice:GetTagged(tag)

    for _, thing : Part|Model in pairs(instances) do
        if thing:IsA("Part") then
            table.insert(positionalTable, {Position = thing.Position, Instance = thing})

        elseif thing:IsA("Model") then
            local primaryPart = thing.PrimaryPart

            if primaryPart then
                table.insert(positionalTable, {Position = primaryPart.Position, Instance = thing})
            else
                warn(thing:GetFullName() .. " does not have a PrimaryPart. Cannot determine position.")
            end
        end
        task.wait()
    end

    SharedTable.update(positionalInformation[tag], "DroneMoving", function()
        return true
    end)

    FlyDrone(positionalTable)

    SharedTable.update(positionalInformation[tag], "DroneMoving", function()
        return false
    end)

    SharedTable.update(positionalInformation[tag], "PositionalData", function()
        return PositionTableIndexedByInstancePathName(positionalTable)
    end)

    ReportLocations(PositionTableIndexedByInstancePathName(positionalTable), tag):andThen(print)

    return positionalTable
end

local function SetupPositionalInformationTick()
    for _, tag : string in pairs(wantedTags) do
        local locTable = SharedTable.new()

        SharedTable.update(locTable, "PositionalData", function()
            return SharedTable.new()
        end)

        SharedTable.update(locTable, "LastUpdated", function()
            return tick()
        end)

        SharedTable.update(locTable, "DroneMoving", function()
            return false
        end)

        SharedTable.update(locTable, "UpdateDelay", function()
            local updateDelay = tagInformation.TagWaitTime[tag]
    
            if updateDelay == nil then
                updateDelay = tagInformation.DefaultWaitTime
            end

            return updateDelay
        end)

        SharedTable.update(positionalInformation, tag, function()
            return SharedTable.clone(locTable, true)
        end)
    end
end

SetupPositionalInformationTick()

while task.wait() do
    for _, tag : string in pairs(wantedTags) do
        if tick() - positionalInformation[tag].LastUpdated >= positionalInformation[tag].UpdateDelay and positionalInformation[tag].DroneMoving == false then
            SharedTable.update(positionalInformation[tag], "LastUpdated", function()
                return tick()
            end)
            
            coroutine.resume(coroutine.create(function()
                FindPosition(tag)
            end))
        end
    end
end
