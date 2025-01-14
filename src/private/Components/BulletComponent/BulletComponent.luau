local class = {}
class.interface = {}
class.schema = {}
class.metatable = { __index = class.schema }

function class.interface.New(info): Bullet
	local bullet = setmetatable({}, class.metatable)

	bullet.Information = class.schema.SetUpInformation(info)
	bullet.Variable = class.schema.VariableInformation(bullet.Information)
	bullet.RBXScriptConnections = {}
	bullet.Allies = {}

	-- Create a raycast params for hitreg
	bullet.RaycastParameters = RaycastParams.new()
	bullet.RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	bullet.RaycastParameters.RespectCanCollide = true

	bullet.OverlapParameters = OverlapParams.new()
	bullet.OverlapParameters.FilterType = Enum.RaycastFilterType.Exclude
	bullet.OverlapParameters.RespectCanCollide = true

	bullet.ListUpdate = {}

	if table.maxn(bullet.Information.IgnoreTagged) ~= 0 then
		for i, tag in pairs(bullet.Information.IgnoreTagged) do
			bullet.RaycastParameters:AddToFilter(game:GetService("CollectionService"):GetTagged(tag))
			bullet.OverlapParameters:AddToFilter(game:GetService("CollectionService"):GetTagged(tag))

			bullet.ListUpdate[i] = game:GetService("CollectionService")
				:GetInstanceAddedSignal(tag)
				:Connect(function(object: Part | Model)
					bullet.RaycastParameters:AddToFilter(object)
					bullet.OverlapParameters:AddToFilter(object)
				end)
		end
	end

	bullet.Movement(bullet)

	return bullet
end

function class.schema.SetUpInformation(info)
	local information:{ BulletDrop: number, Damage: number, DistanceTimeOut: number, Enemy : {string}, IgnoreTagged : {string}, MoveTowards : CFrame, Speed : number, Pierce : number, PierceDamageLoss : number, StartPosition : Vector3} = {
		Damage = info.Damage, -- HP
		Enemy = info.Enemy, -- Tags
		IgnoreTagged = info.IgnoreTagged, -- Tags
		MoveTowards = info.MoveTowards, -- CFrame
		BulletDrop = info.BulletDrop, -- Studs/sec
		DistanceTimeOut = info.DistanceTimeOut, -- Studs
		Speed = info.Speed, -- Studs/sec
		Pierce = info.Pierce, -- Parts
		PierceDamageLoss = info.PierceDamageLoss, -- %damage
		StartPosition = info.StartPosition, -- Vector3
	}

	return information
end

function class.schema.VariableInformation(information:{ StartPosition: Vector3 })
	local variable : {BulletDrop: number, BulletPart: nil, CalculatedMovingDirection: Vector3, DistanceMoved : number, ToDestroy : boolean, Position : Vector3, PartsPierced : {Instance}, LookDirection : CFrame} = {
		BulletPart = nil,
		DistanceMoved = 0,
		CalculatedMovingDirection = Vector3.new(),
		ToDestroy = false,
		Position = information.StartPosition,
		PartsPierced = {},
		LookDirection = CFrame.new(),
		BulletDrop = 0,
	}

	return variable
end

-- Damages a hit part
function class.schema.DamageFunction(self: Bullet, hitPart: Part): nil
	task.desynchronize()

	if table.maxn(self.Variable.PartsPierced) >= self.Information.Pierce then
		self.Variable.ToDestroy = true -- Tells the programme that it has hit more parts than the pierce limit + 1, and therefore the bullet should afterwards be destroyed
	else
		if table.maxn(self.Variable.PartsPierced) > 0 then
			self.Information.Damage = self.Information.Damage
				- (self.Information.Damage / 100 * self.Information.PierceDamageLoss)
		end
	end

	local isEnemy = false

	-- Check if the part has already been pierced through, and therefore should be ignored
	if table.find(self.Variable.PartsPierced, hitPart) then
		return
	end

	-- Detects if the hitpart or if the clostest ancestor has a tag that is affilated with the enemy
	for _, v in pairs(self.Information.Enemy) do
		if hitPart:HasTag(v) then
			isEnemy = true
		end
	end
	
	local model = hitPart:FindFirstAncestorOfClass("Model")

	if isEnemy == false then
		if model then
			for _, v in pairs(self.Information.Enemy) do
				if model:HasTag(v) then
					isEnemy = true
				end
			end
		end
	end

	-- Destroys itself if it's not an enemy
	if isEnemy == false then
		self.SafeRemoval(self)
		self.Variable.PartsPierced[table.maxn(self.Variable.PartsPierced)] = hitPart
		return
	end

	-- Attempts to find the humanoid
	local humanoid = hitPart:FindFirstChildOfClass("Humanoid")

	if humanoid == nil then
		humanoid = model:FindFirstChildOfClass("Humanoid")
	end

	-- If there's no Humanoid, destroys itself
	if not humanoid then
		self.SaveRemoval(self)
		self.Variable.PartsPierced[table.maxn(self.Variable.PartsPierced)] = hitPart
		return
	end

	local defense = hitPart:GetAttribute("Defense")

	if defense == nil then
		defense = model:GetAttribute("Defense")
	end

	if defense == nil then
		defense = 0
	end

	task.synchronize()

	humanoid:TakeDamage(self.Information.Damage - (self.Information.Damage / 100 * defense))

	self.SafeRemoval(self)
	self.Variable.PartsPierced[table.maxn(self.Variable.PartsPierced)] = hitPart

	return nil
end

-- Check if the bullet has hit a part
function class.schema.HitDetection(self: Bullet): nil
	-- Returns if the bullet has already hit something
	if self.Variable.ToDestroy == true then
		return
	end

	task.desynchronize()

	local rayCast = workspace:Raycast(
		self.Variable.Position,
		(self.Variable.CalculatedMovingDirection - Vector3.new(0, self.Variable.BulletDrop, 0)) * 1.1,
		self.RaycastParameters
	)

	if not rayCast then
		return
	end

	self.DamageFunction(self, rayCast.Instance)

	return nil
end

-- Sets the CFame to look in the direction that it should be moving towards
function class.schema.LookAtMovementDirection(self: Bullet): nil
	self.Variable.LookDirection = CFrame.lookAt(
		self.Variable.Position,
		self.Information.MoveTowards.LookVector * self.Information.DistanceTimeOut
	) * CFrame.Angles(0, math.rad(90), 0)

	return nil
end

-- A function to remove all RBXScriptConnections
function class.schema.RemoveRBXConnections(self: Bullet): nil
	task.synchronize()
	for _, v: RBXScriptConnection in pairs(self.RBXScriptConnections) do
		v:Disconnect()
	end

	return nil
end

-- A function to destroy the bullet
function class.schema.SafeRemoval(self): nil
	if self.Variable.ToDestroy == true then
		self.RemoveRBXConnections(self)
	end

	return nil
end

function class.schema.UnsafeRemoval(self): nil
	self.RemoveRBXConnections(self)

	return nil
end

-- Moves the bullet and drops it every second, also destroys the bullet if it has passed main.DistanceTimeOut
function class.schema.Movement(self: Bullet)
	self.LookAtMovementDirection(self)

	coroutine.resume(coroutine.create(function()
		local partsInPart = workspace:GetPartBoundsInBox(
			CFrame.new(self.Variable.Position),
			Vector3.new(0.5, 0.5, 0.5),
			self.OverlapParameters
		)

		if table.maxn(partsInPart) ~= 0 then
			for _, v in pairs(partsInPart) do
				self.DamageFunction(self, v)
			end
		end
	end))

	self.RBXScriptConnections.Movement = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		-- Calculates the direction for the bullet to move, and then moves it in that direction
		self.Variable.CalculatedMovingDirection = self.Information.MoveTowards.LookVector
			* (self.Information.Speed * deltaTime)

		self.Variable.BulletDrop = self.Information.BulletDrop * deltaTime

		self.Variable.Position = (self.Variable.Position + self.Variable.CalculatedMovingDirection) - Vector3.new(0, self.Information.BulletDrop * deltaTime, 0)

		-- Runs the hitreg in a coroutine
		coroutine.resume(coroutine.create(function()
			self.HitDetection(self)
		end))

		self.Variable.DistanceMoved += self.Variable.CalculatedMovingDirection.Magnitude -- Updates how far the bullet has moved

		-- If the bullet has moved further than main.DistanceTimeOut, then destroy the bullet
		if self.Variable.DistanceMoved >= self.Information.DistanceTimeOut then
			self.Variable.ToDestroy = true
			self.SafeRemoval(self)
		end
	end)
end

export type Bullet = typeof(class.interface.New(table.unpack(...)))

return class
