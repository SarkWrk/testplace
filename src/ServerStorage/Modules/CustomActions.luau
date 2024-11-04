local actionTable = {}

actionTable.Teleport = function(part : Model, endPosition : Vector3)
	local primaryPart = part.PrimaryPart
	if primaryPart then
		part:PivotTo(CFrame.new(endPosition + Vector3.new(0, primaryPart.Position.Y, 0)))
	end
end

return actionTable
