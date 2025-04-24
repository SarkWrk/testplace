-- Class
local class = {}

-- Services
local Shared_Table_Registry = game:GetService("SharedTableRegistry")
local Replicated_Storage = game:GetService("ReplicatedStorage")
local Pathfinding_Service = game:GetService("PathfindingService")
local Collection_Service = game:GetService("CollectionService")

-- Dependencies
local _Types = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("Types"))
local HelperModule = require(Replicated_Storage:WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local Fast_Signal = require(Replicated_Storage:WaitForChild("dependencies wally"):WaitForChild("FastSignal"))
local Promises = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("Promise"))

class.interface = {}
class.schema = {}

--[[
Subtable to hold all combat functions.
]]
class.schema.combatHandler = {}

class.metatable = { __index = class.schema }

--[[
Use this function to create a new AIPathfindingComponent.
]]
function class.interface.new(rig: Model, stateManagerScript: Script, ownerScript : Script): AIPathfindingComponent
	local self = setmetatable({}, class.metatable)

	--[[
	A table containing important information necessary for class functionaility because they're (probably) asked for a lot.
	]]
	self._important = {
		_rig = rig,
		_state_manager_script = stateManagerScript,
		_script =  ownerScript,
	}

	self.information = self:SetUpInformation() :: information
	self.signals = self:SetUpSignals() :: signals

	return self
end

--[[
Sets up the signals used in this class.
]]
function class.schema.SetUpSignals(): signals
	--[[
    Contain the signals that will be fired by this component.

    Note: Changed is a global variable that will fire whenever something notable (except when Destroying fires) changes.
    ]]
	local signals = {}

	signals.Changed = Fast_Signal.new()
	signals.Destroying = Fast_Signal.new()
	signals.StartedMoving = Fast_Signal.new()
	signals.StoppedMoving = Fast_Signal.new()
	signals._CustomWaypointActions = Fast_Signal.new()
	signals.SearchBegan = Fast_Signal.new()
	signals.SearchFinished = Fast_Signal.new()

	return signals
end

--[[
Sets up underlying information required for the class to run. Values with the prefix '_' should not be touched.
]]
function class.schema.SetUpInformation(): information
	--[[
    Contains various variables and subtables used for the tasks that this component does.
    ]]
	local information = {
		-- Variables that shouldn't be modified
		_stop_pathfinding = false,
		_dead = false,

		-- Modifiable variables
		random = Random.new(),
		difficulty = 100,
	}

	--[[
    Contains the potential tags that the component will take into consideration when pathfinding.
    ]]
	information.targettags = {
		"Goal",
	}

	--[[
    DO NOT TOUCH!

    Contains information about the current target, positions of every possible target, and the SharedTable used to find the positions of targets.
    ]]
	information._targetinformation = {
		_positions = {},
		_target = nil,
		_shared_table = Shared_Table_Registry:GetSharedTable("PositionsTrackerTable"),
	}

	--[[
    Contains information used when pathfinding.
    ]]
	information.pathfindinginformation = {
		-- Variables that shouldn't be modified
		_path = nil,
		_stop_pathing = false,

		-- Modifiable variables
		viewDistance = 100,
		searchTries = 5,
	}

	--[[
    Contains the settings used when creating a Path using PathfindingService:CreatePath().
    ]]
	information.pathfindinginformation.settings = {
		--Modifiable variables
		AgentRadius = 2,
		AgentHeight = 5,
		waypointSpacing = 1,
		Costs = {},

		PathSettings = {
			SupportPartialPath = true,
		},
	}

	--[[
    Contains information used during pathfinding on what to do in combat situations.
    ]]
	information.pathfindinginformation.combatsettings = {
		-- Variables that shouldn't be modified

		-- Modifiable varibles
		shouldStopOnEnemySight = true,
		movespeedReductionOnEnemySight = 8,
		grenadeAvoidanceRadius = 40,
	}

	--[[
    Contains information used when visualising things from this component.
    ]]
	information.visualisationinformation = {
		-- Variables that shouldn't be modified
		_visualisation_folder = nil,
		_visualisation_folder_name = "Visualiser" .. information.random:NextNumber(1, 1000000000),

		-- Modifiable variables
		visualisePath = true,
		visualisationSpacing = 1,
		normalNodeSize = 1,
		jumpNodeSizeMultiplier = 2,
		customNodeSizeMultiplier = 3,
	}

	--[[
    Contains used information about AICombatComponent.
    ]]
	information.combatinformation = {
		-- Variables that shouldn't be modified
		_spotted_enemy = false,
		_avoiding_grenade = false,

		-- Modifiable variables
	}

	return information
end

--[[
Basic handler for firing events. Used as a wrapper for event firing.
]]
function class.schema._EventWrapper(self : AIPathfindingComponent, from: string, eventName : string?, ...)
	local extraInformation = ...

	self.signals.Changed:Fire(from, extraInformation)

	if eventName then
		if typeof(self.signals[eventName]) == nil then
			self.signals[eventName] = Fast_Signal.new()
		end

		self.signals[eventName]:Fire(extraInformation)
	end
end

--[[
This function cleans up the component to be able to be GC'd. Any connections to Destroying and Changed are given 2 seconds before being disconnected.
    
Note: The class will be set to nil after the 2 seconds.
]]
function class.schema.Destroy(self: AIPathfindingComponent)
	self.signals.Destroying:Fire()

	local destroyStartTime = tick()

	self.information._stop_pathfinding = true

	local function DestroyObjects()
		if self.information.visualisationinformation._visualisation_folder ~= nil then
			self.information.visualisationinformation._visualisation_folder:Destroy()
		end

		if self.information.pathfindinginformation._path then
			self.information.pathfindinginformation._path:DEstroy()
		end

		self.information.random = nil
	end

	local function RemoveSignals()
		for signal_name, signal in pairs(self.signals) do
			if signal_name == "Destroying" then
				continue
			end

			if signal_name == "Changed" then
				continue
			end

			signal:Destroy()
		end
	end

	DestroyObjects()

	RemoveSignals()

	while tick() - destroyStartTime < 2 do
		task.wait()
	end

	self.signals.Changed:Destroy()
	self.signals.Destroying:Destroy()

	self.signals = nil
end

--[[
Function used to visualise the path the rig takes to get to a goal
]]
function class.schema._PathVisualiser(self: AIPathfindingComponent, waypoints: { PathWaypoint })
	local foundFolder = Instance.new("Folder")

	if self.information.visualisationinformation._visualisation_folder == nil then
		local newFolder = Instance.new("Folder")
		newFolder.Name = self.information.visualisationinformation._visualisation_folder_name
		newFolder.Parent = workspace
		self.information.visualisationinformation._visualisation_folder = newFolder
	end

	foundFolder.Parent = self.information.visualisationinformation._visualisation_folder

	-- Checks if the visualisation node spacing is less than the agent waypoint spacing, and if so sets the visualisation node spacing to the agent's
	if
		self.information.visualisationinformation.visualisationSpacing
		< self.information.pathfindinginformation.settings.waypointSpacing
	then
		print(
			"Setting visualisationinformation.visualisationSpacing to "
				.. self.information.pathfindinginformation.settings.waypointSpacing
				.. " (Previously: "
				.. self.information.visualisationinformation.visualisationSpacing
				.. ")"
		)
		self.information.visualisationinformation.visualisationSpacing =
			self.information.pathfindinginformation.settings.waypointSpacing
	end

	local spacer = self.information.visualisationinformation.visualisationSpacing
		/ self.information.pathfindinginformation.settings.waypointSpacing --[[ Calculates
	how often to create a visualised node]]
	local counter = 0 -- Keeps track of when to place a node

	-- Loops through each waypoint and creates a node based off the spacer value
	for i, v: PathWaypoint in pairs(waypoints) do
		-- Creates the node part, determines its colour based off the action, and determines if the node should be shown (otherwise it's skipped)
		local waypoint = Instance.new("Part")
		counter += 1 -- Increments the counter

		-- Jump actions are never skipped, have visualisationinformation.jumpNodeSizeMultiplier the size of a normal node, and are given a GREEN colour
		if v.Action == Enum.PathWaypointAction.Jump then
			counter = 0 -- Resets the counter
			waypoint.Color = Color3.new(0.278431, 0.674510, 0.082353) -- Sets the colour
			waypoint.Size = Vector3.new(
				self.information.visualisationinformation.normalNodeSize
					* self.information.visualisationinformation.jumpNodeSizeMultiplier,
				self.information.visualisationinformation.normalNodeSize
					* self.information.visualisationinformation.jumpNodeSizeMultiplier,
				self.information.visualisationinformation.normalNodeSize
					* self.information.visualisationinformation.jumpNodeSizeMultiplier
			)

			-- Custom actions are never skipped, have visualisationinformation.customNodeSizeMultiplier the size of a normal node, and are given a PINK-ISH-WHITE colour
		elseif v.Action == Enum.PathWaypointAction.Custom then
			counter = 0 -- Resets the counter
			waypoint.Color = Color3.new(1.000000, 0.537255, 1.000000) -- Sets the colour
			waypoint.Size = Vector3.new(
				self.information.visualisationinformation.normalNodeSize
					* self.information.visualisationinformation.customNodeSizeMultiplier,
				self.information.visualisationinformation.normalNodeSize
					* self.information.visualisationinformation.customNodeSizeMultiplier,
				self.information.visualisationinformation.normalNodeSize
					* self.information.visualisationinformation.customNodeSizeMultiplier
			)

			-- Walk actions can be skipped, and are given an ORANGE colour
		else
			if counter % spacer ~= 0 then -- Checks whether to skip the node
				continue
			end

			waypoint.Color = Color3.new(0.639216, 0.454902, 0.086275) -- Sets the colour
			waypoint.Size = Vector3.new(0.5, 0.5, 0.5) -- Sets the size of the node to be 0.5 studes X 0.5 studs X 0.5 studs
		end

		-- General management for making the node more distinct
		waypoint.Name = "Point" .. i -- Gives the node its node value (1, 2, 3 ... n where each value a waypoint (i.e. waypoint 1, waypoint 2, waypoint 3 ... waypoint n))
		waypoint.Shape = "Ball" -- Sets the shape of the node to be a sphere
		waypoint.Material = Enum.Material.Neon -- Sets the material of the node to glow
		waypoint.Position = v.Position -- Sets the position of the node to the waypoint position
		waypoint.CanCollide = false -- Sets the ability to collide with the node to false
		waypoint.Anchored = true -- Sets the anchored property of the node to true
		waypoint.Locked = true -- Sets the locked property of the node to true
		waypoint:AddTag("Visualiser")

		local waypointLabelText = "WP: " .. i
		local textSize = 10

		local billboard = Instance.new("BillboardGui")
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.Size = UDim2.fromOffset(waypointLabelText:len(), textSize)

		local waypointLabel = Instance.new("TextLabel")
		waypointLabel.Size = UDim2.fromOffset(waypointLabelText:len(), textSize)
		waypointLabel.Text = waypointLabelText
		waypointLabel.BackgroundTransparency = 1
		waypointLabel.TextSize = textSize

		waypointLabel.Parent = billboard

		billboard.Parent = waypoint
		waypoint.Parent = foundFolder -- Parents the node to the folder
	end

	coroutine.resume(coroutine.create(function()
		self.signals.StoppedMoving:Wait()

		foundFolder:Destroy()
	end))

	self._EventWrapper(self, "_PathVisualiser", nil, foundFolder)
end

--[[
Contains various functions that can be used in combat situations.
The functions require a pre-set 'fromFunction-want' pairing to work.
This function always returns void.
Warns if a specific 'fromFunction-want' pairing has not been created.

`fromFunction` : The function calling combatHandler._Main.

`want` : The function that should be ran by combatHandler._Main.
]]
function class.schema.combatHandler._Main(
	self: AIPathfindingComponent,
	fromFunction: "Move" | "CombatHandler",
	want: "Halt" | "Grenade"
): boolean | string
	self._EventWrapper(self, "combatHandler._Main", nil, fromFunction, want)
	
	local function Halt()
		if self.information.combatinformation._spotted_enemy == false then
			return false
		end

		local reducedSpeed = false

		if self.information.pathfindinginformation.combatsettings.shouldStopOnEnemySight == false then
			reducedSpeed = true
			self._important._state_manager_script:SetAttribute(
				"Walkspeed",
				self._important._state_manager_script:GetAttribute("Walkspeed")
					- self.information.pathfindinginformation.combatsettings.movespeedReductionOnEnemySight
			)
		end

		while self.information.combatinformation._spotted_enemy == true do
			if self.information._stop_pathfinding == true then
				break
			end

			self.combatHandler._Main(self, "CombatHandler", "Grenade")
			task.wait()
		end

		if reducedSpeed == true then
			self._important._state_manager_script:SetAttribute(
				"Walkspeed",
				self._important._state_manager_script:GetAttribute("Walkspeed")
					+ self.information.pathfindinginformation.combatsettings.movespeedReductionOnEnemySight
			)
		end

		return true
	end

	--[[
    Checks if there're any greandes nearby, and if so tries to avoid them.
    ]]
	local function AvoidGrenade()
		local grenades = Collection_Service:GetTagged("Grenade")

		if table.maxn(grenades) == 0 then
			return false
		end

		local nearbyGrenades = {}

		local function RaycastPositionToGrenade(position, grenadePosition)
			local params = RaycastParams.new()

			params.FilterType = Enum.RaycastFilterType.Exclude
			params:AddToFilter(Collection_Service:GetTagged("Bullets"))
			params:AddToFilter(Collection_Service:GetTagged("Visualiser"))
			params:AddToFilter(Collection_Service:GetTagged("AI"))
			params:AddToFilter(Collection_Service:GetTagged("Gun"))
			params:AddToFilter(Collection_Service:GetTagged("Goal"))

			for _, part in pairs(Collection_Service:GetTagged("Enemy Utilities")) do
				if part:HasTag("Grenade") then
					continue
				end

				params:AddToFilter(part)
			end

			local lookAtGrenade = CFrame.lookAt(position, grenadePosition)

			local ray = workspace:Raycast(
				position,
				lookAtGrenade.LookVector * self.information.pathfindinginformation.viewDistance,
				params
			)

			if not ray then
				return false
			end

			for _, tag: string in pairs(ray.Instance:GetTags()) do
				if tag == "Grenade" then
					return true
				end
			end

			return false
		end

		for _, grenade: Part in pairs(grenades) do
			if grenade:GetAttribute("Exploding") ~= true then
				continue
			end

			if
				HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, grenade.Position)
				> self.information.pathfindinginformation.combatsettings.grenadeAvoidanceRadius
			then
				continue
			end

			local rigHead: BasePart? | MeshPart? = self._important._rig:FindFirstChild("Head")

			if rigHead == nil then
				continue
			end

			local headSize = rigHead.Size
			local sizeX, sizeY, sizeZ = headSize.X / 2, headSize.Y / 2, headSize.Z / 2

			local foundGrenade = false

			for _ = 1, 10 do
				if foundGrenade == true then
					break
				end

				foundGrenade = RaycastPositionToGrenade(
					rigHead.Position
						+ Vector3.new(
							self.information.random:NextNumber(-1, 1) * sizeX,
							self.information.random:NextNumber(-1, 1) * sizeY,
							self.information.random:NextNumber(-1, 1) * sizeZ
						),
					grenade.Position
				)
			end

			if foundGrenade == false then
				continue
			end

			table.insert(nearbyGrenades, grenade)
		end

		if table.maxn(nearbyGrenades) == 0 then
			self.information.combatinformation._avoiding_grenade = false
			return false
		end

		return true
	end

	if fromFunction == "Move" and want == "Halt" then
		return Halt()
	end

	if fromFunction == "Move" and want == "Grenade" then
		return AvoidGrenade()
	end

	local warnMessage = "combatHandler._Main called from function: '"
		.. fromFunction
		.. "' wanting the action '"
		.. want
		.. "' not fufilled because the fromFunction-want combination is created."

	warn(warnMessage)

	return warnMessage
end

--[[
Used to avoid grenades.
]]
function class.schema.combatHandler._AvoidGrenade(self : AIPathfindingComponent) : boolean
	if self.information.combatinformation._avoiding_grenade == true then
		while self.information.combatinformation._avoiding_grenade == true do
			task.wait()
		end
	end
	self.information.combatinformation._avoiding_grenade = true

	local grenadeToBeAvoided

	local grenades = Collection_Service:GetTagged("Grenade")

	-- Check if there are any grenades
	if table.maxn(grenades) == 0 then
		return false
	end

	local nearbyGrenades = {}

	local function RaycastPositionToGrenade(position, grenadePosition)
		local params = RaycastParams.new()

		params.FilterType = Enum.RaycastFilterType.Exclude
		params:AddToFilter(Collection_Service:GetTagged("Bullets"))
		params:AddToFilter(Collection_Service:GetTagged("Visualiser"))
		params:AddToFilter(Collection_Service:GetTagged("AI"))
		params:AddToFilter(Collection_Service:GetTagged("Gun"))
		params:AddToFilter(Collection_Service:GetTagged("Goal"))

		for _, part in pairs(Collection_Service:GetTagged("Enemy Utilities")) do
			if part:HasTag("Grenade") then
				continue
			end

			params:AddToFilter(part)
		end

		local lookAtGrenade = CFrame.lookAt(position, grenadePosition)

		local ray = workspace:Raycast(
			position,
			lookAtGrenade.LookVector * self.information.pathfindinginformation.viewDistance,
			params
		)

		if not ray then
			return false
		end

		for _, tag: string in pairs(ray.Instance:GetTags()) do
			if tag == "Grenade" then
				return true
			end
		end

		return false
	end

	for _, grenade: Part in pairs(grenades) do
		if grenade:GetAttribute("Exploding") ~= true then
			continue
		end

		if
			HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, grenade.Position)
			> self.information.pathfindinginformation.combatsettings.grenadeAvoidanceRadius
		then
			continue
		end

		local rigHead: BasePart? | MeshPart? = self._important._rig:FindFirstChild("Head")

		if rigHead == nil then
			continue
		end

		local headSize = rigHead.Size
		local sizeX, sizeY, sizeZ = headSize.X / 2, headSize.Y / 2, headSize.Z / 2

		local foundGrenade = false

		for _ = 1, 10 do
			if foundGrenade == true then
				break
			end

			foundGrenade = RaycastPositionToGrenade(
				rigHead.Position
					+ Vector3.new(
						self.information.random:NextNumber(-1, 1) * sizeX,
						self.information.random:NextNumber(-1, 1) * sizeY,
						self.information.random:NextNumber(-1, 1) * sizeZ
					),
				grenade.Position
			)
		end

		if foundGrenade == false then
			continue
		end

		table.insert(nearbyGrenades, grenade)
	end

	if table.maxn(nearbyGrenades) == 0 then
		self.information.combatinformation._avoiding_grenade = false
		return false
	end

	table.sort(nearbyGrenades, function(a, b)
		local deltaA = HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, a.Position)
		local deltaB = HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, b.Position)

		if deltaA < deltaB then
			return true
		end

		return false
	end)

	grenadeToBeAvoided = nearbyGrenades[1]

	local humanoid = self._important._rig:FindFirstChildOfClass("Humanoid")

	if humanoid == nil then
		self.information.combatinformation._avoiding_grenade = false
		return false
	end

	local grenadeDirection =
		CFrame.lookAt(self._important._rig.PrimaryPart.Position, grenadeToBeAvoided.Position).LookVector

	local moveToPosition = Vector3.new(grenadeDirection.X, 0, grenadeDirection.Y)
		* -self.information.pathfindinginformation.combatsettings.grenadeAvoidanceRadius
		+ self._important._rig.PrimaryPart.Position


	local function CheckPositionValidity(position)
		local positionLookAt = CFrame.lookAt(self._important._rig.PrimaryPart.Position, position).LookVector
		local distance = HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, position)

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude

		params.FilterType = Enum.RaycastFilterType.Exclude
		params:AddToFilter(Collection_Service:GetTagged("Bullets"))
		params:AddToFilter(Collection_Service:GetTagged("Visualiser"))
		params:AddToFilter(Collection_Service:GetTagged("AI"))
		params:AddToFilter(Collection_Service:GetTagged("Gun"))
		params:AddToFilter(Collection_Service:GetTagged("Goal"))
		params:AddToFilter(Collection_Service:GetTagged("Enemy Utilities"))

		local ray = workspace:Raycast(self._important._rig.PrimaryPart.Position, positionLookAt * distance, params)

		if not ray then
			return position
		end

		local newPosition = self._important._rig.PrimaryPart.Position + positionLookAt * (ray.Distance - 0.1)

		return newPosition
	end

	local _, returned = HelperModule.Promises.ExceptionHandler(
		HelperModule.Promises.PromiseHandler(
			self._PathwaypointToVector3,
			true,
			self,
			CheckPositionValidity(moveToPosition)
		)
	)

	if returned.Resolved == false then
		self.information.combatinformation._avoiding_grenade = false
		return false
	end

	local waypoints = returned.Resolve

	local _, promiseReturn = HelperModule.Promises.ExceptionHandler(
		HelperModule.Promises.PromiseHandler(self._MoveToWaypoints, true, self, waypoints)
	)

	self.information.combatinformation._avoiding_grenade = false

	if promiseReturn.Resolved == false then
		return false
	end

	return true
end

--[[
Fills in AIPathfindingComponent.information._targetinformation.__positions with positional information about each target.
]]
function class.schema._GetTargetPositions(self: AIPathfindingComponent)
	local possibleTargets = {}

	local function GetInstanceFromPath(path: string): Model | Part?
		local target = workspace
		local splitPath = path:split(".")

		for index, part in pairs(splitPath) do
			if index == 1 then
				continue
			end

			local _, err = pcall(function()
				target = target[part]
			end)

			if err then
				if string.match(err, "is not a valid member of Folder") then
					continue
				end
				warn(err)
			end
		end

		if target == workspace then
			return nil
		end

		return target
	end

	local function InsertPositionsIntoTable(tagPositionTable)
		if tagPositionTable == nil then
			return
		end

		for path: string, position: Vector3 in tagPositionTable do
			local targetInstance = GetInstanceFromPath(path)

			if targetInstance == nil then
				continue
			end

			table.insert(possibleTargets, { _targetinstance = targetInstance, _position = position })
		end
	end

	for _, tag in pairs(self.information.targettags) do
		local tagTable = self.information._targetinformation._shared_table[tag]

		if tagTable == nil then
			continue
		end

		InsertPositionsIntoTable(tagTable["PositionalData"])
	end

	self.information._targetinformation._positions = possibleTargets

	self._EventWrapper(self, "_GetTargetPositions", nil, possibleTargets)
end

--[[
Creates a Path object to be used for pathfinding using PathfindingService.
]]
function class.schema.CreatePath(self: AIPathfindingComponent)
	local path: Path = Pathfinding_Service:CreatePath(self.information.pathfindinginformation.settings)

	self.information.pathfindinginformation._path = path

	self._EventWrapper(self, "CreatePath", nil, path)
end

--[[
Creates a Path if there isn't one, and then uses it to generate a set of waypoints to `position`.
]]
function class.schema._PathwaypointToVector3(
	self: AIPathfindingComponent,
	position: Vector3,
	startPositionOverride: Vector3?
)
	if self.information.pathfindinginformation._path == nil then
		self:CreatePath()
	end

	return Promises.new(function(resolve, reject)
		local path: Path = self.information.pathfindinginformation._path

		local positionUsedForComputeAsync = if startPositionOverride
			then startPositionOverride
			else Vector3.new(
				self._important._rig.PrimaryPart.CFrame.Position.X,
				self._important._rig.LeftFoot.CFrame.Position.Y,
				self._important._rig.PrimaryPart.CFrame.Position.Z
			)

		local success, err = pcall(function()
			path:ComputeAsync(positionUsedForComputeAsync, position)
		end)

		if not success then
			reject("Failed to create path: " .. err)
		end

		if path.Status == Enum.PathStatus.NoPath then
			reject("Path Status is Enum.PathStatus.NoPath.")
		end

		self._EventWrapper(self, "_PathwaypointToVector3", nil, path:GetWaypoints())

		resolve(path:GetWaypoints())
	end)
end

--[[
Returns points to move to.
]]
function class.schema._GetPathfindingWaypoints(self: AIPathfindingComponent)
	self:_GetTargetPositions()

	table.sort(
		self.information._targetinformation._positions,
		function(
			a: { _position: Vector3, __targetinstance: Model | Part },
			b: { _position: Vector3, __targetinstance: Model | Part }
		)
			local deltaA = HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, a._position)
			local deltaB = HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, b._position)

			if deltaA < deltaB then
				return true
			end

			return false
		end
	)

	local talbeSize = table.maxn(self.information._targetinformation._positions)
	local maxiumPossibleTargetIndex = math.clamp(talbeSize, 1, 5)

	local function GetChance(x)
		return 100 * math.pow(x, 4) - 8 * math.pow(x, 3) - math.pow(x, 2) - 5 * x
	end

	local chosenNumber = self.information.random:NextNumber(0, GetChance(maxiumPossibleTargetIndex))

	local foundInt

	for i = 1, maxiumPossibleTargetIndex do
		local iLevelChance = GetChance(i)

		if chosenNumber > iLevelChance then
			continue
		end

		foundInt = i
		break
	end

	local target: { _position: Vector3, _targetinstance: Part | Model } =
		self.information._targetinformation._positions[foundInt]

	if target == nil then
		return {}
	end

	self.information._targetinformation._target = target

	local _, returned = HelperModule.Promises.ExceptionHandler(
		HelperModule.Promises.PromiseHandler(self._PathwaypointToVector3, true, self, target._position)
	)

	if returned.Resolved == false then
		return {}
	end

	local waypoints = returned.Resolve

	self._EventWrapper(self, "_GetPathfindingWaypoints", nil, waypoints)

	return waypoints
end

--[[
Metafunction that contains subfunctions for custom actions
]]
function class.schema._CustomWaypointActions(self: AIPathfindingComponent, waypoint: PathWaypoint): boolean
	local functions = {}

	self._EventWrapper(self, "_CustomWaypointActions", "_CustomWaypointActions", waypoint.Label, waypoint)

	--[[
        Function used for the Teleporter label for Enum.WaypointAction.Custom. Returns true if teleported and false if not teleported
    ]]
	functions["Teleporter"] = function(): boolean -- Requires the passing of the waypoint position
		local position = waypoint.Position

		-- Creates an OverlapParams that includes the workspaceSkips.Parts.Teleporters folder, ignoring CanCollide
		local allowList = OverlapParams.new()
		allowList.FilterType = Enum.RaycastFilterType.Include
		allowList.FilterDescendantsInstances = { workspace.Skips.Parts.Teleporters }

		local cast = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(0.1, 0.1, 0.1), allowList) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

		if cast then -- Checks if a table is returned by the previous operation
			if table.maxn(cast) > 0 then -- Makes sure there are part(s) inside the table
				local teleporterEvent: BindableFunction = cast[1]:FindFirstChild("TP") -- Tries to find the BindableFunction nammed "TP" inside the first element of the table

				-- If found, invokes it with the rig and halts until a response is recieved. If the response is (int) 200 reponse, returns true. Otherwise, returns false
				if teleporterEvent then
					local response = false

					response = teleporterEvent:Invoke(self._important._rig) -- Invokes the BindableFunction

					while response == false do -- Waits for the response
						task.wait()
					end

					if response == 200 then -- Checks if the response is 200
						return true -- Returns true
					else
						print(response) -- If not, prints the response
					end
				else
					print("Teleporter function not found.")
				end
			else
				print("Cast table is empty.")
			end
		else
			print("No casted instance.")
		end

		return false
	end

	--[[
    Function used for the Moving Platform label for Enum.WaypointAction.Custom.
    Waits on the platform until the platform has stopped moving.
    Returns true if the rig waited and false otherwise
    ]]
	functions["Moving Platform"] = function(): boolean -- Requires the passing of the waypoint position
		local position = waypoint.Position

		-- Creates an OVerlapParams that includes the workspace.Skips.Parts.MovingPlatforms folder, ignoring CanCollide
		local allowList = OverlapParams.new()
		allowList.FilterType = Enum.RaycastFilterType.Include
		allowList.FilterDescendantsInstances = { workspace.Skips.Parts.MovingPlatforms }

		local cast = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(0.1, 0.1, 0.1), allowList) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

		if cast then -- Checks if a table is returned by the previous operation
			if table.maxn(cast) > 0 then -- Checks if the table has elements in it
				-- If there are elements in it, tries to find the "Active" used to wait while the platform is active, and the "Touch" BindableEvent to start the platform
				local moverPlatformSubPart = cast[1]

				if not moverPlatformSubPart then
					return false
				end

				local moverPlatform = moverPlatformSubPart.Parent.Parent
				local moverPlatformActive: BoolValue = moverPlatform:FindFirstChild("Mover"):FindFirstChild("Active")
				local moverStartEvent: BindableEvent =
					moverPlatform:FindFirstChild("Attached"):FindFirstChild("Start"):FindFirstChild("Touch")

				-- If both are found, the Touch BindableEvent is fired with the rig as an argument, and then the rig waits while the platform moves
				if moverPlatformActive and moverStartEvent then
					moverStartEvent:Fire() -- Fires the BindableEvent

					while moverPlatformActive.Value == false do -- Waits until the platform activates
						task.wait()
					end

					self._important._script:SetAttribute("OnMovingPlatform", true) -- Publicses that the rig is on a moving platform

					while moverPlatformActive.Value == true do -- Waits until the platform deactivates
						local startPosition: Vector3 =
							moverPlatform:FindFirstChild("Attached"):FindFirstChild("Start").Position

						self._important._rig.Humanoid:MoveTo(startPosition)
						task.wait()
					end

					self._important._script:SetAttribute("OnMovingPlatform", false) -- Publicses that the rig is not on a moving platform

					return true -- Returns true when the platform deactivates
				else -- If the "Active" BoolValue and/or "Touch" BindableEvent aren't found, warns useful information for debugging
					warn(
						"Found active boolean? ",
						moverPlatformActive,
						" Found event? ",
						moverStartEvent,
						" Instance: ",
						cast[1]:GetFullName(),
						" Parent's parent: ",
						cast[1].Parent.Parent.Name
					)
				end
			else
				print("Cast table is empty.")
			end
		else
			print("No casted instance.")
		end
		return false
	end

	return functions[waypoint.Label]()
end

--[[
Moves the rig through all the waypoints provided in the waypoints table.
]]
function class.schema._MoveToWaypoints(self: AIPathfindingComponent, waypoints: {PathWaypoint})
	return Promises.new(function(resolve, reject, onCancel)
		local cancelPathfinding = false

		local fireStartedMoving = false

		onCancel(function()
			cancelPathfinding = true

			if fireStartedMoving == true then
				self._EventWrapper(self, "_MoveToWaypoints", "StoppedMoving")
			end
		end)

		if not waypoints then
			reject("Waypoint table is nil.")
		end

		if table.maxn(waypoints) == 0 then
			reject("There are no waypoints in the waypoint table.")
		end

		local humanoid: Humanoid = self._important._rig:FindFirstChildOfClass("Humanoid")

		if not humanoid then
			reject("Model has no Humanoid to pathfind to.")
		end

		if self.information.visualisationinformation.visualisePath == true then
			self:_PathVisualiser(waypoints)
		end

		self._EventWrapper(self, "_MoveToWaypoints", "StartedMoving", waypoints)
		fireStartedMoving = true

		local avoidedGrenade = false
		local completedCustomAction = false
		local _halted
		local avoidingGrenade = self.information.combatinformation._avoiding_grenade

		for _, waypoint: PathWaypoint in pairs(waypoints) do
			if cancelPathfinding == true then
				break
			end

			if self.information._stop_pathfinding == true then
				break
			end

			if waypoint.Action == Enum.PathWaypointAction.Custom then
				completedCustomAction = self:_CustomWaypointActions(waypoint)
			end

			if completedCustomAction == true then
				continue
			end

			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end

			humanoid:MoveTo(waypoint.Position)

			humanoid.MoveToFinished:Wait()

			_halted = self.combatHandler._Main(self, "Move", "Halt")

			if avoidingGrenade == false then
				avoidedGrenade = self.combatHandler._Main(self, "Move", "Grenade")
			end

			if avoidedGrenade == true then
				break
			end
		end

		if avoidedGrenade == true then
			self._EventWrapper(self, "_MoveToWaypoints", "StoppedMoving")

			self.combatHandler._AvoidGrenade(self)

			HelperModule.Promises.ExceptionHandler(
				HelperModule.Promises.PromiseHandler(
					self._PathwaypointToVector3,
					false,
					self,
					waypoints[table.maxn(waypoints)],
					self._important._rig.PrimaryPart.Position
				)
			)
		else
			self._EventWrapper(self, "_MoveToWaypoints", "StoppedMoving")
		end

		resolve("Finished pathfinding")
	end)
end

--[[
Starts the search cycle of the main pathfinding cycle. If the AI doesn't have sight (from the head) of the target at the end of pathfinding,
it will move in random directions to get to the target.
]]
function class.schema._SearchCycle(self: AIPathfindingComponent, initialWaypoints: {})
	local target: Model | Part = self.information._targetinformation._target._targetinstance
	HelperModule.Promises.ExceptionHandler(
		HelperModule.Promises.PromiseHandler(self._MoveToWaypoints, true, self, initialWaypoints)
	)

	local function CanRigSeeTarget()
		local rigHead: BasePart? | MeshPart? = self._important._rig:FindFirstChild("Head")

		if rigHead == nil then
			return false
		end

		local headSize = rigHead.Size
		local sizeX, sizeY, sizeZ = headSize.X / 2, headSize.Y / 2, headSize.Z / 2

		local foundGrenade = false

		local function RaycastPositionToTarget(position)
			local params = RaycastParams.new()

			params.FilterType = Enum.RaycastFilterType.Exclude
			params:AddToFilter(Collection_Service:GetTagged("Bullets"))
			params:AddToFilter(Collection_Service:GetTagged("Visualiser"))
			params:AddToFilter(Collection_Service:GetTagged("Enemy Utilities"))
			params:AddToFilter(Collection_Service:GetTagged("AI"))
			params:AddToFilter(Collection_Service:GetTagged("Gun"))

			local targetPosition

			if target:IsA("Model") then
				local primaryPart = target.PrimaryPart

				if primaryPart == nil then
					return true
				end

				targetPosition = primaryPart.Position
			elseif target:IsA("Part") then
				targetPosition = target.Position
			else
				warn(
					"Target is not a model/part; therefore it is impossible to find its position. Target class: "
						.. target.ClassName
				)
				return true
			end

			local lookAtTarget = CFrame.lookAt(position, targetPosition)

			local ray = workspace:Raycast(
				position,
				lookAtTarget.LookVector * self.information.pathfindinginformation.viewDistance,
				params
			)

			if not ray then
				return false
			end

			if ray.Instance ~= target then
				--[[
                Check if what the rig sees is an enemy or not
                ]]
				for _, tag: string in pairs(ray.Instance:GetTags()) do
					if table.find(self.information.targettags, tag) then
						return true
					end
				end

				--[[
                If that part is a part and has a model as its parent, check the parent's tags too.
                ]]
				if ray.Instance:FindFirstAncestorOfClass("Model") then
					for _, tag: string in pairs(ray.Instance:FindFirstAncestorOfClass("Model"):GetTags()) do
						if table.find(self.information.targettags, tag) then
							return true
						end
					end
				end

				if ray.Instance:IsDescendantOf(target) == false then
					return false
				end
			end

			return true
		end

		for _ = 1, 10 do
			if foundGrenade == true then
				break
			end

			foundGrenade = RaycastPositionToTarget(
				rigHead.Position
					+ Vector3.new(
						self.information.random:NextNumber(-1, 1) * sizeX,
						self.information.random:NextNumber(-1, 1) * sizeY,
						self.information.random:NextNumber(-1, 1) * sizeZ
					)
			)
		end

		if foundGrenade == false then
			return false
		end

		return true
	end

	if CanRigSeeTarget() == true then
		return
	end

	--[[
    The function that selects where the rig should move to to continue to search for the target
    ]]
	local function SearchAlgorithm(): Vector3
		--[[
        Function to choose the point where the rig should go
        ]]
		local function ChoosePoint()
			return self._important._rig.PrimaryPart.Position
				+ Vector3.new(
					self.information.random:NextInteger(-10, 10),
					0,
					self.information.random:NextInteger(-10, 10)
				)
		end

		--[[
        Function to check if the space where the point was chosen is able to be reached
        ]]
		local function CheckIfSpaceIsAvailable(position: Vector3)
			local ignored_tags = {
				"AI",
				"Bullets",
				"Grenade",
				"Goal",
				"Visualiser",
				"Gun",
				"Enemy Utilities",
			}

			local overlapParameters = OverlapParams.new()
			overlapParameters.FilterType = Enum.RaycastFilterType.Exclude

			for _, tag in pairs(ignored_tags) do
				overlapParameters:AddToFilter(Collection_Service:GetTagged(tag))
			end

			overlapParameters:AddToFilter(self._important._rig)

			local isAreaOpen =
				workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(2.5, 2.5, 2.5), overlapParameters)

			if table.maxn(isAreaOpen) > 0 then
				return false
			end

			local head: BasePart = self._important._rig:FindFirstChild("Head")

			if head == nil then
				return true
			end

			local raycastParameters = RaycastParams.new()
			raycastParameters.FilterType = Enum.RaycastFilterType.Exclude

			for _, tag in pairs(ignored_tags) do
				raycastParameters:AddToFilter(Collection_Service:GetTagged(tag))
			end
			
			raycastParameters:AddToFilter(self._important._rig)

			local distanceBetweenPrimaryPartAndHead =
				HelperModule.NumberManipulation.Delta(head.Position, self._important._rig.PrimaryPart.Position)

			local lookDirection = CFrame.lookAt(
				head.Position,
				position + Vector3.new(0, distanceBetweenPrimaryPartAndHead, 0)
			).LookVector * HelperModule.NumberManipulation.Delta(self._important._rig.PrimaryPart.Position, position)

			local isThereAWall = workspace:Raycast(head.Position, lookDirection, raycastParameters)

			if isThereAWall then
				if game:GetService("RunService"):IsStudio() == true then
					print("Wall in way. Hit: " .. isThereAWall.Instance:GetFullName())
				end

				return false
			end

			return true
		end

		local newPosition = ChoosePoint()

		if CheckIfSpaceIsAvailable(newPosition) == false then
			while CheckIfSpaceIsAvailable(newPosition) == false do
				newPosition = ChoosePoint()
				task.wait()
			end
		end

		return newPosition
	end

	local _returnFunction
	local promiseReturn

	local tries = 0

	self._EventWrapper(self, "_SearchCycle", "SearchBegan")

	while task.wait() do
		if CanRigSeeTarget() == true then
			self._EventWrapper(self, "_SearchCycle", "SearchFinished", "Found target")
			return
		end

		if tries >= self.information.pathfindinginformation.searchTries then
			self._EventWrapper(self, "_SearchCycle", "SearchFinished", "Ran out of tries")
			return
		end

		tries += 1

		_returnFunction, promiseReturn = HelperModule.Promises.ExceptionHandler(
			HelperModule.Promises.PromiseHandler(self._PathwaypointToVector3, true, self, SearchAlgorithm()),
			false
		)

		if promiseReturn.Resolved == false then
			break
		end

		HelperModule.Promises.ExceptionHandler(
			HelperModule.Promises.PromiseHandler(self._MoveToWaypoints, true, self, promiseReturn.Resolve)
		)
	end
end

--[[
Starts the cycle of pathfinding for the AI.
]]
function class.schema.StartPathfindingCycle(self: AIPathfindingComponent)
	self._EventWrapper(self, "StartPathfindingCycle", nil, true)

	local function Move(waypoints: {})
		self.combatHandler._Main(self, "Move", "Grenade")
		self:_SearchCycle(waypoints)
	end

	local function GetWaypoints()
		local waypoints = self:_GetPathfindingWaypoints()

		if table.maxn(waypoints) == 0 then
			-- warn("There are no waypoints in the waypoint table.")
			task.wait(2)
			return
		end

		Move(waypoints)
	end

	while self.information._stop_pathfinding == false do
		GetWaypoints()
		task.wait()
	end

	self._EventWrapper(self, "StartPathfindingCycle", nil, false)
end

type signals = typeof(class.schema.SetUpSignals)
type information = typeof(class.schema.SetUpInformation)
export type AIPathfindingComponent = typeof(class.interface.new(table.unpack(...)))

return class
