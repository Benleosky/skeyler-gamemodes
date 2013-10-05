---------------------------
--       Bunny Hop       -- 
-- Created by xAaron113x --
---------------------------


include("shared.lua")
include("sv_config.lua")
include("sh_levels.lua") 
include("sh_maps.lua") 
include("sh_viewoffsets.lua") 
include("player_class/player_bhop.lua")

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_difficulty_menu.lua") 
AddCSLuaFile("sh_levels.lua") 
AddCSLuaFile("sh_viewoffsets.lua") 

GM.PSaveData = {} -- Save last known positions and angles for respawn here.

/* Setup the bhop spawn and finish */
function GM:AreaSetup() 
	local MapData = self.MapList[game.GetMap()] 
	if MapData then -- We will assume the rest is valid
		self.MapSpawn = ents.Create("bhop_area")
		self.MapSpawn:SetPos(MapData.spawnarea.max-(MapData.spawnarea.max-MapData.spawnarea.min)/2) 
		self.MapSpawn:Setup(MapData.spawnarea.min, MapData.spawnarea.max, true) 
		self.MapSpawn:Spawn()

		self.MapFinish = ents.Create("bhop_area") 
		self.MapFinish:SetPos(MapData.finisharea.max-(MapData.finisharea.max-MapData.finisharea.min)/2) 
		self.MapFinish:Setup(MapData.finisharea.min, MapData.finisharea.max) 
		self.MapFinish:Spawn() 

		for k,v in pairs(self.SpawnPoints) do 
			v:SetPos(MapData.spawnpos) 
			v:SetAngles(MapData.spawnang) 
		end 
	end 
end 

function GM:LevelSetup(ply, Level)
print(Level)  
	if !Level or !isnumber(Level) or !self.Levels[Level] then return end 

	ply:SetNetworkedInt("ssbhop_level", Level) 
	ply.LevelData = self.Levels[Level] 

	if !ply.LevelData then return end 

	ply:SetGravity(ply.LevelData.gravity) 
	ply.StayTime = ply.LevelData.staytime 
	ply.award = ply.LevelData.award 

	ply:ChatPrint("Your difficulty is ".. ply.LevelData.name ..".") 

	if ply:Team() == TEAM_BHOP then 
		ply:ResetTimer() 
		ply.Winner = false 
	end  
	ply:SetTeam(TEAM_BHOP) 
	ply:Spawn() 
end 
concommand.Add("level_select", function(ply, cmd, args) GAMEMODE:LevelSetup(ply, tonumber(args[1])) end)

function GM:ShowTeam(ply) 
	if ply:Team() != TEAM_BHOP and ply:HasTimer() then -- Just resume if they already played.
		self:LevelSetup(ply, self.PSaveData[ply:SteamID()].Level)
	else 
		ply:ConCommand("open_difficulties") 
	end 
end 

function GM:PlayerSpawn(ply)
	if ply:IsBot() then ply:SetTeam(TEAM_BHOP) end -- always spawn bots

	if ply:Team() == TEAM_BHOP then  
		ply:UnSpectate()
		
		player_manager.SetPlayerClass( ply, "player_bhop" )
	
		self.BaseClass:PlayerSpawn( ply )
		
		hook.Call( "PlayerSetModel", GAMEMODE, ply )
		
		ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 62))
		ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 45))
		

		if ply:IsSuperAdmin() then 
			ply:Give("ss_mapeditor") 
		end 

		if !ply.LevelData then
			self:LevelSetup(ply,2) --default level
		end
			
		if ply:HasTimer() and self.PSaveData[ply:SteamID()] then 
			ply.AreaIgnore = true 
			local PosInfo = self.PSaveData[ply:SteamID()] 
			ply:SetPos(PosInfo.LastPosition) 
			ply:SetEyeAngles(PosInfo.LastAngle) 
			ply:StartTimer() 
			ply.AreaIgnore = false
		elseif !ply.InSpawn then 
			ply:StartTimer() 
		end 
	else 
		ply:SetTeam(TEAM_SPECTATOR)
		ply:Spectate(OBS_MODE_ROAMING)
	end 
end 

function GM:PlayerDisconnected(ply) 
	ply:PauseTimer() 
end 

function GM:PlayerShouldTakeDamage(ply, attacker) 
	return false 
end 

function GM:IsSpawnpointSuitable() -- Overwrite so we don't run into death problems
	return true 
end 

/* Setup the teleports, platforms, spawns, and finish lines */
function GM:InitPostEntity() 
	if !self.MapList[game.GetMap()].ignoredoors then
		print('hi')
		for k,v in pairs(ents.FindByClass("func_door")) do
			if(!v.IsP) then continue end
			local mins = v:OBBMins()
			local maxs = v:OBBMaxs()
			local h = maxs.z - mins.z
			if(h > 80 && game.GetMap() != "bhop_monster_jam") then continue end
			local tab = ents.FindInBox( v:LocalToWorld(mins)-Vector(0,0,10), v:LocalToWorld(maxs)+Vector(0,0,5) )
			if(tab) then
				for _,v2 in pairs(tab) do if(v2 && v2:IsValid() && v2:GetClass() == "trigger_teleport") then tele = v2 end end
				if(tele) then
					v:Fire("Lock")
					v:SetKeyValue("spawnflags","1024")
					v:SetKeyValue("speed","0")
					v:SetRenderMode(RENDERMODE_TRANSALPHA)
					if(v.BHS) then
						v:SetKeyValue("locked_sound",v.BHS)
					else
						v:SetKeyValue("locked_sound","DoorSound.DefaultMove")
					end
					v:SetNWInt("Platform",1)
				end
			end
		end
	
		for k,v in pairs(ents.FindByClass("func_button")) do
			if(!v.IsP) then continue end
			if(v.SpawnFlags == "256") then 
				local mins = v:OBBMins()
				local maxs = v:OBBMaxs()
				local tab = ents.FindInBox( v:LocalToWorld(mins)-Vector(0,0,10), v:LocalToWorld(maxs)+Vector(0,0,5) )
				if(tab) then
					for _,v2 in pairs(tab) do if(v2 && v2:IsValid() && v2:GetClass() == "trigger_teleport") then tele = v2 end end
					if(tele) then
						v:Fire("Lock")
						v:SetKeyValue("spawnflags","257")
						v:SetKeyValue("speed","0")
						v:SetRenderMode(RENDERMODE_TRANSALPHA)
						if(v.BHS) then
							v:SetKeyValue("locked_sound",v.BHS)
						else
							v:SetKeyValue("locked_sound","None (Silent)")
						end
						v:SetNWInt("Platform",1)
					end
				end
			end
		end
	end
	
	self:AreaSetup()
end 

function GM:PlayerFootstep(ply)
	if ply:Alive() then -- If alive, assume we save positions
		if !self.PSaveData[ply:SteamID()] then self.PSaveData[ply:SteamID()] = {} end 
		self.PSaveData[ply:SteamID()].LastPosition = ply:GetPos() 
		self.PSaveData[ply:SteamID()].LastAngle = ply:GetAngles() 
		self.PSaveData[ply:SteamID()].Level = ply:GetNetworkedInt("ssbhop_level", 0) 
	end 
end

function GM:PlayerWon(ply) 
	ply:EndTimer()
	ply.Winner = true 
	ply:ChatPrintAll("You have won in ".. FormatTime(ply:GetTotalTime(true)))
	ply:GiveMoney(ply.award)
end 