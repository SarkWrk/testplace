-- Services
local Shared_Table_Registry = game:GetService("SharedTableRegistry")
local Replicated_Storage = game:GetService("ReplicatedStorage")
local Pathfinding_Service = game:GetService("PathfindingService")
local Collection_Service = game:GetService("CollectionService")

-- Dependencies
local _Types = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("Types"))
local HelperModule = require(Replicated_Storage:WaitForChild("Helpers"):WaitForChild("GeneralLibrary"))
local Fast_Signal = require(Replicated_Storage:WaitForChild("dependencies wally"):WaitForChild("FastSignal"))
local Classpp = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("Classpp"))

local class = Classpp.class

type fsignal = {
    IsActive: (fsignal) -> boolean,
    Connect:<A> (fsignal, handler: (...A) -> ()) -> ...A,
    Once:<A> (fsignal, handler: (...A) -> ()) -> ...A,
    Wait: (fsignal) -> nil,
    Fire:<A> (fsignal, ...A) -> ...A,
    DisconnectAll: (fsignal) -> nil,
    Destroy: (fsignal) -> nil,

    Connected: boolean,
    Disconnect: (fsignal) -> nil,
}

type locked_information = {
    rig: Model,
    state_manager_script: Script,
    owner_script: Script,
    seed: number?,
}

type pathfinding_settings = {
    view_distance: number?,
    search_tries: number?,
    maximum_target_index: number?,

    path_settings: {
        AgentRadius: number,
        AgentHeight: number,
        WaypointSpacing: number,
        Costs: {[string]: number}?,
        PathSettings: {
            SupportPartialPath: boolean
        }?,
    }?,

    combat_settings: {
        should_stop_on_enemy_sight: boolean?,
        movespeed_reduction_on_enemy_sight: number?,
        grenade_avoidance_radius: number?,
    }?,
}

type visualisation_settings = {
    visualise_path: boolean?,
    node_spacing: number?,
    node_size: number?,
    jump_node_size_multiplier: number?,
    custom_node_size_multiplier: number?,
}

type target_information = {
    shared_table: SharedTable?
}

export type PathfindingAI_Public = {
    signals: {
        Changed: fsignal,
        Destroying: fsignal,
        StartedMoving: fsignal,
        StoppedMoving: fsignal,
        CustomWaypointActions: fsignal,
        SearchBegan: fsignal,
        SearchFinished: fsignal,
    },

    target_tags: {string},

    pathfinding_settings: {
        view_distance: number,
        search_tries: number,
        maximum_target_index: number,
    
        path_settings: {
            AgentRadius: number,
            AgentHeight: number,
            WaypointSpacing: number,
            Costs: {[string]: number},
            PathSettings: {
                SupportPartialPath: boolean
            },
        },
    
        combat_settings: {
            should_stop_on_enemy_sight: boolean,
            movespeed_reduction_on_enemy_sight: number,
            grenade_avoidance_radius: number,
        },
    },

    visualisation_settings: {
        folder_name: string,
        visualise_path: boolean,
        node_spacing: number,
        node_size: number,
        jump_node_size_multiplier: number,
        custom_node_size_multiplier: number,
    },

    --[[
    Creates a Path object to be used for pathfinding using PathfindingService.
    ]]
    CREATE_PATH: (self: PathfindingAI_Combined) -> nil,

    --[[
    Starts the cycle of pathfinding for the AI.
    ]]
    START_PATHFINDING_CYCLE: (self: PathfindingAI_Combined) -> nil,
}

type PathfindingAI_Private = {
    locked: {
        rig: Model,
        state_manager_script: Script,
        owner_script: Script,
        stop_pathfinding: boolean,
        dead: boolean,
    },

    script_only: {
        target_information: {
            positions: {{target_instance: Model|Part, position: Vector3}},
            target: {target_instance: Model|Part, position: Vector3},
            shared_table: SharedTable,
        },

        pathfinding_information: {
            path: Path,
            stop_pathfinding: boolean,
        },

        visualisation_information: {
            folder: Folder,
        },

        combat_information: {
            spotted_enemy: boolean,
            avoiding_grenade: boolean,
        },
    },

    --[[
    Basic handler for firing events. Used as a wrapper for event firing.
    ]]
    EVENT_WRAPPER: (self: PathfindingAI_Combined, string, string?, ...any) -> nil,

    --[[
    Cleans up signal connects to allow for GC.
    ]]
    DESTROY_SIGNALS: (self: PathfindingAI_Combined) -> nil,

    --[[
    Fills in script_only.target_information.positions with positional information about each target.
    ]]
    GET_TARGET_POSITIONS: (self: PathfindingAI_Combined) -> nil,

    --[[
    Starts the search cycle of the main pathfinding cycle. If the AI doesn't have sight (from the head) of the target at the end of pathfinding,
    it will move in random directions to get to the target.
    ]]
    SEARCH_CYCLE: (self: PathfindingAI_Combined, { PathWaypoint }) -> nil,

    --[[
    Function used to visualise the path the rig takes to get to a goal
    ]]
    PATH_VISUALISER: (self: PathfindingAI_Combined, { PathWaypoint }) -> nil,

    --[[
    Contains various functions that can be used in combat situations.
    ]]
    combat_handler: {
        --[[
        The functions require a pre-set 'fromFunction-want' pairing to work.
        Warns if a specific 'fromFunction-want' pairing has not been created.

        `fromFunction` : The function calling combat_handler.MAIN().

        `want` : The function that should be ran by combat_handler.MAIN().
        ]]
        MAIN: (self: PathfindingAI_Combined, "Move"|"CombatHandler", "Halt"|"Grenade") -> boolean|string,

        --[[
        Determines how locked.rig should act when seeing an enemy.
        ]]
        HALT: (self: PathfindingAI_Combined) -> boolean,

        --[[
        Checks if there're any greandes nearby, and if so tries to avoid them.
        ]]
        CHECK_IF_GRENADE_NEARBY: (self: PathfindingAI_Combined, true?) -> (boolean, {Part}) & (self: PathfindingAI_Combined) -> boolean,

        --[[
        Used to avoid grenades.
        ]]
        AVOID_GRENADE: (self: PathfindingAI_Combined) -> boolean,
    },

    --[[
    Creates a Path if there isn't one, and then uses it to generate a set of waypoints to `position`.
    ]]
    PATHWAYPOINT_TO_VECTOR3: (self: PathfindingAI_Combined, Vector3, Vector3?) -> { PathWaypoint },

    --[[
    Returns points to move to.
    ]]
    GET_PATHFINDING_WAYPOINTS: (self: PathfindingAI_Combined) -> { PathWaypoint },

    custom_waypoint_functions: {
        --[[
        Function used for the Teleporter label for Enum.WaypointAction.Custom. Returns true if teleported and false if not teleported
        ]]
        ["Teleporter"]: (self: PathfindingAI_Combined, PathWaypoint) -> boolean,

        --[[
        Function used for the Moving Platform label for Enum.WaypointAction.Custom.
        Waits on the platform until the platform has stopped moving.
        Returns true if the rig waited and false otherwise
        ]]
        ["Moving Platform"]: (self: PathfindingAI_Combined, PathWaypoint) -> boolean,
    },

    --[[
    Metafunction that contains subfunctions for custom actions
    ]]
    CUSTOM_WAYPOINT_ACTIONS: (self: PathfindingAI_Combined, PathWaypoint) -> boolean,

    --[[
    Moves the rig through all the waypoints provided in the waypoints table.
    ]]
    MOVE_TO_WAYPOINTS: (self: PathfindingAI_Combined, { PathWaypoint }) -> (),
}

type PathfindingAI_Protected = {
    random: Random,
    difficulty: number,
}

type PathfindingAI_Combined = PathfindingAI_Public & PathfindingAI_Private & PathfindingAI_Protected

local friend_access_functions = {
    PATH_VISUALISER = function(self: PathfindingAI_Combined, waypoints: { PathWaypoint })
        local visualisation_folder = Instance.new("Folder")
        self.script_only.visualisation_information.folder.Parent = workspace
        visualisation_folder.Parent = self.script_only.visualisation_information.folder

        -- Checks if the visualisation node spacing is less than the agent waypoint spacing, and if so sets the visualisation node spacing to the agent's
        if self.visualisation_settings.node_spacing < self.pathfinding_settings.path_settings.WaypointSpacing then
            print(
                "Setting visualisation_settings.node_spacing to "
                    .. self.pathfinding_settings.path_settings.WaypointSpacing
                    .. " (Previously: "
                    .. self.visualisation_settings.node_spacing
                    .. ")"
            )
            self.visualisation_settings.node_spacing = self.pathfinding_settings.path_settings.WaypointSpacing
        end

        local spacer = self.visualisation_settings.node_spacing / self.pathfinding_settings.path_settings.WaypointSpacing --[[ Calculates how often to create a visualised node ]]
        local counter = 0 -- Keeps track of when to place a node

        -- Loops through each waypoint and creates a node based off the spacer value
        for i, v: PathWaypoint in pairs(waypoints) do
            -- Creates the node part, determines its colour based off the action, and determines if the node should be shown (otherwise it's skipped)
            local waypoint = Instance.new("Part")
            counter += 1 -- Increments the counter

            -- Jump actions are never skipped, have visualisation_settings.jump_node_size_multiplier times the size of a normal node, and are given a GREEN colour
            if v.Action == Enum.PathWaypointAction.Jump then
                counter = 0 -- Resets the counter
                waypoint.Color = Color3.new(0.278431, 0.674510, 0.082353) -- Sets the colour
                waypoint.Size = Vector3.new(
                    self.visualisation_settings.node_size
                        * self.visualisation_settings.jump_node_size_multiplier,
                    self.visualisation_settings.node_size
                        * self.visualisation_settings.jump_node_size_multiplier,
                    self.visualisation_settings.node_size
                        * self.visualisation_settings.jump_node_size_multiplier
                )

                -- Custom actions are never skipped, have visualisation_settings.custom_node_size_multiplier times the size of a normal node, and are given a PINK-ISH-WHITE colour
            elseif v.Action == Enum.PathWaypointAction.Custom then
                counter = 0 -- Resets the counter
                waypoint.Color = Color3.new(1.000000, 0.537255, 1.000000) -- Sets the colour
                waypoint.Size = Vector3.new(
                    self.visualisation_settings.node_size
                        * self.visualisation_settings.custom_node_size_multiplier,
                    self.visualisation_settings.node_size
                        * self.visualisation_settings.custom_node_size_multiplier,
                    self.visualisation_settings.node_size
                        * self.visualisation_settings.custom_node_size_multiplier
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

            local waypoint_label_text = "WP: " .. i
            local text_size = 10

            local billboard = Instance.new("BillboardGui")
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.Size = UDim2.fromOffset(waypoint_label_text:len(), text_size)

            local waypoint_label = Instance.new("TextLabel")
            waypoint_label.Size = UDim2.fromOffset(waypoint_label_text:len(), text_size)
            waypoint_label.Text = waypoint_label_text
            waypoint_label.BackgroundTransparency = 1
            waypoint_label.TextSize = text_size

            waypoint_label.Parent = billboard

            billboard.Parent = waypoint
            waypoint.Parent = visualisation_folder -- Parents the node to the folder
        end

        coroutine.resume(coroutine.create(function()
            self.signals.StoppedMoving:Wait()
    
            visualisation_folder:Destroy()
        end))
    
        self:EVENT_WRAPPER("_PathVisualiser", nil, visualisation_folder)
    end,

    combat_handler = {
        MAIN = function(self: PathfindingAI_Combined, from_function: "Move"|"CombatHandler", want: "Halt"|"Grenade"): boolean|string
            self:EVENT_WRAPPER("combatHandler._Main", nil, from_function, want)

            if from_function == "Move" and want == "Halt" then
                return self.combat_handler.HALT(self)
            end
        
            if from_function == "Move" and want == "Grenade" then
                return self.combat_handler.CHECK_IF_GRENADE_NEARBY(self)
            end
        
            local warnMessage = "combatHandler._Main called from function: '"
                .. from_function
                .. "' wanting the action '"
                .. want
                .. "' not fufilled because the fromFunction-want combination is created."
        
            warn(warnMessage)
        
            return warnMessage
        end,

        HALT = function(self: PathfindingAI_Combined): boolean
            if self.script_only.combat_information.spotted_enemy == false then
                return false
            end
    
            local reducedSpeed = false
    
            if self.pathfinding_settings.combat_settings.should_stop_on_enemy_sight == false then
                reducedSpeed = true
                local walkspeed = self.locked.state_manager_script:GetAttribute("Walkspeed") :: number
                self.locked.state_manager_script:SetAttribute("Walkspeed", walkspeed - self.pathfinding_settings.combat_settings.movespeed_reduction_on_enemy_sight)
            end
    
            while self.script_only.combat_information.spotted_enemy == true do
                if self.locked.stop_pathfinding == true then
                    break
                end
    
                self.combat_handler.MAIN(self, "CombatHandler", "Grenade")
                task.wait()
            end
    
            if reducedSpeed == true then
                local walkspeed = self.locked.state_manager_script:GetAttribute("Walkspeed") :: number
                self.locked.state_manager_script:SetAttribute("Walkspeed", walkspeed + self.pathfinding_settings.combat_settings.movespeed_reduction_on_enemy_sight)
            end
    
            return true
        end,

        CHECK_IF_GRENADE_NEARBY = function(self: PathfindingAI_Combined, return_nearby_grenades: true?): (boolean, {Part}?)
            local grenades = Collection_Service:GetTagged("Grenade")

            if table.maxn(grenades) == 0 then
                return false
            end

            local nearby_grenades = {}

            local function RAYCAST_POSITION_TO_GRENADE(position, grenadePosition)
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

                local look_at_grenade = CFrame.lookAt(position, grenadePosition)

                local ray = workspace:Raycast(
                    position,
                    look_at_grenade.LookVector * self.pathfinding_settings.view_distance,
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

                if self.locked.rig.PrimaryPart == nil then
                    continue
                end

                if HelperModule.NumberManipulation.Delta(self.locked.rig.PrimaryPart.Position, grenade.Position) > self.pathfinding_settings.combat_settings.grenade_avoidance_radius then
                    continue
                end

                local rig_head = self.locked.rig:FindFirstChild("Head") :: BasePart? | MeshPart?

                if rig_head == nil then
                    continue
                end

                local head_size = rig_head.Size
                local size_X, size_Y, size_Z = head_size.X / 2, head_size.Y / 2, head_size.Z / 2

                local found_grenade = false

                for _ = 1, 10 do
                    if found_grenade == true then
                        break
                    end

                    found_grenade = RAYCAST_POSITION_TO_GRENADE(
                        rig_head.Position + Vector3.new(self.random:NextNumber(-1, 1) * size_X, self.random:NextNumber(-1, 1) * size_Y, self.random:NextNumber(-1, 1) * size_Z),
                        grenade.Position
                    )
                end

                if found_grenade == false then
                    continue
                end

                table.insert(nearby_grenades, grenade)
            end

            if table.maxn(nearby_grenades) == 0 then
                self.script_only.combat_information.avoiding_grenade = false
                return false
            end

            if return_nearby_grenades == true then
                return true, nearby_grenades
            else
                return true
            end
        end,

        AVOID_GRENADE = function(self: PathfindingAI_Combined): boolean
            local is_there_nearby_grenades, nearby_grenades = self.combat_handler.CHECK_IF_GRENADE_NEARBY(self, true)
        
            if is_there_nearby_grenades == false then
                return false
            end

            if self.locked.rig.PrimaryPart == nil then
                return false
            end

            table.sort(nearby_grenades, function(a, b)
                local deltaA = HelperModule.NumberManipulation.Delta(self.locked.rig.PrimaryPart.Position, a.Position)
                local deltaB = HelperModule.NumberManipulation.Delta(self.locked.rig.PrimaryPart.Position, b.Position)
        
                if deltaA < deltaB then
                    return true
                end
        
                return false
            end)
        
            local grenade_to_be_avoided = nearby_grenades[1]
        
            local humanoid = self.locked.rig:FindFirstChildOfClass("Humanoid")
        
            if humanoid == nil then
                self.script_only.combat_information.avoiding_grenade = false
                return false
            end
        
            local grenade_directon =
                CFrame.lookAt(self.locked.rig.PrimaryPart.Position, grenade_to_be_avoided.Position).LookVector
        
            local moveToPosition = Vector3.new(grenade_directon.X, 0, grenade_directon.Y)
                * -self.pathfinding_settings.combat_settings.grenade_avoidance_radius
                + self.locked.rig.PrimaryPart.Position
        
        
            local function CheckPositionValidity(position)
                local position_look_at = CFrame.lookAt(self.locked.rig.PrimaryPart.Position, position).LookVector
                local distance = HelperModule.NumberManipulation.Delta(self.locked.rig.PrimaryPart.Position, position)
        
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
        
                params.FilterType = Enum.RaycastFilterType.Exclude
                params:AddToFilter(Collection_Service:GetTagged("Bullets"))
                params:AddToFilter(Collection_Service:GetTagged("Visualiser"))
                params:AddToFilter(Collection_Service:GetTagged("AI"))
                params:AddToFilter(Collection_Service:GetTagged("Gun"))
                params:AddToFilter(Collection_Service:GetTagged("Goal"))
                params:AddToFilter(Collection_Service:GetTagged("Enemy Utilities"))
        
                local ray = workspace:Raycast(self.locked.rig.PrimaryPart.Position, position_look_at * distance, params)
        
                if not ray then
                    return position
                end
        
                local newPosition = self.locked.rig.PrimaryPart.Position + position_look_at * (ray.Distance - 0.1)
        
                return newPosition
            end
        
            local _, returned = HelperModule.Promises.PromiseHandler(self.PATHWAYPOINT_TO_VECTOR3, true, self, CheckPositionValidity(moveToPosition)):ExceptionHandler()
        
            if returned.Resolved == false then
                self.script_only.combat_information.avoiding_grenade = false
                return false
            end
        
            local waypoints = returned.Resolve
        
            local _, promiseReturn = HelperModule.Promises.PromiseHandler(self.MOVE_TO_WAYPOINTS, true, self, waypoints):ExceptionHandler()

            self.script_only.combat_information.avoiding_grenade = false
        
            if promiseReturn.Resolved == false then
                return false
            end
        
            return true
        end,
    },

    PATHWAYPOINT_TO_VECTOR3 = function(self: PathfindingAI_Combined, position: Vector3, start_position_override: Vector3?): { PathWaypoint }?
        self:CREATE_PATH()

        local path: Path = self.script_only.pathfinding_information.path

        local position_used_for_compute_async 
        if start_position_override then 
            position_used_for_compute_async = start_position_override
        else
            if self.locked.rig.PrimaryPart then
                local left_foot = self.locked.rig:FindFirstChild("LeftFoot")
                if left_foot then
                    position_used_for_compute_async = Vector3.new(self.locked.rig.PrimaryPart.CFrame.Position.X, left_foot.CFrame.Position.Y, self.locked.rig.PrimaryPart.CFrame.Position.Z)
                else
                    position_used_for_compute_async = self.locked.rig.PrimaryPart.Position
                end
            else
                error("No start position override nor primary part!")
                return
            end
        end

        local success, err = pcall(function()
            path:ComputeAsync(position_used_for_compute_async, position)
        end)

        if not success then
            error("Failed to create path: " .. err)
            return
        end

        if path.Status == Enum.PathStatus.NoPath then
            error("Path Status is Enum.PathStatus.NoPath.")
            return
        end

        self:EVENT_WRAPPER("_PathwaypointToVector3", nil, path:GetWaypoints())

        return path:GetWaypoints()
    end,

    GET_PATHFINDING_WAYPOINTS = function(self: PathfindingAI_Combined): { PathWaypoint }
        self:GET_TARGET_POSITIONS()

        if not self.locked.rig.PrimaryPart then
            return {}
        end

        table.sort(
            self.script_only.target_information.positions,
            function(
                a: { position: Vector3, target_instance: Model | Part },
                b: { position: Vector3, target_instance: Model | Part }
            )
                local delta_a = HelperModule.NumberManipulation.Delta(self.locked.rig.PrimaryPart.Position, a.position)
                local delta_b = HelperModule.NumberManipulation.Delta(self.locked.rig.PrimaryPart.Position, b.position)
    
                if delta_a < delta_b then
                    return true
                end
    
                return false
            end
        )
    
        local table_size = table.maxn(self.script_only.target_information.positions)
        local maxium_possible_target_index = math.clamp(table_size, 1, self.pathfinding_settings.maximum_target_index)
    
        local function GetChance(x)
            return 100 * math.pow(x, 4) - 8 * math.pow(x, 3) - math.pow(x, 2) - 5 * x
        end
    
        local chosen_number = self.random:NextNumber(0, GetChance(maxium_possible_target_index))
    
        local found_int
    
        for i = 1, maxium_possible_target_index do
            local iLevelChance = GetChance(i)
    
            if chosen_number > iLevelChance then
                continue
            end
    
            found_int = i
            break
        end
    
        local target: { position: Vector3, target_instance: Part | Model } = self.script_only.target_information.positions[found_int]
    
        if target == nil then
            return {}
        end
    
        self.script_only.target_information.target = target

        local waypoints = self:PATHWAYPOINT_TO_VECTOR3(target.position)
    
        self:EVENT_WRAPPER("_GetPathfindingWaypoints", nil, waypoints)
    
        return waypoints
    end,

    custom_waypoint_functions = {
        ["Teleporter"] = function(self: PathfindingAI_Combined, waypoint: PathWaypoint): boolean -- Requires the passing of the waypoint position
            local position = waypoint.Position

            -- Creates an OverlapParams that includes the workspaceSkips.Parts.Teleporters folder, ignoring CanCollide
            local allow_list = OverlapParams.new()
            allow_list.FilterType = Enum.RaycastFilterType.Include
            allow_list.FilterDescendantsInstances = { workspace.Skips.Parts.Teleporters }

            local cast = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(0.1, 0.1, 0.1), allow_list) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

            if cast then -- Checks if a table is returned by the previous operation
                if table.maxn(cast) > 0 then -- Makes sure there are part(s) inside the table
                    local teleporter_event: BindableFunction = cast[1]:FindFirstChild("TP") -- Tries to find the BindableFunction nammed "TP" inside the first element of the table

                    -- If found, invokes it with the rig and halts until a response is recieved. If the response is (int) 200 reponse, returns true. Otherwise, returns false
                    if teleporter_event then
                        local response = false

                        response = teleporter_event:Invoke(self.locked.rig) -- Invokes the BindableFunction

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
        end,

        ["Moving Platform"] = function(self: PathfindingAI_Combined, waypoint: PathWaypoint): boolean -- Requires the passing of the waypoint position
            local position = waypoint.Position

            -- Creates an OVerlapParams that includes the workspace.Skips.Parts.MovingPlatforms folder, ignoring CanCollide
            local allow_list = OverlapParams.new()
            allow_list.FilterType = Enum.RaycastFilterType.Include
            allow_list.FilterDescendantsInstances = { workspace.Skips.Parts.MovingPlatforms }

            local cast = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(0.1, 0.1, 0.1), allow_list) -- Casts using game.Workspace:GetPartsInPart() for parts inside the waypoint position

            if cast then -- Checks if a table is returned by the previous operation
                if table.maxn(cast) > 0 then -- Checks if the table has elements in it
                    -- If there are elements in it, tries to find the "Active" used to wait while the platform is active, and the "Touch" BindableEvent to start the platform
                    local mover_platform_subpart = cast[1]

                    if not mover_platform_subpart then
                        return false
                    end

                    local mover_platform = mover_platform_subpart.Parent.Parent
                    local mover_platform_active: BoolValue = mover_platform:FindFirstChild("Mover"):FindFirstChild("Active")
                    local mover_start_event: BindableEvent =
                        mover_platform:FindFirstChild("Attached"):FindFirstChild("Start"):FindFirstChild("Touch")

                    -- If both are found, the Touch BindableEvent is fired with the rig as an argument, and then the rig waits while the platform moves
                    if mover_platform_active and mover_start_event then
                        mover_start_event:Fire() -- Fires the BindableEvent

                        while mover_platform_active.Value == false do -- Waits until the platform activates
                            task.wait()
                        end

                        self.locked.owner_script:SetAttribute("OnMovingPlatform", true) -- Publicses that the rig is on a moving platform

                        local humanoid = self.locked.rig:FindFirstChild("Humanoid") :: Humanoid?

                        if not humanoid then
                            return false
                        end

                        while mover_platform_active.Value == true do -- Waits until the platform deactivates
                            local startPosition: Vector3 =
                                mover_platform:FindFirstChild("Attached"):FindFirstChild("Start").Position

                            humanoid:MoveTo(startPosition)
                            task.wait()
                        end

                        self.locked.owner_script:SetAttribute("OnMovingPlatform", false) -- Publicses that the rig is not on a moving platform

                        return true -- Returns true when the platform deactivates
                    else -- If the "Active" BoolValue and/or "Touch" BindableEvent aren't found, warns useful information for debugging
                        warn(
                            "Found active boolean? ",
                            mover_platform_active,
                            " Found event? ",
                            mover_start_event,
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
        end,
    },

    CUSTOM_WAYPOINT_ACTIONS = function(self: PathfindingAI_Combined, waypoint: PathWaypoint): boolean
        self:EVENT_WRAPPER("_CustomWaypointActions", "CustomWaypointActions", waypoint.Label, waypoint)

        return self.custom_waypoint_functions[waypoint.Label](self, waypoint)
    end,

    MOVE_TO_WAYPOINTS = function(self: PathfindingAI_Combined, waypoints: { PathWaypoint })
        local cancel_pathfinding = false

        if not waypoints then
            self:EVENT_WRAPPER("_MoveToWaypoints", "StoppedMoving")
            error("Waypoint table is nil.")
        end

        if table.maxn(waypoints) == 0 then
            self:EVENT_WRAPPER("_MoveToWaypoints", "StoppedMoving")
            error("There are no waypoints in the waypoint table.")
        end

        local humanoid = self.locked.rig:FindFirstChildOfClass("Humanoid") :: Humanoid?

        if not humanoid then
            self:EVENT_WRAPPER("_MoveToWaypoints", "StoppedMoving")
            error("Model has no Humanoid to pathfind to.")
        end

        if self.visualisation_settings.visualise_path == true then
            self:PATH_VISUALISER(waypoints)
        end

        self:EVENT_WRAPPER("_MoveToWaypoints", "StartedMoving", waypoints)

        local avoided_grenade = false
        local completed_custom_action = false
        local _halted
        local avoiding_grenade = self.script_only.combat_information.avoiding_grenade

        for _, waypoint: PathWaypoint in pairs(waypoints) do
            if cancel_pathfinding == true then
                break
            end

            if self.locked.stop_pathfinding == true then
                break
            end

            if waypoint.Action == Enum.PathWaypointAction.Custom then
                completed_custom_action = self:CUSTOM_WAYPOINT_ACTIONS(waypoint)
            end

            if completed_custom_action == true then
                continue
            end

            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoint.Position)

            humanoid.MoveToFinished:Wait()

            _halted = self.combat_handler.MAIN(self, "Move", "Halt")

            if avoiding_grenade == false then
                avoided_grenade = self.combat_handler.MAIN(self, "Move", "Grenade")
            end

            if avoided_grenade == true then
                break
            end
        end

        if avoided_grenade == true then
            self:EVENT_WRAPPER("_MoveToWaypoints", "StoppedMoving")

            self.combat_handler.AVOID_GRENADE(self)

            if self.locked.rig.PrimaryPart then
                self:PATHWAYPOINT_TO_VECTOR3(waypoints[table.maxn(waypoints)].Position, self.locked.rig.PrimaryPart.Position)
            else
                self:PATHWAYPOINT_TO_VECTOR3(waypoints[table.maxn(waypoints)].Position)
            end
        else
            self:EVENT_WRAPPER("_MoveToWaypoints", "StoppedMoving")
        end
    end,
}

PathfindingAI = class "PathfindingAIBase" {
    constructor = function(self: PathfindingAI_Combined, locked_information: locked_information, target_tags: {string}?, pathfinding_settings: pathfinding_settings?, visualisation_settings: visualisation_settings?, target_information: target_information?)
        self.visualisation_settings.folder_name = "Visualiser" .. self.random:NextNumber(1, 1000000000)
        self.script_only.visualisation_information.folder.Name = self.visualisation_settings.folder_name

        -- Locked settings
        self.locked.rig = locked_information.rig
        self.locked.state_manager_script = locked_information.state_manager_script
        self.locked.owner_script = locked_information.owner_script
        
        if locked_information.seed then
            self.random = Random.new(locked_information.seed)
        end

        -- Target tag settings
        if target_tags then
            self.target_tags = target_tags
        end

        -- Pathfinding settings
        if pathfinding_settings then
            for index, value in pairs(pathfinding_settings) do
                self.pathfinding_settings[index] = value

                if index == "combat_settings" then
                    continue
                end
            end
            
            if pathfinding_settings.combat_settings then
                for index, value in pairs(pathfinding_settings.combat_settings) do
                    self.pathfinding_settings.combat_settings[index] = value
                end
            end
        end

        -- Visualisation settings
        if visualisation_settings then
            for index, value in pairs(visualisation_settings) do
                self.visualisation_settings[index] = value
            end
        end

        -- Target information settings
        if target_information then
            if target_information.shared_table then
                self.script_only.target_information.shared_table = target_information.shared_table
            end
        end

        self:CREATE_PATH()
    end,

    destructor = function(self: PathfindingAI_Combined)
        self:DESTROY_SIGNALS()
    end,

    Public = {
        signals = {
            Changed = Fast_Signal.new(),
            Destroying = Fast_Signal.new(),
            StartedMoving = Fast_Signal.new(),
            StoppedMoving = Fast_Signal.new(),
            CustomWaypointActions = Fast_Signal.new(),
            SearchBegan = Fast_Signal.new(),
            SearchFinished = Fast_Signal.new(),
        },

        target_tags = {
            "Goal"
        },

        pathfinding_settings = {
            view_distance = 100,
            search_tries = 5,
            maximum_target_index = 5,

            path_settings = {
                AgentRadius = 2,
                AgentHeight = 5,
                WaypointSpacing = 1,
                Costs = {},

                PathSettings = {
                    SupportPartialPath = true,
                },
            },

            combat_settings = {
                should_stop_on_enemy_sight = true,
                movespeed_reduction_on_enemy_sight = 8,
                grenade_avoidance_radius = 40,
            },
        },

        visualisation_settings = {
            folder_name = "",
            visualise_path = true,
            node_spacing = 1,
            node_size = 1,
            jump_node_size_multiplier = 2,
            custm_node_size_multiplier = 3,
        },

        CREATE_PATH = function(self: PathfindingAI_Combined)           
            local path: Path = Pathfinding_Service:CreatePath(self.pathfinding_settings.path_settings)

            self.script_only.pathfinding_information.path = path

            self:EVENT_WRAPPER("CreatePath", nil, path)
        end,

        START_PATHFINDING_CYCLE = function(self: PathfindingAI_Combined)
            self:EVENT_WRAPPER("StartPathfindingCycle", nil, true)

            local function MOVE(waypoints: {})
                self.combat_handler.MAIN(self, "Move", "Grenade")
                self:SEARCH_CYCLE(waypoints)
            end

            local function GET_WAYPOINTS()
                local waypoints = self:GET_PATHFINDING_WAYPOINTS()

                if table.maxn(waypoints) == 0 then
                    -- warn("There are no waypoints in the waypoint table.")
                    task.wait(2)
                    return
                end

                MOVE(waypoints)
            end

            while self.locked.stop_pathfinding == false do
                GET_WAYPOINTS()
                task.wait()
            end

            self:EVENT_WRAPPER("StartPathfindingCycle", nil, false)
        end,
    },

    Private = {
        --[[
        **NO TOUCHY!!**
        ]]
        locked = {
            rig = "",
            state_manager_script = "",
            owner_script = "",
            stop_pathfinding = false,
            dead = false,
        },

        --[[
        **Can be touched!!**
        ]]
        script_only = {
            target_information = {
                positions = {},
                target = "",
                shared_table = Shared_Table_Registry:GetSharedTable("PositionsTrackerTable"),
            },

            pathfinding_information = {
                path = "",
                stop_pathfinding = false,
            },

            visualisation_information = {
                folder = Instance.new("Folder"),
            },

            combat_information = {
                spotted_enemy = false,
                avoiding_grenade = false,
            },
        },

        EVENT_WRAPPER = function(self: PathfindingAI_Combined, from: string, event_name: string?, ...)
            local extra_information = ...

            self.signals.Changed:Fire(from, extra_information)

            if event_name then
                if typeof(self.signals[event_name]) == nil then
                    self.signals[event_name] = Fast_Signal.new()
                end

                self.signals[event_name]:Fire(extra_information)
            end
        end,

        DESTROY_SIGNALS = function(self: PathfindingAI_Combined)
            self.signals.Destroying:Fire()

            local destroy_start_time = tick()

            self.locked.stop_pathfinding = true

            for signal_name: string, signal: fsignal in pairs(self.signals) do
                if signal_name == "Destroying" then
                    continue
                end

                signal:Destroy()
            end

            while tick()-destroy_start_time < 2 do
                task.wait()
            end

            self.signals.Destroying:Destroy()
        end,

        GET_TARGET_POSITIONS = function(self: PathfindingAI_Combined)
            local possible_targets = {}

            local function GET_INSTANCE_FROM_PATH(path: string): Model | Part?
                local target = workspace
                local split_path = path:split(".")

                for index, part in pairs(split_path) do
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

            local function INSERT_POSITIONS_INTO_TABLE(tag_position_table)
                if tag_position_table == nil then
                    return
                end

                for path: string, position: Vector3 in tag_position_table do
                    local target_instance = GET_INSTANCE_FROM_PATH(path)

                    if target_instance == nil then
                        continue
                    end

                    table.insert(possible_targets, { target_instance = target_instance, position = position })
                end
            end

            for _, tag in pairs(self.target_tags) do
                local tag_table = self.script_only.target_information.shared_table[tag]

                if tag_table == nil then
                    continue
                end

                INSERT_POSITIONS_INTO_TABLE(tag_table["PositionalData"])
            end

            self.script_only.target_information.positions = possible_targets

            self:EVENT_WRAPPER("_GetTargetPositions", nil, possible_targets)
        end,

        SEARCH_CYCLE = function(self: PathfindingAI_Combined, initial_waypoints: { PathWaypoint })
            local target: Model | Part = self.script_only.target_information.target.target_instance

            self:MOVE_TO_WAYPOINTS(initial_waypoints)

            local function CAN_RIG_SEE_TARGET()
                local rig_head = self.locked.rig:FindFirstChild("Head") :: BasePart? | MeshPart?

                if rig_head == nil then
                    return false
                end

                local head_size = rig_head.Size
                local size_x, size_y, size_z = head_size.X / 2, head_size.Y / 2, head_size.Z / 2

                local found_grenade = false

                local function RAYCAST_POSITION_TO_TARGET(position)
                    local params = RaycastParams.new()

                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params:AddToFilter(Collection_Service:GetTagged("Bullets"))
                    params:AddToFilter(Collection_Service:GetTagged("Visualiser"))
                    params:AddToFilter(Collection_Service:GetTagged("Enemy Utilities"))
                    params:AddToFilter(Collection_Service:GetTagged("AI"))
                    params:AddToFilter(Collection_Service:GetTagged("Gun"))

                    local target_position

                    if target:IsA("Model") then
                        local primary_part = target.PrimaryPart

                        if primary_part == nil then
                            return true
                        end

                        target_position = primary_part.Position
                    elseif target:IsA("Part") then
                        target_position = target.Position
                    else
                        warn(
                            "Target is not a model/part; therefore it is impossible to find its position. Target class: "
                                .. target.ClassName
                        )
                        return true
                    end

                    local look_at_target = CFrame.lookAt(position, target_position)

                    local ray = workspace:Raycast(position, look_at_target.LookVector * self.pathfinding_settings.view_distance, params)

                    if not ray then
                        return false
                    end

                    if ray.Instance ~= target then
                        --[[
                        Check if what the rig sees is an enemy or not
                        ]]
                        for _, tag: string in pairs(ray.Instance:GetTags()) do
                            if table.find(self.target_tags, tag) then
                                return true
                            end
                        end

                        --[[
                        If that part is a part and has a model as its parent, check the parent's tags too.
                        ]]
                        if ray.Instance:FindFirstAncestorOfClass("Model") then
                            for _, tag: string in pairs(ray.Instance:FindFirstAncestorOfClass("Model"):GetTags()) do
                                if table.find(self.target_tags, tag) then
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
                    if found_grenade == true then
                        break
                    end

                    found_grenade = RAYCAST_POSITION_TO_TARGET(rig_head.Position + Vector3.new(self.random:NextNumber(-1, 1) * size_x, self.random:NextNumber(-1, 1) * size_y, self.random:NextNumber(-1, 1) * size_z))
                end

                if found_grenade == false then
                    return false
                end

                return true
            end

            if CAN_RIG_SEE_TARGET() == true then
                return
            end

            --[[
            The function that selects where the rig should move to to continue to search for the target
            ]]
            local function SEARCH_ALGORITHM(): Vector3
                --[[
                Function to choose the point where the rig should go
                ]]
                local function CHOOSE_POINT()
                    if not self.locked.rig.PrimaryPart then
                        error("Rig has no primary part!")
                    end

                    return self.locked.rig.PrimaryPart.Position + Vector3.new(self.random:NextInteger(-10, 10), 0, self.random:NextInteger(-10, 10))
                end

                --[[
                Function to check if the space where the point was chosen is able to be reached
                ]]
                local function CHECK_IF_SPACE_IS_AVAILABLE(position: Vector3)
                    local ignored_tags = {
                        "AI",
                        "Bullets",
                        "Grenade",
                        "Goal",
                        "Visualiser",
                        "Gun",
                        "Enemy Utilities",
                    }

                    local overlap_parameters = OverlapParams.new()
                    overlap_parameters.FilterType = Enum.RaycastFilterType.Exclude

                    for _, tag in pairs(ignored_tags) do
                        overlap_parameters:AddToFilter(Collection_Service:GetTagged(tag))
                    end

                    overlap_parameters:AddToFilter(self.locked.rig)

                    local is_area_open = workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(2.5, 2.5, 2.5), overlap_parameters)

                    if table.maxn(is_area_open) > 0 then
                        return false
                    end

                    local head = self.locked.rig:FindFirstChild("Head") :: BasePart?

                    if head == nil then
                        return true
                    end

                    local raycast_parameters = RaycastParams.new()
                    raycast_parameters.FilterType = Enum.RaycastFilterType.Exclude

                    for _, tag in pairs(ignored_tags) do
                        raycast_parameters:AddToFilter(Collection_Service:GetTagged(tag))
                    end
                    
                    raycast_parameters:AddToFilter(self.locked.rig)

                    if not self.locked.rig.PrimaryPart then
                        error("Rig has no primary part!")
                    end

                    local distance_between_primary_part_and_head = HelperModule.NumberManipulation.Delta(head.Position, self.locked.rig.PrimaryPart.Position)

                    local look_direction = CFrame.lookAt(head.Position, position + Vector3.new(0, distance_between_primary_part_and_head, 0)).LookVector * HelperModule.NumberManipulation.Delta(self.locked.rig.PrimaryPart.Position, position)

                    local is_there_a_wall = workspace:Raycast(head.Position, look_direction, raycast_parameters)

                    if is_there_a_wall then
                        if game:GetService("RunService"):IsStudio() == true then
                            print("Wall in way. Hit: " .. is_there_a_wall.Instance:GetFullName())
                        end

                        return false
                    end

                    return true
                end

                local new_position = CHOOSE_POINT()

                if CHECK_IF_SPACE_IS_AVAILABLE(new_position) == false then
                    while CHECK_IF_SPACE_IS_AVAILABLE(new_position) == false do
                        new_position = CHOOSE_POINT()
                        task.wait()
                    end
                end

                return new_position
            end

            local tries = 0

            self:EVENT_WRAPPER("_SearchCycle", "SearchBegan")

            while task.wait() do
                if CAN_RIG_SEE_TARGET() == true then
                    self:EVENT_WRAPPER("_SearchCycle", "SearchFinished", "Found target")
                    return
                end

                if tries >= self.pathfinding_settings.search_tries then
                    self:EVENT_WRAPPER("_SearchCycle", "SearchFinished", "Ran out of tries")
                    return
                end

                tries += 1

                local success, waypoints = pcall(function()
                    return self:PATHWAYPOINT_TO_VECTOR3(SEARCH_ALGORITHM())
                end)

                if success == false then
                    break
                end

                self:MOVE_TO_WAYPOINTS(waypoints)
            end
        end,

        PATH_VISUALISER = friend_access_functions.PATH_VISUALISER,

        combat_handler = {
            MAIN = friend_access_functions.combat_handler.MAIN,

            HALT = friend_access_functions.combat_handler.HALT,

            CHECK_IF_GRENADE_NEARBY = friend_access_functions.combat_handler.CHECK_IF_GRENADE_NEARBY,

            AVOID_GRENADE = friend_access_functions.combat_handler.AVOID_GRENADE,

        },

        PATHWAYPOINT_TO_VECTOR3 = friend_access_functions.PATHWAYPOINT_TO_VECTOR3,

        GET_PATHFINDING_WAYPOINTS = friend_access_functions.GET_PATHFINDING_WAYPOINTS,

        custom_waypoint_functions = {
            ["Teleporter"] = friend_access_functions.custom_waypoint_functions.Teleporter,

            ["Moving Platform"] = friend_access_functions.custom_waypoint_functions["Moving Platform"],
        },

        CUSTOM_WAYPOINT_ACTIONS = friend_access_functions.CUSTOM_WAYPOINT_ACTIONS,

        MOVE_TO_WAYPOINTS = friend_access_functions.MOVE_TO_WAYPOINTS,
    },

    Protected = {
        random = Random.new(),
        difficulty = 100,
    },

    Friend = {
        friend_access_functions.PATH_VISUALISER,
        friend_access_functions.combat_handler.MAIN,
        friend_access_functions.combat_handler.HALT,
        friend_access_functions.combat_handler.CHECK_IF_GRENADE_NEARBY,
        friend_access_functions.combat_handler.AVOID_GRENADE,
        friend_access_functions.PATHWAYPOINT_TO_VECTOR3,
        friend_access_functions.GET_PATHFINDING_WAYPOINTS,
        friend_access_functions.custom_waypoint_functions.Teleporter,
        friend_access_functions.custom_waypoint_functions["Moving Platform"],
        friend_access_functions.CUSTOM_WAYPOINT_ACTIONS,
        friend_access_functions.MOVE_TO_WAYPOINTS,
    },
}

return PathfindingAI