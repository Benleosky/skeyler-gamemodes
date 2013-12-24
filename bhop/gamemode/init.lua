	---------------------------
--       Bunny Hop       -- 
-- Created by xAaron113x --
---------------------------


include("shared.lua")
include("sv_config.lua")
include("sv_jumpstats.lua")
include("sh_levels.lua") 
include("sh_styles.lua") 
include("sh_maps.lua") 
include("sh_viewoffsets.lua") 
include("player_class/player_bhop.lua")

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_difficulty_menu.lua") 
AddCSLuaFile("sh_levels.lua") 
AddCSLuaFile("sh_styles.lua") 
AddCSLuaFile("sh_viewoffsets.lua") 

util.AddNetworkString("WriteRT")
util.AddNetworkString("ModifyRT")

GM.PSaveData = {} -- Save last known positions and angles for respawn here.
GM.ACAreas = {}
GM.RecordTable = {}
for k,_ in pairs(GM.Levels) do
	GM.RecordTable[k] = {}
	for k2,_ in pairs(GM.Styles) do
		GM.RecordTable[k][k2] = {}
	end
end

function GM:Initialize()
	DB_Query("SELECT id FROM bh_mapids WHERE mapname='"..game.GetMap().."'", 
	function(data)
		if(data && data[1]) then
			self.CurrentID = data[1]["id"]
			self:LoadRecs()
		elseif(data && !data[1]) then
			DB_Query("INSERT INTO bh_mapids (mapname) VALUES ('"..game.GetMap().."')",
			function()
				DB_Query("SELECT id FROM bh_mapids WHERE mapname='"..game.GetMap().."'", 
				function(data)
					if(data && data[1]) then
						self.CurrentID = data[1]["id"]
						self:LoadRecs()
					end
				end)
			end)
		end
	end, 
	function() 
		--lets retry that one more time
		timer.Simple(4, function()
			DB_Query("SELECT id FROM bh_mapids WHERE mapname='"..game.GetMap().."'", 
			function(data)
				if(data && data[1]) then
					self.CurrentID = data[1]["id"]
					self:LoadRecs()
				elseif(data && !data[1]) then
					DB_Query("INSERT INTO bh_mapids (mapname) VALUES ('"..game.GetMap().."')",
						function()
						DB_Query("SELECT id FROM bh_mapids WHERE mapname='"..game.GetMap().."'", 
						function(data)
							if(data && data[1]) then
								self.CurrentID = data[1]["id"]
								self:LoadRecs()
							end
						end)
					end)
				end
			end)
		end)
	end)
	self.BaseClass:Initialize()
end

/* Setup the bhop spawn and finish */
function GM:AreaSetup() 
	local MapData = SS.MapList[game.GetMap()] 
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

function GM:AddACArea(min,max,message)
	local m = ""
	if(!message) then
		m = "You have attempted to exploit the map and as such your time has been stopped."
	else
		m = message
	end
	table.insert(GAMEMODE.ACAreas,{min,max,m})
end

function GM:LevelSetup(ply, Level)
	if !Level or !isnumber(Level) or !self.Levels[Level] then return end 

	ply:SetNetworkedInt("ssbhop_level", Level) 
	ply.LevelData = self.Levels[Level] 

	if !ply.LevelData then return end 

	ply:SetGravity(ply.LevelData.gravity) 
	ply.StayTime = ply.LevelData.staytime 
	print(game.GetMap())
	ply.Payout = SS.MapList[game.GetMap()] and SS.MapList[game.GetMap()].payout or 100

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

function GM:PlayerSay( ply, text, public )
	local t = string.lower( text )
	
	for k,v in pairs(self.Styles) do
		if(t == v.cmd) then
			ply.Style = k
			ply:SetNWInt("Style",k)
			ply:ChatPrint("Changed to "..v.name..".")
			if(ply:IsTimerRunning() || ply.Winner) then
				if ply:Team() == TEAM_BHOP then 
					ply:ResetTimer() 
					ply.Winner = false 
				end  
				ply:SetTeam(TEAM_BHOP) 
				ply:Spawn() 
			end
			return ""
		end
	end
	
	if(t == "!r") then
		if ply:Team() == TEAM_BHOP then 
			ply:ResetTimer() 
			ply.Winner = false 
		end  
		ply:SetTeam(TEAM_BHOP) 
		ply:Spawn() 
		return ""
	end
	
	return self.BaseClass:PlayerSay(ply,text,public)
end

function GM:LoadRecs()
	DB_Query("SELECT name,level,style,time,steamid FROM bh_records WHERE mapid='"..self.CurrentID.."' AND pb='1' ORDER BY time",
	function(data)
		if(data) then
			for _,v in pairs(data) do
				table.insert(self.RecordTable[tonumber(v["level"])][tonumber(v["style"])],{["name"] = v["name"],["steamid"] = v["steamid"],["time"] = v["time"]})
			end
		end
	end)
end

function PLAYER_META:LoadPBs()
	self.PBS = {}
	for k,_ in pairs(GAMEMODE.Levels) do
		self.PBS[k] = {}
		for k2,_ in pairs(GAMEMODE.Styles) do
			self.PBS[k][k2] = 0
		end
	end
	for k,v in pairs(GAMEMODE.RecordTable) do
		for k2,v2 in pairs(v) do
			for _,rec in pairs(v2) do
				if(rec["steamid"] == string.sub(self:SteamID(),7)) then
					self.PBS[k][k2] = rec["time"]
				end
			end
		end
	end
	net.Start("WriteRT")
	net.WriteTable(GAMEMODE.RecordTable)
	net.Send(self)
end

function GM:PlayerInitialSpawn(ply) 
	if(self.CurrentID) then
		ply:LoadPBs()
	else
		timer.Simple(4, function()
			if(self.CurrentID) then
				ply:LoadPBs()
			end
		end)
	end
	self.BaseClass:PlayerInitialSpawn(ply)
end

function GM:PlayerSpawn(ply)
	if ply:IsBot() then ply:SetTeam(TEAM_BHOP) end -- always spawn bots

	if ply:Team() == TEAM_BHOP then  
		ply:UnSpectate()
		
		player_manager.SetPlayerClass( ply, "player_bhop" )
	
		self.BaseClass:PlayerSpawn( ply )

		player_manager.OnPlayerSpawn( ply )
		player_manager.RunClass( ply, "Spawn" )
		
		hook.Call( "PlayerSetModel", GAMEMODE, ply )
		
		ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 62))
		ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 45))
		
		if !ply.Style then
			ply.Style = 1 --normal style
			ply:SetNWInt("Style",1)
		end

		if ply:IsSuperAdmin() then 
			ply:Give("ss_mapeditor") 
		end 

		if(!ply:IsBot()) then
			if !ply.LevelData then
				self:LevelSetup(ply,2) --default level
			end
		
			ply:SetPB(tonumber(ply.PBS[ply.LevelData.id][ply.Style]))
			
			if ply:HasTimer() and self.PSaveData[ply:SteamID()] then 
				ply.AreaIgnore = true 
				local PosInfo = self.PSaveData[ply:SteamID()] 
				ply:SetPos(PosInfo.LastPosition) 
				ply:SetEyeAngles(PosInfo.LastAngle) 
				ply:StartTimer() 
				ply.AreaIgnore = false
			elseif !ply.InSpawn then 
				ply:StartTimer() 
				ply.StoreFrames = nil
				ply.Frames = 0
			end 

			local oldhands = ply:GetHands()
			if ( IsValid( oldhands ) ) then oldhands:Remove() end

			local hands = ents.Create( "gmod_hands" )
			if ( IsValid( hands ) ) then
				ply:SetHands( hands )
				hands:SetOwner( ply )

				-- Which hands should we use?
				local cl_playermodel = ply:GetInfo( "cl_playermodel" )
				local info = player_manager.TranslatePlayerHands( cl_playermodel )
				if ( info ) then
					hands:SetModel( info.model )
					hands:SetSkin( info.skin )
					hands:SetBodyGroups( info.body )
				end

				-- Attach them to the viewmodel
				local vm = ply:GetViewModel( 0 )
				hands:AttachToViewmodel( vm )

				vm:DeleteOnRemove( hands )
				ply:DeleteOnRemove( hands )

				hands:Spawn()
			end
		end
	else 
		ply:SetTeam(TEAM_SPECTATOR)
		ply:Spectate(ply.SpecMode)
	end 
end 

function GM:PlayerCanPickupWeapon(ply, wep)
	if ply:HasWeapon(wep:GetClass()) then return false end
	ply:SetAmmo(999,wep:GetPrimaryAmmoType())
	return true
end

function GM:PlayerDisconnected(ply) 
	ply:PauseTimer() 
	ply:ProfileSave() 
end 

function GM:PlayerShouldTakeDamage(ply, attacker) 
	return false 
end 

function GM:IsSpawnpointSuitable() -- Overwrite so we don't run into death problems
	return true 
end 

/* Setup the teleports, platforms, spawns, and finish lines */
function GM:InitPostEntity() 
	if !SS.MapList[game.GetMap()] or !SS.MapList[game.GetMap()].ignoredoors then
		for k,v in pairs(ents.FindByClass("func_door")) do
			if(!v.IsP) then continue end
			local mins = v:OBBMins()
			local maxs = v:OBBMaxs()
			local h = maxs.z - mins.z
			if(h > 80 && !table.HasValue(SS.Alldoors,game.GetMap())) then continue end
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
	
	self:ReadWRRun()
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

function GM:ReadWRRun()
	self.WRFrames = 0
	if(!file.IsDir("botfiles","DATA")) then
		file.CreateDir("botfiles","DATA")
	end
	if(file.Exists("botfiles/"..game.GetMap()..".txt","DATA")) then
		local str = file.Read("botfiles/"..game.GetMap()..".txt","DATA")
		str = string.gsub(str,"THISISABOTFILE\n","")
		str = util.Decompress(str)
		str = util.JSONToTable(str)
		self.WRFr = str
		self.WRFrames = #self.WRFr[1]
	end
	if(self.WRFr) then
		self:SpawnBot()
	end
end

function GM:SpawnBot()
	for k,v in pairs(player.GetAll()) do
		if(v:IsBot()) then
			self.WRBot = v
			if(v:GetMoveType() != 0) then
				v:SetMoveType(0)
				v:SetCollisionGroup(10)
			end
		end
	end
	if(self.WRBot && self.WRBot:IsValid()) then return end
	RunConsoleCommand("bot")
	timer.Simple(0.5,function()
		for k,v in pairs(player.GetAll()) do
			if(v:IsBot()) then
				self.WRBot = v
				if(v:GetMoveType() != 0) then
					v:SetMoveType(0)
					v:SetCollisionGroup(10)
				end
			end
		end
	end)
end

function GM:PlayerWon(ply) 
	if(ply:IsBot()) then return end
	ply:EndTimer()
	ply.Winner = true 
	ply:ChatPrintAll(ply:Name().." has won in ".. FormatTime(ply:GetTotalTime(true)))
	local t = ply:GetTotalTime(false)
	if(self.CurrentID && (tonumber(ply.PBS[ply.LevelData.id][ply.Style]) == 0 ||t < tonumber(ply.PBS[ply.LevelData.id][ply.Style]))) then
		ply:ChatPrint("You have set a new Personal Best of "..FormatTime(t).."!")
		local steamid = ply:SteamID()
		local name = ply:Nick()
		if(tonumber(ply.PBS[ply.LevelData.id][ply.Style]) == 0) then
			DB_Query("INSERT INTO bh_records (name,mapid,level,style,date,time,steamid,pb) VALUES('"..name.."','"..self.CurrentID.."','"..ply.LevelData.id.."','"..ply.Style.."','"..os.time().."','"..t.."','"..string.sub(steamid, 7).."','1')")
		else
			DB_Query("UPDATE bh_records SET pb='0' WHERE style='"..ply.Style.."' AND level='"..ply.LevelData.id.."' AND steamid='"..string.sub(steamid, 7).."' AND pb='1'")
			DB_Query("INSERT INTO bh_records (name,mapid,level,style,date,time,steamid,pb) VALUES('"..name.."','"..self.CurrentID.."','"..ply.LevelData.id.."','"..ply.Style.."','"..os.time().."','"..t.."','"..string.sub(steamid, 7).."','1')")
		end
		ply.PBS[ply.LevelData.id][ply.Style] = t
		ply:SetPB(t)
	
		local rem = 0
		for k,v in pairs(self.RecordTable[ply.LevelData.id][ply.Style]) do
			if(v["steamid"] == string.sub(steamid, 7)) then
				rem = k
			end
		end
		local i = {["name"] = name, ["steamid"] = string.sub(steamid, 7), ["time"] = t}
		table.remove(self.RecordTable[ply.LevelData.id][ply.Style],k)
		table.insert(self.RecordTable[ply.LevelData.id][ply.Style],i)
		table.SortByMember(self.RecordTable[ply.LevelData.id][ply.Style], "time", function(a, b) return a > b end)
		if(self.RecordTable[ply.LevelData.id][ply.Style][1]["steamid"] == i["steamid"] && ply.Style == 1 && ply.StoreFrames) then
			self.WRFr = ply.StoreFrames
			ply.StoreFrames = nil
			self.WRFrames = #self.WRFr[1]
			self.NewWR = true
			file.Write("botfiles/"..game.GetMap()..".txt", "THISISABOTFILE\n")
			local write = util.TableToJSON(self.WRFr)
			write = util.Compress(write)
			file.Append("botfiles/"..game.GetMap()..".txt",write)
			
			self:SpawnBot()
		end
		net.Start("ModifyRT")
		net.WriteString(steamid)
		net.WriteString(name)
		net.WriteInt(ply.LevelData.id,4)
		net.WriteInt(ply.Style,4)
		net.WriteInt(rem,32)
		net.WriteInt(t,32)
		net.Broadcast()
	else
		DB_Query("INSERT INTO bh_records (name,mapid,level,style,date,time,steamid,pb) VALUES('"..name.."','"..self.CurrentID.."','"..ply.LevelData.id.."','"..ply.Style.."','"..os.time().."','"..t.."','"..string.sub(steamid, 7).."','0')")
	end
	print(ply.Payout) 
	ply:GiveMoney(ply.Payout)
end 

hook.Add("Think","ACAreas",function()
	for _,p in pairs(player.GetAll()) do
		if(p:IsBot() && GAMEMODE.WRBot && p == GAMEMODE.WRBot) then 
			if(p:GetMoveType() == 2) then
				p:SetMoveType(0)
			end
		end
		for _,v in pairs(GAMEMODE.ACAreas) do	
			if(p:Team() == TEAM_BHOP && p:HasTimer() && p:IsTimerRunning() && !p.Winner && GAMEMODE:IsInArea(p,v[1],v[2])) then
				p:EndTimer()
				p:ChatPrint(v[3])
			end
		end
	end
	if(GAMEMODE.WRBot && !GAMEMODE.WRBot:IsValid() && GAMEMODE.WRFr && #player.GetAll() != 0) then
		GAMEMODE:SpawnBot()
	end
end) --seperate think hooks = more organised and no extra cost in proccessing afaik

local wrframes = 1

hook.Add("SetupMove","wrbot",function(ply,data)
	if(ply == GAMEMODE.WRBot) then
		if(GAMEMODE.NewWR) then
			GAMEMODE.NewWR = false
			wrframes = 1
		end
		if wrframes >= GAMEMODE.WRFrames then
			wrframes = 1
		end
		data:SetOrigin(GAMEMODE.WRFr[1][wrframes])
		ply:SetEyeAngles(GAMEMODE.WRFr[2][wrframes])

		wrframes = wrframes + 1
	elseif(ply:Team() == TEAM_BHOP && !ply.InStart && ply:IsTimerRunning() && !ply.Winner && ply.Frames) then
		if(ply.Frames == 0) then
			ply.Frames = 1
			ply.StoreFrames = {}
			ply.StoreFrames[1] = {}
			ply.StoreFrames[2] = {}
			ply.StoreFrames[3] = {}
		end
		ply.StoreFrames[1][ply.Frames] = data:GetOrigin()
		ply.StoreFrames[2][ply.Frames] = ply:EyeAngles()
		
		ply.Frames = ply.Frames + 1
	end
end)