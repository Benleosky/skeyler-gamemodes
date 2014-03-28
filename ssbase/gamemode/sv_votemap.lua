---------------------------- 
--         SSBase         -- 
-- Created by Skeyler.com -- 
---------------------------- 

SS.MapVoteNumber = 5 -- How many maps can be in the vote 
SS.MaxExtends = 3 
SS.MapTime = 15 -- In minutes 
SS.MaxNomiations = 2 
SS.RTVPercent = 0.75 
SS.VotemapTime = 30 -- how long in seconds the vote will last 

local SS = SS 
local rpairs = rpairs 
local table = table 
local CurTime = CurTime 
local timer = timer 
local pairs = pairs 
local vote = vote 
local RunConsoleCommand = RunConsoleCommand 
local ChatPrintAll = ChatPrintAll 
local unpack = unpack 

module("votemap") 

local voteinfo = {} 
voteinfo.voting = false 
voteinfo.nominations = {} 
voteinfo.rtv = false 
voteinfo.extends = 0 
voteinfo.startTime = 0 
voteinfo.endTime = 0 

function IsVoting() 
	return voteinfo.voting 
end 

function GetTimeleft() 
	return (voteinfo.endTime-voteinfo.startTime) 
end 

function Init() 
	Timer() 
end 

function Timer() 
	voteinfo.startTime = CurTime() 
	voteinfo.endTime = CurTime()+SS.MapTime*60 
	timer.Create("SS_Votemap", SS.MapTime*60, 1, Start) 
end 

function Map(name) 
	RunConsoleCommand("ss_map", name) 

	-- Assume if we haven't changed that the map doesn't exist 
	timer.Simple(6, function() 
		InvalidMap(name) 
	end ) 
end 

function Start() 
	if voteinfo.voting then return end -- don't start twice...

	voteinfo.voting = true 
	voteinfo.options = {} 

	-- Add the best nominations (limited in the nominate function) 
	for k,v in pairs(voteinfo.nominations) do 
		table.insert(voteinfo.options, v) 
	end 

	-- Select random maps from the maplist to fill in the spots 
	for k,v in rpairs(SS.MapList) do 
		if table.Count(voteinfo.options) >= SS.MapVoteNumber then break end -- We have all the maps already 

		-- if v.name == game.GetMap() then continue end -- Don't add the current map.

		table.insert(voteinfo.options, v.name) 
	end 

	-- Add an extend 
	if !voteinfo.rtv and voteinfo.extends < SS.MaxExtends then 
		table.insert(voteinfo.options, "Extend") 
	end 

	vote.Start(false, "Vote for a map to play!", SS.VotemapTime, End, Failed, unpack(voteinfo.options)) 
end 

function End(map) 
	if !voteinfo.voting then return end -- don't end if it isn't started 

	voteinfo.nominations = {} 
	voteinfo.rtv = false 
	voteinfo.voting = false 

	if !map then return end 

	if map == "Extend" then 
		voteinfo.extends = voteinfo.extends+1 
		Timer() 
		ChatPrintAll("You've selected to extend the current map.")
	else 
		ChatPrintAll("You've selected to change to "..map) 
		if SS.NewMap then -- Custom mapchange function for the gamemode 
			SS:NewMap(map) 
		else 
			Map(map) 
		end 
	end 
end 

function Failed() 
	if voteinfo.extends >= SS.MaxExtends+3 then -- on the third extra extend 
		ChatPrintAll("No one has voted, but you've been on this map long enough!") 
		Map(table.Random(SS.MapList).name) 
		return 
	end 

	voteinfo.extends = voteinfo.extends+1 
	End()
	Timer() 
	ChatPrintAll("No one voted for a new map.  The current map has been extended.") 
end 

function InvalidMap(map) 
	ChatPrintAll(map.." appears to be an invalid map.  Tell a developer!") 
	Start() 
end 

function Nominate() 
	-- TODO
end 

function RTV() 
	-- TODO
end 
