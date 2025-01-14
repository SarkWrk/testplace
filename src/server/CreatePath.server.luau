local crsplineModule = require(game:GetService("ReplicatedStorage").CRSplineModules.CatmullRomPath)

local positionsTable = {
    Vector3.new(750, 0, 580),
    Vector3.new(750, 0, 580),
    Vector3.new(788.2, 12, 687.9),
    Vector3.new(839.8, 35.6, 659.6),
    Vector3.new(783.7, 35.6, 680.7),
    Vector3.new(823, 10.7, 603.3),
    Vector3.new(791.9, 10.7, 543.2),
    Vector3.new(853, -107.5, 509.6),
    Vector3.new(853, 61.4, 652.1),
    Vector3.new(812.5, -22.6, 744.8),
    Vector3.new(750, 0, 580),
    Vector3.new(750, 0, 580),
}

local newPath = crsplineModule.fromPoints(positionsTable, 1)

local part = Instance.new("Part")

local trail = Instance.new("Trail")
local attachment1 = Instance.new("Attachment")
local attachment2 = Instance.new("Attachment")

attachment1.Position = Vector3.new(0, 1, 0)
attachment2.Position = Vector3.new(0, -1, 0)
attachment1.Parent = part
attachment2.Parent = part

trail.Parent = part
trail.Attachment0 = attachment1
trail.Attachment1 = attachment2
trail.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(1.000000, 0.000000, 0.000000)),
    ColorSequenceKeypoint.new(1, Color3.new(0.345098, 0.337255, 0.854902))
})

part.Name = "Spline Part"
part.Anchored = true
part.Material = "Neon"
part.Size = Vector3.new(1, 1, 1)
part.Shape = "Ball"
part.Parent = workspace

local length = newPath.Length

local timeScale = 0.5 -- Lerp length


while task.wait() do
    local a = time()
    for i = 0, 1, timeScale/length do
        task.wait(1/timeScale/length)
        part.Position = newPath:Position(i)
    end
    print(math.round(time()-a))
    a = 0
end
