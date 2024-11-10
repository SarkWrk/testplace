-- Class
local class = {}

-- Services
local SHARED_TABLE_REGISTRY = game:GetService("SharedTableRegistry")
local REPLICATED_STORAGE = game:GetService("ReplicatedStorage")
local PATHFINDING_SERVICE = game:GetService("PathfindingService")
local COLLECTION_SERVICE = game:GetService("CollectionService")

-- Dependencies
local _TYPES = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("Types"))
local HELPER = require(REPLICATED_STORAGE:WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local FAST_SIGNAL = require(REPLICATED_STORAGE:WaitForChild("FastSignal"):WaitForChild("FastSignal"))
local PROMISES = require(game:GetService("ReplicatedStorage"):WaitForChild("roblox-lua-promise"):WaitForChild("Promise"))

class.interface = {}
class.schema = {}
class.metatable = {__index = class.schema}

--[[
Use this function to create a new AIPathfindingComponent.
]]
class.interface.new = function(rig : Model) : AIPathfindingComponent 
    local self = setmetatable({}, class.metatable)
    
    self.___important = {
        ___rig = rig,
        ___state_manager_script = Instance.new("Script"),
    }
    self.information = self:SetUpInformation()
    self.signals = self:SetUpSignals()

    return self
end

--[[
Sets up the signals used in this class.
]]
function class.schema:SetUpSignals()
    --[[
    Contain the signals that will be fired by this component.

    Note: Changed is a global variable that will fire whenever something notable (except when Destroying fires) changes.
    ]]
    local signals = {}

    signals.___Changed = FAST_SIGNAL.new()
    signals.___Destroying = FAST_SIGNAL.new()
    signals.___StartedMoving = FAST_SIGNAL.new()
    signals.___StoppedMoving = FAST_SIGNAL.new()
    signals.___CustomWaypointActions = FAST_SIGNAL.new()

    return signals
end

--[[
Sets up underlying information required for the class to run. Values with the prefix '___' should not be touched.
]]
function class.schema:SetUpInformation()
    --[[
    Contains various variables and subtables used for the tasks that this component does.
    ]]
    local information = {
        -- Variables that shouldn't be modified
        ___stop_pathfinding = false,

        -- Modifiable variables
        RANDOM = Random.new()
    }

    --[[
    Contains the potential tags that the component will take into consideration when pathfinding.
    ]]
    information.targettags = {
        "Goal"
    }

    --[[
    DO NOT TOUCH!

    Contains information about the current target, positions of every possible target, and the SharedTable used to find the positions of targets.
    ]]
    information.___targetinformation = {
        ___positions = {},
        ___target = nil,
        ___shared_table = SHARED_TABLE_REGISTRY:GetSharedTable("PositionsTrackerTable")}

    --[[
    Contains information used when pathfinding.
    ]]
    information.pathfindinginformation = {
        -- Variables that shouldn't be modified
        ___path = nil

        -- Modifiable variables
    }

    --[[
    Contains information used when creating a Path using PathfindingService:CreatePath().
    ]]
    information.pathfindinginformation.settings = {
        --Modifiable variables
        AGENT_RADIUS = 2,
        AGENT_HEIGHT = 5,
        WAYPOINT_SPACING = 1,
        COSTS = {}
    }

    --[[
    Contains information used during pathfinding on what to do in combat situations.
    ]]
    information.pathfindinginformation.combatsettings = {
        -- Variables that shouldn't be modified

        -- Modifiable varibles
        SHOULD_STOP_ON_ENEMY_SIGHT = true,
        MOVESPEED_REDUCTION_ON_ENEMY_SIGHT = 8,
        GRENADE_AVOIDANCE_RADIUS = 40,
    }

    --[[
    Contains information used when visualising things from this component.
    ]]
    information.visualisationinformation = {
        -- Variables that shouldn't be modified
        ___visualisation_folder = nil,
        ___visualisation_folder_name = self.___important.___rig:GetFullName(),

        -- Modifiable variables
        VISUALISE_PATH = true,
        VISUALISATION_SPACING = 1,
        NORMAL_NODE_SIZE = 1,
        JUMP_NODE_SIZE_MULTIPLIER = 2,
        CUSTOM_NODE_SIZE_MULTIPLIER = 4,
    }

    --[[
    Contains used information about AICombatComponent.
    ]]
    information.combatinformation = {
        -- Variables that shouldn't be modified
        ___spotted_enemy = false

        -- Modifiable variables
    }

    return information
end

--[[
This function cleans up the component to be able to be GC'd. Any connections to ___Destroying and ___Changed are given 2 seconds before being disconnected.

When called will:
1. Fire the ___Destroying event.
2. Set class.information.___stop_pathfinding to true.
3. Destroy, (if applicable) class.information.visualisationinformation.___visualisation_folder and class.information.pathfindinginformation.___path,
4. Disconnect all signals baring ___Changed and ___Destroying.
5. Wait 2 seconds since class.signals.____Destroying was called.
6. Remove all references to class.information and class.___important.
7. Disconnect ___Changed and ___Destroying.
8. Remove all references to class.signals.
]]
function class.schema.Destroy(self : AIPathfindingComponent)
    print(self)
    self.signals.___Destroying:Fire()

    local destroyStartTime = tick()

    self.information.___stop_pathfinding = true

    local function DestroyObjects()
        if self.information.visualisationinformation.___visualisation_folder ~= nil then
            self.information.visualisationinformation.___visualisation_folder:Destroy()
        end
    
        if self.information.pathfindinginformation.___path then
            self.information.pathfindinginformation.___path:DEstroy()
        end
    
        self.information.RANDOM = nil
    end

    local function RemoveSignals()
        for signal_name, signal in pairs(self.signals) do
            if signal_name == "___Destroying" then
                continue
            end
    
            if signal_name == "___Changed" then
                continue
            end
    
            signal:Destroy()
        end
    end

    local function RemoveReferences()
        self.information = nil
        self.___important = nil
    end

    DestroyObjects()

    RemoveSignals()

    while tick()-destroyStartTime < 2 do
        task.wait()
    end

    RemoveReferences()

    self.signals.___Changed:Destroy()
    self.signals.___Destroying:Destroy()

    self.signals = nil
    
    self = nil
end

--[[
Function used to visualise the path the rig takes to get to a goal
]]
function class.schema.PathVisualiser(self: AIPathfindingComponent, waypoints: {})
	-- Tries to find if a folder to store all the paths has already been made. If it hasn't, then it creates the folder
	local foundFolder = self.information.visualisationinformation.___visualisation_folder
	if foundFolder then
		foundFolder:ClearAllChildren() -- Clears all previous nodes in the folder
	else
		-- Creates a new folder with the name "PathVisualiser" and parents it to the workspace
		foundFolder = Instance.new("Folder")
		foundFolder.Name = self.information.visualisationinformation.___visualisation_folder_name
		foundFolder.Parent = workspace
		self.information.visualisationinformation.___visualisation_folder = foundFolder
	end

	-- Checks if the visualisation node spacing is less than the agent waypoint spacing, and if so sets the visualisation node spacing to the agent's
	if self.information.visualisationinformation.VISUALISATION_SPACING < self.information.pathfindinginformation.settings.WAYPOINT_SPACING then
		print(
			"Setting visualisationinformation.VISUALISATION_SPACING to "
				.. self.information.pathfindinginformation.settings.WAYPOINT_SPACING
				.. " (Previously: "
				.. self.information.visualisationinformation.VISUALISATION_SPACING
				.. ")"
		)
		self.information.visualisationinformation.VISUALISATION_SPACING = self.information.pathfindinginformation.settings.WAYPOINT_SPACING
	end

	local spacer = self.information.visualisationinformation.VISUALISATION_SPACING
		/ self.information.pathfindinginformation.settings.WAYPOINT_SPACING --[[ Calculates
	how often to create a visualised node]]
	local counter = 0 -- Keeps track of when to place a node

	-- Loops through each waypoint and creates a node based off the spacer value
	for i, v: PathWaypoint in pairs(waypoints) do
		-- Creates the node part, determines its colour based off the action, and determines if the node should be shown (otherwise it's skipped)
		local waypoint = Instance.new("Part")
		counter += 1 -- Increments the counter

		-- Jump actions are never skipped, have visualisationinformation.JUMP_NODE_SIZE_MULTIPLIER the size of a normal node, and are given a GREEN colour
		if v.Action == Enum.PathWaypointAction.Jump then
			counter = 0 -- Resets the counter
			waypoint.Color = Color3.new(0.278431, 0.674510, 0.082353) -- Sets the colour
			waypoint.Size = Vector3.new(
				self.information.visualisationinformation.NORMAL_NODE_SIZE * self.information.visualisationinformation.JUMP_NODE_SIZE_MULTIPLIER,
				self.information.visualisationinformation.NORMAL_NODE_SIZE * self.information.visualisationinformation.JUMP_NODE_SIZE_MULTIPLIER,
				self.information.visualisationinformation.NORMAL_NODE_SIZE * self.information.visualisationinformation.JUMP_NODE_SIZE_MULTIPLIER
			)

			-- Custom actions are never skipped, have visualisationinformation.CUSTOM_NODE_SIZE_MULTIPLIER the size of a normal node, and are given a PINK-ISH-WHITE colour
		elseif v.Action == Enum.PathWaypointAction.Custom then
			counter = 0 -- Resets the counter
			waypoint.Color = Color3.new(1.000000, 0.537255, 1.000000) -- Sets the colour
			waypoint.Size = Vector3.new(
				self.information.visualisationinformation.NORMAL_NODE_SIZE * self.information.visualisationinformation.CUSTOM_NODE_SIZE_MULTIPLIER,
				self.information.visualisationinformation.NORMAL_NODE_SIZE * self.information.visualisationinformation.CUSTOM_NODE_SIZE_MULTIPLIER,
				self.information.visualisationinformation.NORMAL_NODE_SIZE * self.information.visualisationinformation.CUSTOM_NODE_SIZE_MULTIPLIER
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
		waypoint.Parent = foundFolder -- Parents the node to the folder
	end
end

--[[
Contains various functions that can be used in combat situations.
The functions require a pre-set 'fromFunction-want' pairing to work.
This function always returns void.
Warns if a specific 'fromFunction-want' pairing has not been created.

fromFunction : The function calling ___CombatHandler.

want : The function that should be ran by ___CombatHandler.
]]
function class.schema.___CombatHandler(self : AIPathfindingComponent, fromFunction : "Move"|"CombatHandler", want : "Halt"|"Grenade")
    local function Halt()
        if self.information.combatinformation.___spotted_enemy == false then
            return
        end

        local reducedSpeed = false

        if self.information.pathfindinginformation.combatsettings.SHOULD_STOP_ON_ENEMY_SIGHT == false then
            reducedSpeed = true
            self.___important.___state_manager_script:SetAttribute("Walkspeed", self.___important.___state_manager_script:GetAttribute("Walkspeed") - self.information.pathfindinginformation.combatsettings.MOVESPEED_REDUCTION_ON_ENEMY_SIGHT)
        end

        while self.information.combatinformation.___spotted_enemy == true do
            self:___CombatHandler("CombatHandler", "Grenade")
            task.wait()
        end

        if reducedSpeed == true then
            self.___important.___state_manager_script:SetAttribute("Walkspeed", self.___important.___state_manager_script:GetAttribute("Walkspeed") + self.information.pathfindinginformation.combatsettings.MOVESPEED_REDUCTION_ON_ENEMY_SIGHT)
        end
    end

    --[[
    Checks if there're any greandes nearby, and if so tries to avoid them.
    ]]
    local function AvoidGrenade(override : Part?)
        local grenadeToBeAvoided = override

        if grenadeToBeAvoided == nil then
            local grenades = COLLECTION_SERVICE:GetTagged("Grenade")

            -- Check if there are any grenades
            if table.maxn(grenades) == 0 then
                return
            end

            local nearbyGrenades = {}

            for _, grenade : Part in pairs(grenades) do
                if grenade:GetAttribute("Exploding") ~= true then
                    continue
                end

                if HELPER.NumberManipulation.Delta(self.___important.___rig.PrimaryPart.Position, grenade.Position) > self.information.pathfindinginformation.combatsettings.GRENADE_AVOIDANCE_RADIUS then
                    continue
                end

                local rigHead : BasePart?|MeshPart? = self.___important.___rig:FindFirstChild("Head")

                if rigHead == nil then
                    continue
                end

                local headSize = rigHead.Size
                local sizeX, sizeY, sizeZ = headSize.X/2, headSize.Y/2, headSize.Z/2

                local foundGrenade = false

                local function RaycastPositionToGrenade(position)
                    local ray = workspace:Raycast(position, grenade.Position)

                    if not ray then
                        return false
                    end

                    if ray.Instance ~= grenade then
                        if ray.Instance:IsDescendantOf(grenade) == false then
                            return false
                        end
                    end

                    return true
                end

                for _ = 1, 10 do
                    if foundGrenade == true then
                        break
                    end

                    foundGrenade = RaycastPositionToGrenade(
                        rigHead.Position +
                        Vector3.new(
                        self.information.RANDOM:NextNumber(-1, 1) * sizeX,
                        self.information.RANDOM:NextNumber(-1, 1) * sizeY,
                        self.information.RANDOM:NextNumber(-1, 1) * sizeZ
                    ))
                end

                if foundGrenade == false then
                    continue
                end

                table.insert(nearbyGrenades, grenade)
            end

            if table.maxn(nearbyGrenades) == 0 then
                return
            end

            table.sort(nearbyGrenades, function(a, b)
                local deltaA = HELPER.NumberManipulation.Delta(self.___important.___rig.PrimaryPart.Position, a.Position)
                local deltaB = HELPER.NumberManipulation.Delta(self.___important.___rig.PrimaryPart.Position, b.Position)

                if deltaA < deltaB then
                    return true
                end
                
                return false
            end)

            grenadeToBeAvoided = nearbyGrenades[1]
        end

        local humanoid = self.___important.___rig:FindFirstChildOfClass("Humanoid")

        if humanoid == nil then
            return
        end

        local grenadeDirection = CFrame.lookAt(self.___important.___rig.PrimaryPart.Position, grenadeToBeAvoided.Position).LookVector

        local moveToPosition = Vector3.new(grenadeDirection.X, 0, grenadeDirection.Y) * -self.information.pathfindinginformation.combatsettings.GRENADE_AVOIDANCE_RADIUS

        local _, returned = HELPER.Promises.ExceptionHandler(HELPER.Promises.PromiseHandler(self.PathwaypointToVector3, true, self, moveToPosition), true)

        if returned.Resolved == false then
            return
        end

        local waypoints = returned.Resolve

        HELPER.Promises.ExceptionHandler(HELPER.Promises.PromiseHandler(self.MoveToWayPoints, true, self, waypoints))

        local grenadeDestroyed = false

        local destroyConnection = grenadeToBeAvoided.Destroying:Connect(function()
            grenadeDestroyed = true
        end)

        while grenadeDestroyed == false do
            if HELPER.NumberManipulation.Delta(self.___important.___rig.PrimaryPart.Position, grenadeToBeAvoided.Position) > self.information.pathfindinginformation.combatsettings.GRENADE_AVOIDANCE_RADIUS then
                continue
            end

            destroyConnection:Disconnect()
            grenadeDestroyed = true

            AvoidGrenade(grenadeToBeAvoided)
        end
    end

    if fromFunction == "Move" and want == "Halt" then
        Halt()
        return
    end

    if fromFunction == "Move" and want == "Grenade" then
        AvoidGrenade()
        return
    end

    if fromFunction == "CombatHandler" and want == "Grenade" then
        AvoidGrenade()
        return
    end

    warn("___CombatHandler called from function: '" .. fromFunction .. "' wanting the action '" .. want .. "' not fufilled because the fromFunction-want combination is created.")
end

--[[
Fills in AIPathfindingComponent.information.___targetinformation.____positions with positional information about each target.
]]
function class.schema.___GetTargetPositions(self : AIPathfindingComponent)
    local possibleTargets = {}

    local function GetInstanceFromPath(path : string) : Model|Part?
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

        for path : string, position : Vector3 in tagPositionTable do
            local targetInstance = GetInstanceFromPath(path)

            if targetInstance == nil then
                continue
            end

            table.insert(possibleTargets, {___targetinstance = targetInstance, ___position = position})
        end
    end

    for _, tag in pairs(self.information.targettags) do
        local tagTable = self.information.___targetinformation.___shared_table[tag]

        if tagTable == nil then
            continue
        end

        InsertPositionsIntoTable(tagTable["PositionalData"])
    end

    self.information.___targetinformation.___positions = possibleTargets

    self.signals.___Changed:Fire("___GetTargetPositions", possibleTargets)
end

--[[
Creates a Path object to be used for pathfinding using PathfindingService.
]]
function class.schema.CreatePath(self : AIPathfindingComponent)
    local path : Path = PATHFINDING_SERVICE:CreatePath({
        AgentRadius = self.information.pathfindinginformation.settings.AGENT_RADIUS,
        AgentHeight = self.information.pathfindinginformation.settings.AGENT_HEIGHT,
        WaypointSpacing = self.information.pathfindinginformation.settings.WAYPOINT_SPACING,
        Costs = self.information.pathfindinginformation.settings.COSTS})

    self.information.pathfindinginformation.___path = path

    self.signals.___Changed:Fire("CreatePath", path)
end

--[[
Creates a path to a point using the created path
]]
function class.schema.PathwaypointToVector3(self : AIPathfindingComponent, position : Vector3)
    if self.information.pathfindinginformation.___path == nil then
        self:CreatePath()
    end

    return PROMISES.new(function(resolve, reject)
        local path : Path = self.information.pathfindinginformation.___path

        local positionUsedForComputeAsync = Vector3.new(self.___important.___rig.PrimaryPart.Position.X, self.___important.___rig.LeftFoot.Position.Y, self.___important.___rig.PrimaryPart.Position.Z)

        local success, err = pcall(function()
            path:ComputeAsync(positionUsedForComputeAsync, position)
        end)

        if not success then
            reject("Failed to create path: " .. err)
        end

        if path.Status ~= Enum.PathStatus.Success then
            reject("Path is not Enum.PathStatus.Success. Status: " .. path.Status.Name)
        end

        resolve(path:GetWaypoints())
    end)
end

--[[
Returns points to move to.
]]
function class.schema.___GetPathfindingWaypoints(self : AIPathfindingComponent)
    self:___GetTargetPositions()

    table.sort(self.information.___targetinformation.___positions, function(a : {___position : Vector3, ____targetinstance : Model|Part}, b  : {___position : Vector3, ____targetinstance : Model|Part})
        local deltaA = HELPER.NumberManipulation.Delta(self.___important.___rig.PrimaryPart.Position, a.___position)
        local deltaB = HELPER.NumberManipulation.Delta(self.___important.___rig.PrimaryPart.Position, b.___position)

        if deltaA < deltaB then
            return true
        end

        return false
    end)

    local talbeSize = table.maxn(self.information.___targetinformation.___positions)
    local maxiumPossibleTargetIndex = math.clamp(talbeSize, 1, 5)

    local function GetChance(x)
        return 100*math.pow(x, 4) - 8*math.pow(x, 3) - math.pow(x, 2) - 5*x
    end

    local chosenNumber = self.information.RANDOM:NextNumber(0, GetChance(maxiumPossibleTargetIndex))

    local foundInt

    for i = 1, maxiumPossibleTargetIndex do
        local iLevelChance = GetChance(i)

        if chosenNumber > iLevelChance then
            continue
        end

        foundInt = i
        break
    end

    local target : {___position : Vector3, ___targetinstance : Part|Model} = self.information.___targetinformation.___positions[foundInt]

    if target == nil then
        return {}
    end

    self.information.___targetinformation.___target = target

    local _, returned = HELPER.Promises.ExceptionHandler(HELPER.Promises.PromiseHandler(self.PathwaypointToVector3, true, self, target.___position))

    if returned.Resolved == false then
        return {}
    end

    local waypoints = returned.Resolve

    self.signals.___Changed:Fire("___GetPathfindingWaypoints", waypoints)

    return waypoints
end

--[[
Metafunction that contains subfunctions for custom actions
]]
function class.schema.___CustomWaypointActions(self : AIPathfindingComponent, waypoint : PathWaypoint) : boolean
    local functions = {}

    self.signals.___CustomWaypointActions:Fire(waypoint.Label, waypoint)

    --[[
        Function used for the Teleporter label for Enum.WaypointAction.Custom. Returns true if teleported and false if not teleported
    ]]
    function functions.Telporter(): boolean -- Requires the passing of the waypoint position
        local position = waypoint.Position

        -- Creates a new small part at the position of the waypoint
        local makeshiftPart = Instance.new("Part")
        makeshiftPart.Size = Vector3.new(0.1, 0.1, 0.1)
        makeshiftPart.Position = position

        -- Creates an OverlapParams that includes the workspaceSkips.Parts.Teleporters folder, ignoring CanCollide
        local allowList = OverlapParams.new()
        allowList.FilterType = Enum.RaycastFilterType.Include
        allowList.FilterDescendantsInstances = { workspace.Skips.Parts.Teleporters }

        local cast = game.Workspace:GetPartsInPart(makeshiftPart, allowList) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

        makeshiftPart:Destroy()

        if cast then -- Checks if a table is returned by the previous operation
            if table.maxn(cast) > 0 then -- Makes sure there are part(s) inside the table
                local teleporterEvent: BindableFunction = cast[1]:FindFirstChild("TP") -- Tries to find the BindableFunction nammed "TP" inside the first element of the table

                -- If found, invokes it with the rig and halts until a response is recieved. If the response is (int) 200 reponse, returns true. Otherwise, returns false
                if teleporterEvent then
                    local response = false

                    response = teleporterEvent:Invoke(self.ImportantInformation.___rig) -- Invokes the BindableFunction

                    while response == false do -- Waits for the response
                        if self.Infrmation.Died == true then
                            break
                        end

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
    function functions.MovingPlatform(): boolean -- Requires the passing of the waypoint position
        local position = waypoint.Position

        -- Creates a small part at the position of the waypoint
        local makeshiftPart = Instance.new("Part")
        makeshiftPart.Size = Vector3.new(0.1, 0.1, 0.1)
        makeshiftPart.Position = position

        -- Creates an OVerlapParams that includes the workspace.Skips.Parts.MovingPlatforms folder, ignoring CanCollide
        local allowList = OverlapParams.new()
        allowList.FilterType = Enum.RaycastFilterType.Include
        allowList.FilterDescendantsInstances = { workspace.Skips.Parts.MovingPlatforms }

        local cast = game.Workspace:GetPartsInPart(makeshiftPart, allowList) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

        makeshiftPart:Destroy()

        if cast then -- Checks if a table is returned by the previous operation
            if table.maxn(cast) > 0 then -- Checks if the table has elements in it
                -- If there are elements in it, tries to find the "Active" used to wait while the platform is active, and the "Touch" BindableEvent to start the platform
                local moverPlatform = cast[1].Parent.Parent
                local moverPlatformActive: BoolValue =
                    moverPlatform:FindFirstChild("Mover"):FindFirstChild("Active")
                local moverStartEvent: BindableEvent =
                    moverPlatform:FindFirstChild("Attached"):FindFirstChild("Start"):FindFirstChild("Touch")

                -- If both are found, the Touch BindableEvent is fired with the rig as an argument, and then the rig waits while the platform moves
                if moverPlatformActive and moverStartEvent then
                    moverStartEvent:Fire() -- Fires the BindableEvent

                    while moverPlatformActive.Value == false do -- Waits until the platform activates
                        if self.Information.Died == true then
                            return false
                        end

                        task.wait()
                    end

                    self.ImportantInformation.script:SetAttribute("OnMovingPlatform", true) -- Publicses that the rig is on a moving platform

                    while moverPlatformActive.Value == true do -- Waits until the platform deactivates
                        if self.Information.Died == true then
                            return false
                        end
                        
                        local startPosition: Vector3 = moverPlatform:FindFirstChild("Attached"):FindFirstChild("Start").Position

                        self.ImportantInformation.humanoid:MoveTo(startPosition)
                        task.wait()
                    end

                    self.ImportantInformation.script:SetAttribute("OnMovingPlatform", false) -- Publicses that the rig is not on a moving platform

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
function class.schema.MoveToWayPoints(self : AIPathfindingComponent, waypoints : {})
    return PROMISES.new(function(resolve, reject, onCancel)
        local cancelPathfinding = false

        local fireStartedMoving = false

        onCancel(function()
            cancelPathfinding = true

            if fireStartedMoving == true then
                self.signals.___StoppedMoving:Fire()
            end
        end)

        if table.maxn(waypoints) == 0 then
            reject("There are no waypoints in the waypoint table.")
        end

        local humanoid = self.___important.___rig:FindFirstChildOfClass("Humanoid")

        if not humanoid then
            reject("Model has no Humanoid to pathfind to.")
        end

        if self.information.visualisationinformation.VISUALISE_PATH == true then
            self:PathVisualiser(waypoints)
        end

        self.signals.___StartedMoving:Fire(waypoints)
        fireStartedMoving = true

        for _, waypoint : PathWaypoint in pairs(waypoints) do
            if cancelPathfinding == true then
                break
            end

            if self.information.___stop_pathfinding == true then
                break
            end

            self:___CombatHandler("Move", "Halt")

            local completedCustomAction = false

            if waypoint.Action == Enum.PathWaypointAction.Custom then
                completedCustomAction = self:___CustomWaypointActions(waypoint)
            end

            if completedCustomAction == true then
                continue
            end

            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoint.Position)

            humanoid.MoveToFinished:Wait()
        end

        self.signals.___StoppedMoving:Fire()

        resolve("Finished pathfinding")
    end)
end

--[[
Starts the cycle of pathfinding for the AI.
]]
function class.schema.StartPathfindingCycle(self : AIPathfindingComponent)
    self.signals.___Changed:Fire("StartPathfindingCycle", true)

    local function Move(waypoints : {})
        self:___CombatHandler("Move", "Grenade")
        HELPER.Promises.ExceptionHandler(HELPER.Promises.PromiseHandler(self.MoveToWayPoints, true, self, waypoints))
    end

    local function GetWaypoints()
        local waypoints = self:___GetPathfindingWaypoints()

        if table.maxn(waypoints) == 0 then
            warn("There are no waypoints in the waypoint table.")
            task.wait(2)
            return
        end

        Move(waypoints)
    end

    while self.information.___stop_pathfinding == false do
        GetWaypoints()
        task.wait(0.1)
    end

    self.signals.___Changed:Fire("StartPathfindingCycle", false)
end

export type AIPathfindingComponent = typeof(class.interface.new(table.unpack(...)))

return class