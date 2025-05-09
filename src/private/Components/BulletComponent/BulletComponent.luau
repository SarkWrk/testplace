local classpp = require(game:GetService("ReplicatedStorage"):WaitForChild("dependencies wally"):WaitForChild("Classpp"))
local class = classpp.class

local bullet = class "Bullet" {
    constructor = function(self, damage : number, enemy_tags: {string}, ignored_tags: {string}, move_towards: CFrame, bullet_drop: number, distance_timeout: number, speed: number, pierce: number, pierce_damage_loss: number, start_position: Vector3)
        self.damage = damage
        self.enemy = enemy_tags
        self.ignore_tagged = ignored_tags
        self.move_towards = move_towards
        self.bullet_drop = bullet_drop
        self.distance_timeout = distance_timeout
        self.speed = speed
        self.pierce = pierce
        self.pierce_damage_loss = pierce_damage_loss
        self.start_position = start_position
        self.position = start_position

        self.raycast_parameters.FilterType = Enum.RaycastFilterType.Exclude
        self.raycast_parameters.RespectCanCollide = true
        self.overlap_parameters.FilterType = Enum.RaycastFilterType.Exclude
        self.overlap_parameters.RespectCanCollide = true

        self:UPDATE_HITREG_PARAMETERS()
    end,

    Public = {
        damage = 0,
        enemy = {},
        ignore_tagged = {},
        move_towards = CFrame.new(),
        bullet_drop = 0,
        distance_timeout = 0,
        speed = 0,
        pierce = 0,
        pierce_damage_loss = 0,
        start_position = Vector3.new(),
        to_destroy = false,
        look_direction = CFrame.new(),
        parts_pierced = {},
        already_tagged_instances = {},

        START = function(self)
            self:MOVEMENT()
        end,

        UPDATE_HITREG_PARAMETERS = function(self)
            if table.maxn(self.ignore_tagged) ~= 0 then
                for _, tag in pairs(self.ignore_tagged) do
                    for _, instance in pairs(game:GetService("CollectionService"):GetTagged(tag)) do
                        if table.find(self.already_tagged_instances, instance) then
                            continue
                        else
                            table.insert(self.already_tagged_instances, instance)
                        end

                        self.raycast_parameters:AddToFilter(instance)
                        self.overlap_parameters:AddToFilter(instance)
                    end
                end
            end
        end,
    },

    Private = {
        distance_moved = 0,
        calculated_moving_direction = Vector3.new(),
        position = Vector3.new(),
        adjusted_bullet_drop = 0,
        raycast_parameters = RaycastParams.new(),
        overlap_parameters = OverlapParams.new(),

        PIERCE_FUNCTIONS = function(self, pierced_part: Part|Model)
            self.parts_pierced[table.maxn(self.parts_pierced) + 1] = pierced_part
        end,

        DAMAGE_FUNCTION = function(self, hit_part: Part)
            if table.maxn(self.parts_pierced) >= self.pierce then
                self.to_destroy = true -- Tells the programme that it has hit more parts than the pierce limit + 1, and therefore the bullet should afterwards be destroyed
            else
                if table.maxn(self.parts_pierced) > 0 then
                    self.damage = self.damage
                        - (self.damage / 100 * self.pierce_damage_loss)
                end
            end
        
            local isEnemy = false
        
            -- Check if the part has already been pierced through, and therefore should be ignored
            if table.find(self.parts_pierced, hit_part) then
                return
            end
        
            -- Detects if the hitpart or if the clostest ancestor has a tag that is affilated with the enemy
            for _, v in pairs(self.enemy) do
                if hit_part:HasTag(v) then
                    isEnemy = true
                end
            end
            
            local model = hit_part:FindFirstAncestorOfClass("Model")
        
            if isEnemy == false then
                if model then
                    for _, v in pairs(self.enemy) do
                        if model:HasTag(v) then
                            isEnemy = true
                        end
                    end
                end
            end
        
            -- Destroys itself if it's not an enemy
            if isEnemy == false then
                self:PIERCE_FUNCTIONS(hit_part)
                return
            end
        
            -- Attempts to find the humanoid
            local humanoid = hit_part:FindFirstChildOfClass("Humanoid")
        
            if humanoid == nil then
                humanoid = model:FindFirstChildOfClass("Humanoid")
            end
        
            -- If there's no Humanoid, destroys itself
            if not humanoid then
                self:PIERCE_FUNCTIONS(hit_part)
                return
            end
        
            local defense = hit_part:GetAttribute("Defense")
        
            if defense == nil then
                defense = model:GetAttribute("Defense")
            end
        
            if defense == nil then
                defense = 0
            end
        
            humanoid:TakeDamage(self.damage - (self.damage / 100 * defense))
        
            self:PIERCE_FUNCTIONS(hit_part)
        end,

        HIT_DETECTION = function(self)
            self:UPDATE_HITREG_PARAMETERS()

            if self.to_destroy == true then
                return
            end

            local rayCast: RaycastResult? = workspace:Raycast(
                self.position,
                (self.calculated_moving_direction - Vector3.new(0, self.adjusted_bullet_drop, 0)) * 1.1,
                self.raycast_parameters
            )

            if not rayCast then
                return
            end
        
            self:DAMAGE_FUNCTION(rayCast.Instance)
        end,

        LOOK_AT_MOVEMENT_DIRECTION = function(self)
            self.look_direction = CFrame.lookAt(
                self.position,
                self.move_towards.LookVector * self.distance_timeout
            )
        end,

        MOVEMENT = function(self)
            self:LOOK_AT_MOVEMENT_DIRECTION()

            coroutine.resume(coroutine.create(function()
                local parts_in_part = workspace:GetPartBoundsInBox(
                    CFrame.new(self.position),
                    Vector3.new(0.5, 0.5, 0.5),
                    self.overlap_parameters
                )
        
                if table.maxn(parts_in_part) ~= 0 then
                    for _, v in pairs(parts_in_part) do
                        self.DAMAGE_FUNCTION(v)
                    end
                end
            end))

            local old_time = time()

            while game:GetService("RunService").Heartbeat:Wait() do
                local delta_time = time()-old_time
                old_time = time()

                -- Calculates the direction for the bullet to move, and then moves it in that direction
                self.calculated_moving_direction = self.move_towards.LookVector
                    * (self.speed * delta_time)
        
                self.adjusted_bullet_drop = self.bullet_drop * delta_time
        
                self.position = (self.position + self.calculated_moving_direction) - Vector3.new(0, self.adjusted_bullet_drop, 0)
        
                self:HIT_DETECTION()

                if self.to_destroy == true then
                    break
                end
        
                self.distance_moved += self.calculated_moving_direction.Magnitude -- Updates how far the bullet has moved
        
                -- If the bullet has moved further than main.DistanceTimeOut, then destroy the bullet
                if self.distance_moved >= self.distance_timeout then
                    self.to_destroy = true
                    break
                end
            end
        end,
    },
}

return bullet