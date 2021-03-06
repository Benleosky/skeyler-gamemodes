---------------------------- 
--        Deathrun        -- 
-- Created by Skeyler.com -- 
---------------------------- 

include("shared.lua")
include("sv_config.lua") 
include("sh_maps.lua") 
include("sh_meta.lua") 
include("sh_library.lua") 
include("sv_gatekeeper.lua") 
include("sv_lasers.lua")
include("player_class/player_deathrun.lua")

AddCSLuaFile("shared.lua") 
AddCSLuaFile("sh_maps.lua") 
AddCSLuaFile("sh_meta.lua") 
AddCSLuaFile("sh_library.lua") 
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("player_class/player_deathrun.lua")

SS.SetupGamemode("deathrun", true) 

function GM:InitPostEntity() 
	self.BaseClass:InitPostEntity() 
	self.FirstRoundTime = CurTime()+10
	timer.Simple(11, function() self:CanRoundStart() end) 
end 

function GM:PlayerInitialSpawn(ply) 
	self.BaseClass:PlayerInitialSpawn(ply) 
	ply:SetTeam(TEAM_DEAD) 
	ply:Spawn() 
	self:CanRoundStart() 

	if (self.FirstRoundTime-CurTime())>0 then 
		ply:ChatPrint("Waiting "..tostring(math.ceil(self.FirstRoundTime-CurTime())).." seconds for players to spawn.") 
	end 
end 

function GM:PlayerSpawn(ply) 
	if ply:Alive() then 
		self.BaseClass:PlayerSpawn(ply) 

		player_manager.SetPlayerClass(ply, "player_deathrun")
		player_manager.OnPlayerSpawn(ply) 
		player_manager.RunClass(ply, "Spawn") 
		player_manager.RunClass(ply, "Loadout")
	else 
		self:PlayerSpawnAsSpectator(ply) 
	end 
end 

function GM:IsSpawnpointSuitable(ply, spawnpointent, bMakeSuitable) 
	-- Don't kill people please...
	return true 
end 

function GM:PlayerDisconnected(ply) 
	self.BaseClass:PlayerDisconnected(ply) 
	timer.Simple(0.1, function() self:CheckRoundOver() end) -- Wait until they are gone.
end 

function GM:PlayerShouldTakeDamage(ply, attacker) 
	if ply and ply.Team and attacker and attacker.Team and ply:Team() == attacker:Team() then 
		return false 
	end 
	return self.BaseClass:PlayerShouldTakeDamage(ply, attacker) 
end 

local fatal = 1100
local maxsafe = 580
local damage = 100/(fatal-maxsafe) --do not change these, they are direct css rips ;_;

--note I am doing this to hopefully save a little calc on fall damage :P

function GM:GetFallDamage( ply, speed )
	return math.max((speed - maxsafe)*damage*1.25,0)
end

function GM:DoPlayerDeath(victim, attacker, dmg) 
	victim:SetTeam(TEAM_DEAD) 
	self.BaseClass:DoPlayerDeath(victim, attacker, dmg) 
	self:CheckRoundOver() 
end 

function GM:ShowTeam(ply) 
	if ply:Team() == TEAM_SPEC then 
		ply:SetTeam(TEAM_DEAD) 
		ply:ChatPrint("You will spawn on the next round.") 
	end 
end 

function GM:NewDeaths(anydeath, deathcount) 
	local deathcount = deathcount or 0
	for k,v in rpairs(GetFilteredPlayers({TEAM_DEAD, TEAM_RUNNER})) do 

		-- We have enough deaths
		if deathcount >=4 or deathcount*7 > (#GetFilteredPlayers({TEAM_DEAD, TEAM_RUNNER})-deathcount) then 
			break 
		end 

		-- Don't be a death twice please
		if !v.WasDeath or anydeath  then 
			v.IsDeath = true 
			deathcount = deathcount + 1
		end 
	end 
end 

function GM:CheckRoundOver() 
	if self:CheckPlayers() then 
		if self.Restarting then return end 
		local runners = GetFilteredPlayers({TEAM_RUNNER}) 
		local deaths = GetFilteredPlayers({TEAM_DEATH}) 
		if #runners <= 0 then 
			ChatPrintAll("The deaths have triumphed!  Starting new round.") 
			self.Started = false 
		elseif #deaths <= 0 then 
			ChatPrintAll("The runners have prevailed!  Starting new round.") 
			self.Started = false 
		end 
	else 
		self.Started = false 
	end 
	self:CanRoundStart() 
end 

function GM:CanRoundStart() 
	if !self.Started and (self.FirstRoundTime-CurTime())<=0 then 
		if self:CheckPlayers() then 
			self:RoundRestart() 
			self.Started = true 
		else 
			ChatPrintAll("Not enough players to start another round... waiting.") 
			self.Started = false 
			self.Restarting = false 
			timer.Destroy("SS_RoundReset") 
		end 
	end 
	return false 
end 

function GM:RoundStart() 
	self.Restarting = false 
	self.Started = true 

	for k,v in pairs(ents.FindByClass("weapon_*")) do
		if(v and v:IsValid()) then
			v:Remove()
		end
	end
	for k,v in pairs(ents.FindByClass("prop_ragdoll")) do
		if(v and v:IsValid()) then
			v:Remove()
		end
	end

	game.CleanUpMap() 

	for k,v in pairs(player.GetAll()) do 
		if v:Team() == TEAM_SPEC then continue end 
		if v.IsDeath then 
			v:SetTeam(TEAM_DEATH) 
			v:ChatPrint("You've randomly been selected to be a death!") 
		elseif v:Team() == TEAM_RUNNER or v:Team() == TEAM_DEAD or v:Team() == TEAM_DEATH then 
			v:SetTeam(TEAM_RUNNER) 
		else 
			v:Kick("Idk how the fuck you got on an invalid team!") 
			return 
		end 
		v:Spawn() 
	end 
end 

function GM:RoundRestart() 
	self.Restarting = true 
	self.Started = true 

	ChatPrintAll("A new round will start in 5 seconds.") 

	timer.Create("SS_RoundReset", 5, 1, function() 
		if self:CheckPlayers() then 
			local nodeathcount = 0
			for k,v in pairs(player.GetAll()) do 
				if v.IsDeath then 
					v.WasDeath = true 
					v.IsDeath = false 
					nodeathcount = nodeathcount + 1 -- Make sure we aren't filtering everyone out.
				elseif v.WasDeath then 
					v.WasDeath = false 
				end 
			end 
			self:NewDeaths((nodeathcount >= #player.GetAll() and true or false), 0)
			self:RoundStart() 
		else 
			self.Started = false 
			self:CheckRoundOver() 
		end 
	end ) 
end 

-- Check to make sure we have enough players to actually play
function GM:CheckPlayers() 
	return (table.Count(GetFilteredPlayers({TEAM_DEAD, TEAM_RUNNER, TEAM_DEATH})) >= 2)
end 

function GM:PlayerCanPickupWeapon( ply, wep ) 
	if !wep or !wep:IsValid() then return false end 
	if ply:HasWeapon(wep:GetClass()) then return false end 
	ply:SetAmmo(999, wep:GetPrimaryAmmoType()) 
	ply:SelectWeapon(wep:GetClass()) 
	return true
end 

function GM:PlayerDeathSound() 
	return true  
end 

local freeze = {}
local reps = 0

local function freezethem()
	if(reps == 20) then
		hook.Remove("Think","SS_FreezeWeps")
		freeze = {}
	end
	for k,v in pairs(freeze) do
		local py = v:GetPhysicsObject()
		if(py && py:IsValid()) then
			py:Sleep()
		end
	end
	reps = reps + 1
end

hook.Add("InitPostEntity","SS_FindWeaponsToFreeze",function()
	for k,v in pairs(ents.FindByClass("weapon_*")) do
		table.insert(freeze,v)
	end
	hook.Add("Think","SS_FreezeWeps",freezethem)
end)

hook.Add("PreCleanupMap","SS_PreWeaponFreeze",function()
	hook.Remove("Think","SS_FreezeWeps")
	freeze = {}
end)

hook.Add("PostCleanupMap","SS_PostWeaponFreeze",function()
	for k,v in pairs(ents.FindByClass("weapon_*")) do
		table.insert(freeze,v)
	end
	hook.Add("Think","FreezeWeps",freezethem)
end)