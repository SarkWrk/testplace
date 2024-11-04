local globalTable = game:GetService("SharedTableRegistry"):GetSharedTable("TrackedPlayerData")

--[[
Creates a new sharedtable at index playerName if one doesn't already exist.
]]
local function CreatePlayerSharedTable(playerName : string)
    if globalTable[playerName] == nil then
        SharedTable.update(globalTable, playerName, function()
            return SharedTable.new()
        end)
    end
end

--[[
Tracks a player's HP and position until they die.
]]
local function TrackPlayerStats(character : Model, playerName : string)
    local humanoid:Humanoid? = character:FindFirstChildOfClass("Humanoid")
    local primaryPart: BasePart? = character.PrimaryPart
    local lastUpdated = 0

    local function UpdateStats()
        if humanoid then
            SharedTable.update(globalTable[playerName], "Health", function()
                return humanoid.Health
            end)
        end

        if primaryPart then
            SharedTable.update(globalTable[playerName], "Position", function()
                return primaryPart.Position
            end)
        end
    end

    local died = false

    if humanoid then
        humanoid.Died:Connect(function()
            died = true
        end)
    end

    while task.wait() do
        if tick()-lastUpdated >= 0.5 then
            lastUpdated = tick()
            UpdateStats()
        end

        if died == true then
            UpdateStats()
            break
        end
    end
end

game:GetService("Players").PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        CreatePlayerSharedTable(player.Name)

        TrackPlayerStats(character, player.Name)
    end)
end)