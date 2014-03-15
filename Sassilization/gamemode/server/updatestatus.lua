LOBBY_IP = "192.168.1.152"
LOBBY_PORT = 40000

---------------------------------------------------------
--
---------------------------------------------------------

function GM:SocketConnected(ip, port, data)
	local id = self.ServerID
	local map = game.GetMap()

	socket.Send(LOBBY_IP, LOBBY_PORT, "smap", function(data)
		return data .. self.ServerID .. "¨" .. map
	end)
end

---------------------------------------------------------
--
---------------------------------------------------------

function GM:UpdateScoreboard()
	local info = {server = self.ServerID}
	local empires = empire.GetAll()
	
	for k, empire in pairs(empires) do
		if (ValidEmpire(empire)) then
			local id = empire:GetColorID()
			local name = empire:GetName()
			local cities = empire:GetCities()
			local food = empire:GetFood()
			local iron = empire:GetIron()
			local gold = empire:GetGold()

			table.insert(info, {id = id, name = name, cities = cities, food = food, iron = iron, gold = gold})
		end
	end

	data = util.Compress(von.serialize(info))

	socket.Send(LOBBY_IP, LOBBY_PORT, "sif", function(data)
		return data .. info
	end)
end

timer.Create("SA.UpdateScoreboard", 10, 0, function()
	if (GAMEMODE.Started) then
		GAMEMODE:UpdateScoreboard()
	end
end)

---------------------------------------------------------
--
---------------------------------------------------------

function GM:UpdateMinimap()
	local info = ""
	local empires = empire.GetAll()
	
	local world = game.GetWorld()
	local saveTable = world:GetSaveTable()
	local mins, maxs = saveTable.m_WorldMins, saveTable.m_WorldMaxs
	
	local x = math.abs(maxs.x)
	local y = math.abs(mins.y)

	for k, empire in pairs(empires) do
		if (ValidEmpire(empire)) then
			info = info .. "id=" .. empire:GetColorID() .. "u{"
			
			local units = empire:GetUnits()
			local buildings = empire:GetBuildings()

			for k, unit in pairs(units) do
				if (unit and unit:IsValid()) then
					local position = unit:GetPos()
					local direction = unit.targetPosition or position
					
					local positionX = math.Round((math.abs(position.x) /x) *359)
					local positionY = math.Round((math.abs(position.y) /y) *360)
					
					local size = math.Round(math.ceil(unit.OBBMaxs.x *0.8))
					local directionX = math.Round((math.abs(direction.x) /x) *359)
					local directionY = math.Round((math.abs(direction.y) /y) *360)

					info = info .. "|x=" .. positionX .. ",y=" .. positionY .. ",dx=" .. directionX .. ",dy=" .. directionY .. ",s=" .. size
				end
			end
			
			info = info .. "}b{"
			
			for k, building in pairs(buildings) do
				if (building and building:IsValid()) then
					local position = building:GetPos()
					
					local positionX = math.Round((math.abs(position.x) /x) *359)
					local positionY = math.Round((math.abs(position.y) /y) *360)
					
					local size = math.Round(math.ceil(building:OBBMaxs().x *0.4))
					
					info = info .. "|x=" .. positionX .. ",y=" .. positionY .. ",s=" .. size
				end
			end
		end
		
		info = info .. "}"
	end
	
	info = util.Compress(info)
	
	socket.Send(LOBBY_IP, LOBBY_PORT, "smp", function(data)
		return data .. self.ServerID .. "¨" .. info
	end)
end

timer.Create("SA.UpdateMinimap", 20, 0, function()
	if (GAMEMODE.Started) then
		GAMEMODE:UpdateMinimap()
	end
end)

---------------------------------------------------------
--
---------------------------------------------------------

socket.AddCommand("spl", function(sock, ip, port, data)
	data = von.deserialize(util.Decompress(data[1]))

	SA.AuthedPlayers = data
end)