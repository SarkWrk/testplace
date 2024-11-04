local module = {}

module.Conversions = {}
module.NumberManipulation = {}
module.TableManipulation = {}

--[[
Returns the order of magnitude (b10) of the inputted number.
]]
function module.NumberManipulation.OrderOfMagnitude(number: number): number
	assert(typeof(number) == "number", "Number is not a <number>. Number type: " .. typeof(number))

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
function module.NumberManipulation.Rounder(input: number, places: number): number
	assert(typeof(input) == "number", "Input is not a <number>. Input type: " .. typeof(input))
	assert(typeof(places) == "number", "Places is not a <number>. Pumber type: " .. typeof(places))

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
			roundingRemainer = tonumber(string.sub(actualRemainder, 4, 4)) or 0 * 0.1
		else
			roundingRemainer = tonumber(string.sub(actualRemainder, 3, 3)) or 0 * 0.1
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
	assert(typeof(number) == "number", "Number is not a <number>. Number type: " .. typeof(number))
	assert(typeof(places) == "number", "Places is not a <number>. Pumber type: " .. typeof(places))

	local oom = module.NumberManipulation.OrderOfMagnitude(number) * -1
	local actual = math.floor(number * math.pow(10, oom + places)) / math.pow(10, places)

	return actual, oom * -1
end

--[[
Returns the delta between two numbers or two Vector3s.

Warns if both variables do not match types or are not numbers/Vector3s.
]]
function module.NumberManipulation.Delta(initial: number | Vector3, final: number | Vector3): number
	assert(typeof(initial) == "number" or "Vector3", "Initial type is not a number of Vector3. Initial type: " .. typeof(initial))
	assert(typeof(final) == "number" or "Vector3", "Fnitial type is not a number of Vector3. Fnitial type: " .. typeof(final))

	if typeof(initial) == "number" and typeof(final) == "number" then
		return final - initial
	elseif typeof(initial) == "Vector3" and typeof(final) == "Vector3" then
		return (final - initial).Magnitude
	else
		error("Types passed to GeneralLibrary:Delta() are not matching.")
	end
end

--[[
Converts a string to a Vector3. The string must be formatted as "x[seperator]y[seperator]z".

Accepts overloads of:

stringEquivilant [string] → The string that should be converted to a Vector3. 

seperator [string] → The seperator between each positional axis. 

]]
function module.Conversions.StringToVector3(stringEquivilant: string, seperator: string): Vector3
	assert(typeof(stringEquivilant) == "string", "StringEquivilant is not a <string>. StringEquivilant type: " .. typeof(stringEquivilant))
	assert(typeof(seperator) == "string", "Seperator is not a <string>. Seperator type: " .. typeof(seperator))

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

	assert(typeof(position) == "Vector3", "Position is not a <Vector3>. Position type: " .. typeof(position))
	assert(typeof(rotation) == "Vector3", "Rotaton is not a <Vector3>. Rotaton type: " .. typeof(rotation))

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
function module.Conversions.Vector3ToString(vector: Vector3, seperator: string, round: boolean?, places: number?): string | nil
	assert(typeof(vector) == "Vector3", "Vector is not a <Vector3>. Vector type: " .. typeof(vector))
	assert(typeof(seperator) == "string", "Seperator is not a <string>. Seperator type: " .. typeof(seperator))

	if round == true then
		assert(typeof(places) == "string", "Places is not a <number>. Places type: " .. typeof(places))

		places = places :: number
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
	assert(typeof(converted) == "CFrame", "Converted is not a <CFrame>. Converted type: " .. typeof(converted))

	local angleX, angleY, angleZ = converted:ToEulerAnglesXYZ()
	local tempVector = Vector3.new(angleX, angleY, angleZ)

	if round == true then
		assert(typeof(places) == "string", "Places is not a <number>. Places type: " .. typeof(places))

		places = places :: number
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
Creates a new table ordered based off relative distances. NOTE: The inputted table's subtables must first be ordered.

Accepts overloads of:

tableOfRelativeDistances [table] → The table used to create a new table based off distances closest to the previous index. This table must be formatted as:

{[number1] = {Distance = number, Index = number}}

Where number1 is the index in the table, Index corresponds to the index to the corresponding distance number1 is from, and Distance is the distance between the two points.

Returns:

{[number1] = {Distance = number, Index = number}}

Where number1 is the ordered positions based off index 1 in tableOfRelativeDistances, Distance represents the distance between number1 and number1 + 1, and Index represents the original index of the number + 1 in tableOfRelativeDistances.
]]
function module.TableManipulation.OrderRelativeTable(tableOfRelativeDistances : {number : {number : {Distance : number, Index : number}}}) : {[number] : {Distance : number, Index : number}}
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

    local prevIndex: number = 1

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

NOTE: When number1 and Index are the same, Distance is math.huge.
]]
function module.TableManipulation.CreateRelativeTable(tableOfPositions : {number : Vector3}, startPoint : Vector3?): {number : {number : {Distance : number, Index : number}}}
	local relativeDistances = {}

	if startPoint then
		table.insert(tableOfPositions, 1, startPoint)
	end

    for i : number, actualPosition : Vector3 in pairs(tableOfPositions) do
        relativeDistances[i] = {}
        for j : number, position : Vector3 in pairs(tableOfPositions) do
			local relative = (actualPosition-position).Magnitude
			
			if relative ~= 0 then
				relativeDistances[i][j] = {Distance = relative, Index = j}
			else
				relativeDistances[i][j] = {Distance = math.huge, Index = j}
			end
        end
		task.wait()
    end

	return relativeDistances
end

return module