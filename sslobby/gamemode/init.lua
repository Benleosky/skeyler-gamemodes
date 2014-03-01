AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_scoreboard.lua") 

AddCSLuaFile("modules/sh_link.lua")
AddCSLuaFile("modules/cl_link.lua")
AddCSLuaFile("modules/sh_chairs.lua")
AddCSLuaFile("modules/cl_chairs.lua")
AddCSLuaFile("modules/cl_worldpicker.lua")
AddCSLuaFile("modules/sh_minigame.lua")
AddCSLuaFile("modules/cl_minigame.lua")
AddCSLuaFile("modules/cl_worldpanel.lua")
AddCSLuaFile("modules/sh_leaderboard.lua")
AddCSLuaFile("modules/cl_leaderboard.lua")

include("shared.lua")
include("player_class/player_lobby.lua")

include("modules/sv_socket.lua")
include("modules/sh_link.lua")
include("modules/sv_link.lua")
include("modules/sh_chairs.lua")
include("modules/sv_chairs.lua")
include("modules/sv_worldpicker.lua")
include("modules/sh_minigame.lua")
include("modules/sv_minigame.lua")
include("modules/sh_leaderboard.lua")
include("modules/sv_leaderboard.lua")

--------------------------------------------------
--
--------------------------------------------------

function GM:InitPostEntity()
	self.spawnPoints = {lounge = {}}
	
	local spawns = ents.FindByClass("info_player_spawn")
	
	for k, entity in pairs(spawns) do
		if (entity.lounge) then
			table.insert(self.spawnPoints.lounge, entity)
		elseif (entity.minigames) then
		else
			table.insert(self.spawnPoints, entity)
		end
	end
	
--[[	self.EnterSpawns = {}
	self.SpawnPoints = {}
	
	for k,v in pairs(ents.FindByClass("info_player_spawn")) do
		if(v.lounge) then
			table.insert(self.EnterSpawns, v)
		elseif v.gamemode and MINIGAMES then
			for k2, v2 in pairs( v.gamemode ) do
				if( MINIGAMES[v2] && MINIGAMES[v2].spawns ) then
					table.insert( MINIGAMES[v2].spawns, v)
				end
			end
		else
			table.insert(self.SpawnPoints, v)
		end
	end
	
	for k,v in pairs(ents.FindByClass("info_lounge")) do
		self.LoungeOrigin = v
		break
	end
	
	
	if(self.InitVendors) then
		self:InitVendors()
		self:SetupVendors()
	end
	
	]]
	
	--local pokerTable = ents.Create("poker_table")
--	pokerTable:SetPos(Vector(-1193.461914, -9.690007, 176.031250))
	--pokerTable:SetAngles(Angle(0, 89.546 *2, 0.000))
	--pokerTable:Spawn()
	
	local slotMachines = ents.FindByClass("prop_physics_multiplayer")
	
	for k, entity in pairs(slotMachines) do
		if (IsValid(entity)) then
			local model = string.lower(entity:GetModel())
			
			if (model == "models/sam/slotmachine.mdl") then
				local position, angles = entity:GetPos(), entity:GetAngles()
				
				local slotMachine = ents.Create("slot_machine")
				slotMachine:SetPos(position)
				slotMachine:SetAngles(angles)
				slotMachine:Spawn()
				
				entity:Remove()
			end
		end
	end
end

--------------------------------------------------
--
--------------------------------------------------

function GM:PlayerInitialSpawn(player)
	self.BaseClass:PlayerInitialSpawn(player)
	
	player:SetTeam(TEAM_READY)
	
	timer.Simple(0.1,function()
		for i = LEADERBOARD_DAILY, LEADERBOARD_ALLTIME_10 do
			SS.Lobby.LeaderBoard.Network(i, player)
		end
	end)
end

--------------------------------------------------
--
--------------------------------------------------

function GM:PlayerSpawn(player)
	self.BaseClass:PlayerSpawn(player)
	
	--self:InitSpeed(ply)
	-- ply:SetRunSpeed(300)
	-- ply:SetWalkSpeed(300)
	
	player:SetJumpPower(205)
end

--------------------------------------------------
--
--------------------------------------------------

function GM:PlayerSelectSpawn(player)
	local spawnPoint = self.spawnPoints.lounge
	
	if (player:Team() > TEAM_READY) then
		spawnPoint = self.spawnPoints
	end
	
	for i = 1, #spawnPoint do
		local entity = spawnPoint[i]
		local suitAble = self:IsSpawnpointSuitable(player, entity, i == #spawnPoint)
		
		if (suitAble) then
			return entity
		end
	end
	
	spawnPoint = table.Random(spawnPoint)
	
	return spawnPoint
end