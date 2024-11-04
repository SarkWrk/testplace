local tween
local prevPoint
local nextPoint

while task.wait() do
	prevPoint = nextPoint
	nextPoint = script.Parent.Parent.MoverPositions:GetChildren()
	table.remove(nextPoint, table.find(nextPoint, prevPoint))
	nextPoint = nextPoint[math.random(1, table.maxn(nextPoint))]
	tween = game:GetService("TweenService"):Create(script.Parent, TweenInfo.new(4, Enum.EasingStyle.Linear), {Position = nextPoint.Position})
	tween:Play()
	tween.Completed:Wait()
end