---------------------------- 
--         SSBase         -- 
-- Created by Skeyler.com -- 
---------------------------- 

DB_DEVS = false 

if (game.IsDedicated()) then
	DB_HOST = "127.0.0.1"
	DB_USER = "root"
	DB_PASS = "4a5ruxeMatRAhERe"
else
	DB_HOST = "127.0.0.1"
	DB_USER = "root"
	DB_PASS = ""
end

resource.AddWorkshop("239292201")

resource.AddFile("resource/fonts/arvilsans0.ttf") 

resource.AddFile("resource/fonts/helveticaltstdboldcond.ttf") 
resource.AddFile("resource/fonts/helveticaltstdlight.ttf") 

AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_library.lua")
AddCSLuaFile("sh_profiles.lua") 
AddCSLuaFile("sh_store.lua") 
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua") 
AddCSLuaFile("cl_chatbox.lua") 
AddCSLuaFile("cl_store.lua") 
AddCSLuaFile("cl_scoreboard.lua") 
AddCSLuaFile("cl_vote.lua") 

AddCSLuaFile("panels/ss_slot.lua")
AddCSLuaFile("panels/ss_slider.lua")
AddCSLuaFile("panels/ss_tooltip.lua")
AddCSLuaFile("panels/ss_checkbox.lua")
AddCSLuaFile("panels/ss_notify.lua")

include("player_class/player_ssbase.lua")

-- I need this before everything else loads
function ChatPrintAll(msg)
	if !msg or string.Trim(msg) == "" then return end 

	for k,v in pairs(player.GetAll()) do 
		v:ChatPrint(msg) 
	end 
end

include("shared.lua")
include("sh_library.lua")  
include("sv_database.lua")
include("sh_profiles.lua") 
include("sv_profiles.lua") 
include("sv_timer.lua")
include("sv_commands.lua")
include("sh_maps.lua")
include("sv_maps.lua")
include("sv_vote.lua") 
include("sv_votemap.lua") 
include("sh_store.lua") 
include("sv_store.lua") 

if (!game.IsDedicated()) then
	include("sv_gatekeeper.lua") 
end

if !file.IsDir("ss", "DATA") then file.CreateDir("ss") end 

-- Call this after you've loaded your map file
function SS.SetupGamemode(name, b_loadmaps)  
	if !name then Error("SetupGamemode requires a name") return end 

	if !file.IsDir("ss/"..name, "DATA") then file.CreateDir("ss/"..name) end 
	if !file.IsDir("ss/"..name.."/logs", "DATA") then file.CreateDir("ss/"..name.."/logs") end 

	SS.ServerDir = "ss/"..name.."/" 

	if b_loadmaps then 
		SS:LoadMaps() 
		votemap.Init()
	end 
end 

 
function PLAYER_META:ChatPrintAll(msg) 
	ChatPrintAll(msg)
 end 
 
function GM:PlayerInitialSpawn(ply) 
	ply:ProfileLoad() 
	ply:CheckFake()

	ply:SetTeam(TEAM_SPEC) 

	ply.SpecMode = OBS_MODE_CHASE 
	ply.SpecID = 1
	ply.roam = false
	ply.chase = true

	ply:SendLua("ResolutionCheck()") 
end 

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_ssbase")
	
	self.BaseClass:PlayerSpawn(ply)
end 

function GM:PlayerSetModel(player)
	self.BaseClass:PlayerSetModel(player)

	if (player.storeEquipped) then
		local model = player:GetSlotData(SS.STORE.SLOT.MODEL)
		
		if (model) then
			model = SS.STORE.Items[model.unique]
			
			if (model) then
				player:SetModel(model.Model)
			end
		end
	end
end

function GM:GetPlayers(b_alive, filter)  
	local players = player.GetAll() 
	local Return = {} 
	for k,v in pairs(players) do 
		if v:Alive() and b_alive then 
			if (filter and !table.HasValue(filter, v)) or !filter then 
				table.insert(Return, v) 
			end 
		elseif !b_alive then
			if (filter and !table.HasValue(filter, v)) or !filter then 
				table.insert(Return, v) 
			end 
		end 
	end 
	return Return 
end 

function GM:SpectateNext(ply) 
	local players = self:GetPlayers(true,{ply})
	if(#players == 1) then
		if(ply.SpecID != 1) then
			ply.SpecID = 1
			ply:SpectateEntity(players[ply.SpecID])
		end
		return
	end
	ply.SpecID = ply.SpecID + 1
	if(ply.SpecID>#players)then
		ply.SpecID = 1
	end
	ply:SpectateEntity(players[ply.SpecID])
end 

function GM:SpectatePrev(ply) 
	local players = self:GetPlayers(true,{ply})
	if(#players == 1) then
		if(ply.SpecID != 1) then
			ply.SpecID = 1
			ply:SpectateEntity(players[ply.SpecID])
		end
		return
	end
	ply.SpecID = ply.SpecID - 1
	if(ply.SpecID<1)then
		ply.SpecID = #players
	end
	ply:SpectateEntity(players[ply.SpecID])
end 

function GM:ChangeSpecMode(ply)
	if(ply.chase) then
		ply.SpecMode = OBS_MODE_IN_EYE
		ply.chase = false
	else
		ply.SpecMode = OBS_MODE_CHASE
		ply.chase = true
	end
	ply:SetObserverMode(ply.SpecMode)
end

function GM:ToggleRoam(ply)
	if(ply.roam) then
		if(ply.chase) then
			ply.SpecMode = OBS_MODE_CHASE
		else
			ply.SpecMode = OBS_MODE_IN_EYE
		end
		ply.roam = false
	else
		ply.SpecMode = OBS_MODE_ROAMING
		ply.roam = true
	end
	ply:Spectate(ply.SpecMode)
end

hook.Add("KeyPress", "SpectateModeChange", function(ply, key) 
	if ply:Team() == TEAM_SPEC then 
		if !ply.roam && key == IN_ATTACK then 
			GAMEMODE:SpectateNext(ply)
		elseif !ply.roam && key == IN_ATTACK2 then 
			GAMEMODE:SpectatePrev(ply)
		elseif !ply.roam && key == IN_JUMP then 
			GAMEMODE:ChangeSpecMode(ply)
		elseif key == IN_RELOAD then 
			GAMEMODE:ToggleRoam(ply)
		end
	end 
end )

function GM:PlayerSay( ply, text, public )
	local t = text

	if (string.sub(t, 0, 1) == "/") then
		SS.ToConCommand(ply, t)
		return ""
	end
	
	local t = string.lower( text )
	
	if(t == "!spec" || t == "!spectate") then
		if(ply:Team() == TEAM_SPEC) then
			ply:ChatPrint("You are already a spectator")
			return ""
		end
		ply:SetTeam(TEAM_SPEC)
		ply:Spawn()
		return ""
	end

	if ply:IsSSMuted() then
		return ""
	end

	return self.BaseClass:PlayerSay(ply,text,public)
end

function GM:PlayerDisconnected(ply) 
	ply:ProfileSave() 
end 

function GM:AllowPlayerPickup( ply, object )
	if ply:IsSuperAdmin() then return true end 
	return false 
end 

function GM:ShowHelp(ply) 
	ply:ConCommand("ss_store") 
end 

function GM:ShowTeam(ply) 
end 

function GM:ShowSpare(ply) 
end 

function GM:ShowSpare2(ply) 
end 

function GM:PlayerNoClip(ply) 
	return ply:GetRank() >= 70 
end 

/* Get a list of SpawnPoints */
hook.Add("InitPostEntity", "SpawnPoints", function() 
	local self = GAMEMODE
	if ( !IsTableOfEntitiesValid( self.SpawnPoints ) ) then
		self.LastSpawnPoint = 0
		self.SpawnPoints = ents.FindByClass( "info_player_start" )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_deathmatch" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_combine" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_rebel" ) )
		
		-- CS Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_counterterrorist" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_terrorist" ) )
		
		-- DOD Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_axis" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_allies" ) )

		-- (Old) GMod Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "gmod_player_start" ) )
		
		-- TF Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_teamspawn" ) )
		
		-- INS Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "ins_spawnpoint" ) )  

		-- AOC Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "aoc_spawnpoint" ) )

		-- Dystopia Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "dys_spawn_point" ) )

		-- PVKII Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_pirate" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_viking" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_knight" ) )

		-- DIPRIP Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "diprip_start_team_blue" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "diprip_start_team_red" ) )
 
		-- OB Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_red" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_blue" ) )        
 
		-- SYN Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_coop" ) )
 
		-- ZPS Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_human" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_zombie" ) )      
 
		-- ZM Maps
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_deathmatch" ) )
		self.SpawnPoints = table.Add( self.SpawnPoints, ents.FindByClass( "info_player_zombiemaster" ) ) 

	end
end )

function GM:EntityKeyValue( ent, key, value )
	 
	if !GAMEMODE.BaseStoreOutput or !GAMEMODE.BaseTriggerOutput then
	 
		local e = scripted_ents.Get( "base_entity" )
		GAMEMODE.BaseStoreOutput = e.StoreOutput
		GAMEMODE.BaseTriggerOutput = e.TriggerOutput
		 
	end
 
	if key:lower():sub( 1, 2 ) == "on" then
		 
		if !ent.StoreOutput or !ent.TriggerOutput then -- probably an engine entity
		 
			ent.StoreOutput = GAMEMODE.BaseStoreOutput
			ent.TriggerOutput = GAMEMODE.BaseTriggerOutput
			
		end
		
		if ent.StoreOutput then
				 
			ent:StoreOutput( key, value )
				 
		end
		 
	end
	 
end
