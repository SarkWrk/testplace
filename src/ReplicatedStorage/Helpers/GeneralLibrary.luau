--!strict

local module = {}

module.Conversions = {}
module.NumberManipulation = {}
module.TableManipulation = {}

--[[
Returns the order of magnitude (b10) of the inputted number.
]]
function module.NumberManipulation.OrderOfMagnitude(number: number): number
	assert(typeof(number) == "number", "'number' is not a number. 'number' type: " .. typeof(number))

	if string.split(tostring(number), "e")[2] then
		return tonumber(string.split(tostring(number), "e")[2]) or 0
	else
		local splitter = string.split(tostring(number), ".")
		local lead = string.len(splitter[1])

		local split = splitter[2]

		if split == nil then
			return lead
		else
			local counter = 0

			for _, v in pairs(string.split(split, "0")) do
				if v ~= "0" then
					break
				else
					counter += 1
				end
			end

			return counter + lead
		end
	end
end

--[[
Returns the inputted number rounded to places amount of decimal places.
]]
function module.NumberManipulation.Rounder(input: number, places: number?): number
	if places == nil then
		places = 0
	end

	assert(typeof(input) == "number", "'input' is not a number. 'input' type: " .. typeof(input))
	assert(typeof(places) == "number", "'places' is not a number. 'places' type: " .. typeof(places))

	local leading, remainder = math.modf(input)
	local extraPlaces = 0

	-- Finds the leading digit
	if math.abs(leading) == 0 then
		extraPlaces = module.NumberManipulation.OrderOfMagnitude(remainder) * -1
	end

	local actualLeading, actualRemainder = math.modf(input * math.pow(10, places + extraPlaces))

	local roundingRemainer

	-- Finds the first didgit after the decimal
	if actualRemainder == 0 then
		roundingRemainer = 0
	else
		if actualRemainder < 0 then
			roundingRemainer = tonumber(string.sub(tostring(actualRemainder), 4, 4)) or 0 * 0.1
		else
			roundingRemainer = tonumber(string.sub(tostring(actualRemainder), 3, 3)) or 0 * 0.1
		end
	end

	-- Rounding, finally!
	local rounded = math.round(actualLeading + roundingRemainer)

	-- Brings it back to the order of magnitude of the original number
	return rounded / math.pow(10, places + extraPlaces)
end

--[[
Truncates the inputted number to the specified amount of places.

Returns a tupple:

number (leading didgits) (NOTE: the leading digits is e-1),

number (order of magnitude (b10)).
]]
function module.NumberManipulation.Truncater(number: number, places: number): (number, number)
	assert(typeof(number) == "number", "'number' is not a number. 'number' type: " .. typeof(number))
	assert(typeof(places) == "number", "'places' is not a number. 'places' type: " .. typeof(places))

	local oom = module.NumberManipulation.OrderOfMagnitude(number) * -1
	local actual = math.floor(number * math.pow(10, oom + places)) / math.pow(10, places)

	return actual, oom * -1
end

--[[
Returns the delta between two numbers or two Vector3s.

Warns if both variables do not match types or are not numbers/Vector3s.
]]
function module.NumberManipulation.Delta(initial: number | Vector3, final: number | Vector3): number
	local initialType = typeof(initial)

	assert(initialType == "number" or "Vector3", "'initial' type is not a number of Vector3. 'initial' type: " .. initialType)
	assert(typeof(final) == initialType, "'final' type does not match initial type. 'final' type: " .. typeof(final) .. " ('initial' type: " .. initialType ..")")

	if typeof(initial) == "number" and typeof(final) == "number" then
		return final - initial
	elseif typeof(initial) == "Vector3" and typeof(final) == "Vector3" then
		return (final - initial).Magnitude
	end
	
	return final - initial
end

--[[
Converts a string to a Vector3. The string must be formatted as "x[seperator]y[seperator]z".

Accepts overloads of:

stringEquivilant [string] → The string that should be converted to a Vector3. 

seperator [string] → The seperator between each positional axis. 

]]
function module.Conversions.StringToVector3(stringEquivilant: string, seperator: string): Vector3
	assert(typeof(stringEquivilant) == "string", "'stringEquivilant' is not a string. 'stringEquivilant' type: " .. typeof(stringEquivilant))
	assert(typeof(seperator) == "string", "'seperator' is not a string. 'seperator' type: " .. typeof(seperator))

	local split = string.split(stringEquivilant, seperator)
	return Vector3.new(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
end

--[[
Returns a CFrame made up of a positional Vector3 and a rotational Vector3. If a rotational Vector3 is not provided, the CFrame will have the rotation (0, 0, 0).

Accepts overloads of:

position [Vector3] → The Vector3 that should be converted to CFrame.new(x, y, z).

rotation [Vector3?] → The Vector3 that should be converted to CFrame.Angles(x, y, z).

]]
function module.Conversions.Vector3ToCFrame(position: Vector3, rotation: Vector3?): CFrame
	if not rotation then
		rotation = Vector3.new()
	end

	assert(typeof(position) == "Vector3", "'position' is not a Vector3. 'position' type: " .. typeof(position))
	assert(typeof(rotation) == "Vector3", "'rotaton' is not a Vector3. 'rotaton' type: " .. typeof(rotation))

	return CFrame.new(position) * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
end

--[[
Converts a Vector3 to a string representation seperated by "seperator". The values of the Vector3 can be rounded if desired. The returned string is formatted as "x[seperator]y[seperator]z".

Accepts overloads of:

vector [Vector3] → The Vector3 that should be converted to a string.

seperator [string] → The seperator between each positional axis.

round [boolean?] → Whether the Vector3 components should be rounded.

places [number?] → How many places to round the components to.

]]
function module.Conversions.Vector3ToString(vector: Vector3, seperator: string, round: boolean?, places: number?): string
	assert(typeof(vector) == "Vector3", "'vector' is not a Vector3. 'vector' type: " .. typeof(vector))
	assert(typeof(seperator) == "string", "'seperator' is not a string. 'seperator' type: " .. typeof(seperator))

	assert(typeof(round) == "boolean" or round == nil, "'round' is not a boolean or nil. 'round''s type: " .. typeof(round))

	if round == true then
		if places == nil then
			places = 0
		end

		assert(typeof(places) == "number", "'places' is not a number. 'places' type: " .. typeof(places))

		return module.NumberManipulation.Rounder(vector.X, places) .. seperator
			.. module.NumberManipulation.Rounder(vector.Y, places) .. seperator
			.. module.NumberManipulation.Rounder(vector.Z, places)
	else
		return vector.X .. seperator .. vector.Y .. seperator .. vector.Z
	end
end

--[[
Converts a CFrame to a string equivilant of its rotation.

Accepts overloads of:

converted [CFrame] → The CFrame that should be converted to a string of its rotation.

round [boolean?] → Whether the Vector3 components should be rounded.

places [number?] → How many places to round the components to.

]]
function module.Conversions.CFrameAnglesToVector3(converted: CFrame, round: boolean?, places: number?): Vector3
	assert(typeof(converted) == "CFrame", "'converted' is not a CFrame. 'converted' type: " .. typeof(converted))

	local angleX, angleY, angleZ = converted:ToEulerAnglesXYZ()
	local tempVector = Vector3.new(angleX, angleY, angleZ)

	if round == true then
		if places == nil then
			places = 0
		end

		assert(typeof(places) == "number", "'places' is not a number. 'places' type: " .. typeof(places))

		return Vector3.new(
			module.NumberManipulation.Rounder(tempVector.X, places),
			module.NumberManipulation.Rounder(tempVector.Y, places),
			module.NumberManipulation.Rounder(tempVector.Z, places)
		)
	else
		return tempVector
	end
end

--[[
Creates a new table ordered based off relative distances.

Accepts overloads of:

tableOfRelativeDistances [table] → The table used to create a new table based off distances closest to the previous index. This table must be formatted as:

{[number1] = {[number2] = {Distance = number, Index = number}}}

Where number1 is the index in the table, number2 the index of the new point, Index (same as number2) corresponds to the index to the corresponding distance number1 is from, and Distance is the distance between the two points.

Returns:

{[number1] = {Distance = number, Index = number}}

Where number1 is the ordered positions based off index 1 in tableOfRelativeDistances, Distance represents the distance between number1 and number1 + 1, and Index represents the original index of the number + 1 in tableOfRelativeDistances.
]]
function module.TableManipulation.OrderRelativeTable(tableOfRelativeDistances : {[number] : {[number] : {Distance : number, Index : number}}}) : {[number] : {Distance : number, Index : number}}
	assert(typeof(tableOfRelativeDistances) == "table", "The passed value is not a table. Value type: " .. typeof(tableOfRelativeDistances))
	assert(table.maxn(tableOfRelativeDistances) ~= 0, "tableOfRelativeDistances is not numerically indexed.")

	local startIndex = 1

    for i, _ in pairs(tableOfRelativeDistances) do
		assert(typeof(tableOfRelativeDistances[i]) == "table", "tableOfRelativeDistances[" .. i .. "] is not a table. The type is: " .. typeof(tableOfRelativeDistances[i]))

        table.sort(tableOfRelativeDistances[i], function(a, b)
			assert(typeof(a.Distance) == "number" and typeof(b.Distance) == "number", "The value of tableOfRelativeDistances[" .. i .. "][x].Distance is not a number. The values are: (a) " .. typeof(a.Distance) .. " (b) " .. typeof(b.Distance))

            if a.Distance < b.Distance then
                return true
            else
                return false
            end
        end)
        task.wait()
    end

	local orderedDistances: {[number] : {Distance : number, Index : number}} = {}

	-- NOTE: SPECIAL CASE IF table.maxn OF tableOfRelativeDistances IS 1
	if table.maxn(tableOfRelativeDistances) == 1 then
		return {[1] = {Distance = tableOfRelativeDistances[1][1].Distance, Index = 1}}
	end

	local usedIndicies = {}

    local incrementer = 0

	--[[
	Inserts a new entry into the ordered table and returns the next index to use for the function
	]]
    local function AddToOrderedDistances(index : number)
        incrementer += 1

		local currentIndex = 1
		local newIndex: number

		if tableOfRelativeDistances[index][currentIndex].Distance ~= math.huge then
			newIndex = tableOfRelativeDistances[index][currentIndex].Index
		else
			currentIndex += 1
			newIndex = tableOfRelativeDistances[index][currentIndex].Index
		end

		if usedIndicies[newIndex] ~= nil then
			while task.wait() do
				currentIndex += 1

				if tableOfRelativeDistances[index][currentIndex].Distance ~= math.huge then
					newIndex = tableOfRelativeDistances[index][currentIndex].Index
				end

				if usedIndicies[newIndex] == nil then
					break
				elseif currentIndex % 15 == 0 then
					task.wait()
				end
			end
		end

		if usedIndicies[newIndex] == nil then
			usedIndicies[newIndex] = 1
		else
			usedIndicies[newIndex] += 1
		end

        orderedDistances[incrementer] = {Distance = tableOfRelativeDistances[index][currentIndex].Distance, Index = newIndex}

        return newIndex
    end

    local prevIndex: number = startIndex

    for _, _ in pairs(tableOfRelativeDistances) do
        prevIndex = AddToOrderedDistances(prevIndex)
    end
    
    return orderedDistances
end

--[[
Creates a new table with subtables containing how far each part is from another.

Accepts overloads of:

tableOfPositions [table] → Table used for creating the subtables. This table must be formatted as:

{[number1?] = Vector3}

Where number1 is an optional index to base all indexes and off of and the value is the Vector3 representation of said index's position in the workspace.

startPoint [Vector3?] → Will be inserted as the first index of the returned table.

Returns:

{[number1] = {Distance = number, Index = number}}

Where number1 is the index based off tableOfPositions, Index is correlated to another index in the table, and Distance is the magnitude of the distance between the two points.
]]
function module.TableManipulation.CreateRelativeTable(tableOfPositions : {[number] : Vector3}, startPoint : Vector3?): {[number] : {[number] : {Distance : number, Index : number}}}
	assert(typeof(tableOfPositions) == "table", "The passed value is not a table. The passed value's type: " .. typeof(tableOfPositions))
	assert(table.maxn(tableOfPositions) ~= 0, "'tableOfPositions' is not numerically indexed or has no values.")

	local relativeDistances = {}

	if startPoint then
		assert(typeof(startPoint) == "Vector3", "'startPoint' is not a Vector3. 'startPoint''s type: " .. typeof(startPoint))
		table.insert(tableOfPositions, 1, startPoint)
	end

    for i : number, actualPosition : Vector3 in pairs(tableOfPositions) do
		assert(typeof(actualPosition) == "Vector3", "'tableOfPositions[" .. i .. "]''s value is not a Vector3. The type is actually: " .. typeof(actualPosition))

        relativeDistances[i] = {}
        for j : number, position : Vector3 in pairs(tableOfPositions) do
			local relative = module.NumberManipulation.Delta(position, actualPosition)
			
			relativeDistances[i][j] = {Distance = relative, Index = j}
        end
		task.wait()
    end

	return relativeDistances
end

return module