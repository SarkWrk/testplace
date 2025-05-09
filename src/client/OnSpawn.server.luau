local player:Player = game:GetService("Players")[script.Parent.Name]

function InitEffects()
    script.Parent:AddTag(player.Name) --"Player")

    local fov = Instance.new("IntValue")
    fov.Name = "FoV"
    fov.Parent = player
    
    local speed = Instance.new("IntValue")
    speed.Name = "Base_Speed"
    speed.Value = 16
    speed.Parent = player
end

InitEffects()
