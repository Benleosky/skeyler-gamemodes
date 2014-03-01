local function GeneratePassword()
	
	local str = ""
	
	while string.len(str) < 6 do
		
		local int = math.random(97,122)
		local stradd = string.char(int)
		str = str .. stradd
		
	end
	
	str = "~_~"..str
	
	GAMEMODE.password = str
	
	return str
	
end

function ResetPassword()
	
	local pass = GeneratePassword()
	
	MsgN("Changing the server's Password to: "..pass)
	
	RunConsoleCommand("sv_password",pass)
	
	libsass.mysqlDatabase:Query("UPDATE "..DB_SERVER_TABLE.." SET password=\'"..pass.."\' WHERE ip=\'"..HOSTIP.."\' AND port=\'"..HOSTPORT.."\'" )
	
end

function ResetServerStatus()
	
	for _, pl in pairs( player.GetAll() ) do
		
		pl:ConCommand("connect "..LOBBYIP.. ":"..LOBBYPORT)
		
	end
	
	ResetPassword()
	libsass.mysqlDatabase:Query("UPDATE "..DB_SERVER_TABLE.." SET status=\'ready\' WHERE ip=\'"..HOSTIP.."\' AND port=\'"..HOSTPORT.."\'" )
	tcpSend( LOBBYIP, DATAPORT, tostring("UPDATESTATUS:"..Json.Encode({SERVERID,"ready",game.GetMap()}).."\n") )
	
end

-- send every 12 seconds
function GM:UpdateScoreboard()
	local data = ""
	local empires = empire.GetAll()
	
	for id, empire in pairs(empires) do
		if (ValidEmpire(empire)) then
			local name = empire:GetName()
			local cities = empire:GetCities()
			local food = empire:GetFood()
			local iron = empire:GetIron()
			local gold = empire:GetGold()

			data = data .. "|" .. "id=" .. id .. ",n=" .. name .. ",c=" .. cities .. ",f=" .. food .. ",i=" .. iron .. ",g=" .. gold
		end
	end

	data = util.Compress(data)
	
	--socket.Send(ip, port, "sassinfo", function(buffer)
	--	buffer:WriteLong(string.len(data))
	--	buffer:WriteData(data)
	--end)
end

-- send every 20 seconds
function GM:UpdateMinimap()
	local data = ""
	local empires = empire.GetAll()
	
	local world = game.GetWorld()
	local saveTable = world:GetSaveTable()
	local mins, maxs = saveTable.m_WorldMins, saveTable.m_WorldMaxs
	
	for id, empire in pairs(empires) do
		if (ValidEmpire(empire)) then
			data = data .. "id=" .. id .. "u{"
			
			local units = empire:GetUnits()
			local buildings = empire:GetBuildings()

			for k, unit in pairs(units) do
				if (unit and unit:IsValid()) then
					local position = unit:GetPos()
					local direction = unit.targetPosition or vector_origin
					
					position.x = math.Round((position.x /maxs.x) *359)
					position.y = math.Round((position.y /maxs.y) *360)
					
					local size = math.Round(math.ceil(unit.OBBMaxs.x *0.8))
					local directionX = math.Round((direction.x /maxs.x) *359)
					local directionY = math.Round((direction.y /maxs.y) *359)
					
					data = data .. "|x=" .. position.x .. ",y=" .. position.y .. ",dx=" .. directionX .. ",dy=" .. directionY .. ",s=" .. size
				end
			end
			
			data = data .. "}b{"
			
			for k, building in pairs(buildings) do
				if (building and building:IsValid()) then
					local position = building:GetPos()
					
					position.x = math.Round((position.x /maxs.x) *359)
					position.y = math.Round((position.y /maxs.y) *360)
					
					local size = math.Round(math.ceil(building:OBBMaxs().x *0.4))
					
					data = data .. "|x=" .. position.x .. ",y=" .. position.y .. ",s=" .. size
				end
			end
		end
		
		data = data .. "}"
	end
	
	--[[
	data = data .. "id=" .. 2 .. "u{"
	data = data .. "}b{"
	data = data .. "}"
	
	data = data .. "id=" .. 3 .. "u{"
	data = data .. "}b{"
	data = data .. "}"
	
	local s=string.Explode("id=",data)
	if (s[1] == "") then table.remove(s, 1) end
	
	for k, v in pairs(s) do
		print("")
		print("id:", string.sub(v, 1, 1))
		print("")
		local c = string.match(v, "u{(.*)}b")
		
		print("units:")
		print(c)
		
		local j = string.Explode("|", c)
		PrintTable(j)
		
		local g = string.match(v, "b{(.*)}")
		
		print("")
		print("buildings:")
		print(g)
		
		local h = string.Explode("|", g)
		
	end
	]]
	
	data = util.Compress(data)
	
--	socket.Send(ip, port, "sassmap", function(buffer)
--		buffer:WriteLong(string.len(data))
--		buffer:WriteData(data)
--	end)
end

--[[ THIS IS VERY OLD CODE
function GM:UpdateScoreboard()
	
	if game.SinglePlayer() then return end
	if not START or ENDROUND then return end
	if not SERVERID then return end
	
	local players = player.GetAll()
	table.sort(players, function( a, b ) return math.Round(a:GetNWInt("_gold")) > math.Round(b:GetNWInt("_gold")) end)
	
	--Send the scoreboard information to the lobby
	local info = 'LEADERBOARD:'..SERVERID..'|SCORES = {'
	for _, pl in pairs(players) do
		if IsValid(pl) and pl:IsPlayer() and pl.MyColor then
			info = info..'{'
			info = info..'n="'..tmysql.escape(string.gsub( pl:GetName(), "|", "" ))..'",'
			info = info..'c={r='..pl.MyColor[1].r..',g='..pl.MyColor[1].g..',b='..pl.MyColor[1].b..'},'
			info = info..'g='..math.Round(pl:GetNWInt("_gold"))..','
			info = info..'f='..math.Round(pl:GetNWInt("_food"))..','
			info = info..'i='..math.Round(pl:GetNWInt("_iron"))..','
			info = info..'ci='..math.Round(pl:GetNWInt("_cities"))..','
			info = info..'cr='..math.Round(pl:GetNWInt("_spirits"))..','
			info = info..'s='..math.Round(pl:GetNWInt("_shrines"))..','
			info = info..'fa='..math.Round(pl:GetNWInt("_farms"))..','
			info = info..'mi='..math.Round(pl:GetNWInt("_mines"))..','
			info = info..'u='..pl:GetNWInt("_soldiers")
			if _ == #players then info = info..'}' else info = info..'},' end
		end
	end
	info = info..'}'
	tcpSend(LOBBYIP,DATAPORT,info.."\n","Scoreboard Updated")
	
end

function GM:UpdateMinimapBuildings()
	
	if game.SinglePlayer() then return end
	if not START or ENDROUND then return end
	if not SERVERID then return end
	
	if not MINIMAPS then return end
	if MINIMAPS[game.GetMap()] then
		local map = MINIMAPS[game.GetMap()]
		local info = 'MINIMAP:'..SERVERID..'|bldg|DATA = {'
		local bldgs = ents.FindByClass("bldg_*")
		for _, ent in pairs(bldgs) do
			local r,g,b,a = ent:GetColor()
			ent.lastAttacked = ent.lastAttacked == 1 and 1 or 0
			info = info..'{'
			info = info..'i='..ent:EntIndex()..','
			info = info..'s="'..math.ceil(ent:OBBMaxs().x*map.Scale)..'",'
			info = info..'c={r='..r..',g='..g..',b='..b..',a='..a..'},'
			info = info..'a='..ent.lastAttacked..','
			info = info..'x='..math.Round((ent:GetPos().x-map.Origin.x)*map.Scale)..','
			info = info..'y='..math.Round((map.Origin.y-ent:GetPos().y)*map.Scale)
			if _ == #bldgs then info = info..'}' else info = info..'},' end
			ent.lastAttacked = 0
		end
		info = info..'}'
		tcpSend(LOBBYIP,DATAPORT,info.."\n","Minimap Buildings Updated")
	end
end

function GM:UpdateMinimapUnits()
	
	if game.SinglePlayer() then return end
	if not START or ENDROUND then return end
	if not SERVERID then return end
	
	if not MINIMAPS then return end
	if MINIMAPS[game.GetMap()] then
		local map = MINIMAPS[game.GetMap()]
		local info = 'MINIMAP:'..SERVERID..'|unit|DATA = {'
		local units = ents.FindByClass("unit_*")
		for _, ent in pairs(units) do
			if ent:GetEmpire() and ent:GetEmpire():GetPlayer():IsPlayer() then
				local r,g,b,a = ent:GetEmpire():GetColor()
				local pos = ent:GetPos()
				ent.lastAttacked = ent.lastAttacked == 1 and 1 or 0
				ent.lastPos = ent.lastPos or {x=pos.x,y=pos.y}
				info = info..'{'
				info = info..'i='..ent:EntIndex()..','
				info = info..'s="'..math.ceil(ent:OBBMaxs().x*map.Scale)..'",'
				info = info..'c={r='..r..',g='..g..',b='..b..',a='..a..'},'
				info = info..'a='..ent.lastAttacked..','
				info = info..'px='..math.Round((ent.lastPos.x-map.Origin.x)*map.Scale)..','
				info = info..'py='..math.Round((map.Origin.y-ent.lastPos.y)*map.Scale)..','
				info = info..'x='..math.Round((pos.x-map.Origin.x)*map.Scale)..','
				info = info..'y='..math.Round((map.Origin.y-pos.y)*map.Scale)
				if _ == #units then info = info..'}' else info = info..'},' end
				ent.lastAttacked = 0
				ent.lastPos = {x=pos.x,y=pos.y}
			end
		end
		info = info..'}'
		tcpSend(LOBBYIP,DATAPORT,info.."\n","Minimap Units Updated")
	end
end
]]