local helper = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))

local character = game:GetService("Players").LocalPlayer.Character
local humanoid : Humanoid = character:FindFirstChild("Humanoid")

local fov_offset : IntValue = game:GetService("Players").LocalPlayer:WaitForChild("FoV")
local base_speed : IntValue = game:GetService("Players").LocalPlayer:WaitForChild("Base_Speed")
local camera = workspace.CurrentCamera

local changing_fov = false

local update_functions = {}
update_functions.ChangeFoV = function(_) : boolean
    changing_fov = false

    local speed : number = humanoid.WalkSpeed

    local delta_base= helper.NumberManipulation.Delta(speed, base_speed.Value)

    -- Base fov is 70
    local change_fov_from_speed = math.abs(delta_base * 2)

    local new_fov = 70 + change_fov_from_speed + fov_offset.Value

    local tweenTime = 0.5

    if new_fov < camera.FieldOfView then
        tweenTime = 0.2
    end

    changing_fov = true

    local tween = game:GetService("TweenService"):Create(camera, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {["FieldOfView"] = new_fov})

    tween:Play()

    local tweenEnded = false
    tween.Completed:Connect(function()
        tweenEnded = true
    end)

    while tweenEnded == false do
        if changing_fov == false then
            tween:Cancel()
            tweenEnded = true
        end
        task.wait()
    end

    changing_fov = false

    return true
end

humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
    update_functions:ChangeFoV()
end)
fov_offset.Changed:Connect(function()
    update_functions:ChangeFoV()
end)
