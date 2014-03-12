MINIGAME.Time = 60

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:Initialize()
	self.BaseClass.Initialize(self)
	
	local entity = ents.FindByClass("info_minigame_headsup")[1]

	if (IsValid(entity)) then
		local position = entity:GetPos()
		local min, max = Vector(-472, -472, 0), Vector(472, 472, 0)
		
		self.spawnOrigin = {position, min, max}
	end
end

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:Start()
	print(self.Name .. " has started.")
	
	self.BaseClass.Start(self)
	
	self.nextDrop = CurTime() +1
	self.bombVelocity = 0.1
end

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:Finish(timeLimit)
	self.BaseClass.Finish(self, timeLimit)
	
	print(self.Name .. " has finished.")
end

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:HasRequirements(players, teams)
	return teams > 1
end

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:Think()
	if (self.nextDrop <= CurTime() and self.spawnOrigin) then
		local data = self.spawnOrigin
		
		self.bombVelocity = math.Clamp(self.bombVelocity -0.5, -15, 0)
	
		for k, player in pairs(self.players) do
			if (IsValid(player)) then
				local position = player:GetPos()
				
				position = position +Vector(0, 0, data[1].z)
				
				local entity = ents.Create("info_minigame_bomb")
				entity:SetPos(position)
				entity:Spawn()
	
				timer.Simple(0, function()
					local physicsObject = entity:GetPhysicsObject()
			
					if (IsValid(physicsObject)) then
						physicsObject:SetVelocity(Vector(0, 0, self.bombVelocity))
					end
				end)
			end
		end
		
		for i = 1, math.random(4, 8) do
			local position = Vector(data[1].x +math.random(data[2].x, data[3].x), data[1].y +math.random(data[2].y, data[3].y), data[1].z)
			
			local entity = ents.Create("info_minigame_bomb")
			entity:SetPos(position)
			entity:Spawn()

			timer.Simple(0, function()
				local physicsObject = entity:GetPhysicsObject()
		
				if (IsValid(physicsObject)) then
					physicsObject:SetVelocity(Vector(0, 0, self.bombVelocity))
				end
			end)
		end
		
		self.nextDrop = CurTime() +5
	end
end

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:DoPlayerDeath(victim, inflictor, dmginfo)
	timer.Simple(0, function()
		self:RemovePlayer(victim)

		local won = self:AnnounceWin()
		
		if (won) then
			self:Finish()
		end
	end)
end

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:CanPlayerSuicide(player)
	return false
end