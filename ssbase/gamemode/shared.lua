---------------------------- 
--         SSBase         -- 
-- Created by Skeyler.com -- 
---------------------------- 

DeriveGamemode("base") 

GM.Name 		= "SSBase"
GM.Author 		= "Skeyler Servers"
GM.Email 		= "info@skeyler.com"
GM.Website 		= "skeyler.com"
GM.TeamBased 	= false 

GM.VIPBonusHP = false 
GM.HUDShowVel = false 
GM.HUDShowTimer = false 
SS = {}
PLAYER_META = FindMetaTable("Player")
ENTITY_META = FindMetaTable("Entity")
TEAM_SPEC = TEAM_SPECTATOR

team.SetUp(TEAM_SPEC, "Spectator", Color(150, 150, 150), false) 

PLAYER_META.Alive2 = PLAYER_META.Alive2 or PLAYER_META.Alive 
function PLAYER_META:Alive() 
	if self:Team() == TEAM_SPEC then return false end 
	return self:Alive2() 
end 
 
function FormatTime(Time) 
	local Mili, Seconds, Mins, Hours, Text

	Mili = string.Explode(".", tostring(Time))
	if Mili[2] then Mili = string.sub(string.Explode(".", tostring(Time))[2], 1, 2) else Mili = "00" end 
	Hours = math.floor(Time/3600)
	Mins = math.floor((Time-Hours*3600)/60) 
	Seconds = math.floor(Time-Hours*3600-Mins*60)

	Text = ""
	for k,v in pairs({Hours, Mins, Seconds}) do 
		if v > 0 then 
			if v >= 10 then 
				Text = Text..tostring(v) 
			else 
				Text = Text..tostring("0"..tostring(v)) 
			end 
		else 
			Text = Text.."00" 
		end 
		if k < 3 then Text = Text..":" end 
	end 
	if string.len(Mili) < 2 then 
		Text = Text.."."..Mili.."0" 
	else 
		Text = Text.."."..Mili
	end 
	return Text 
end 
 
function FormatNum(n)
	if (!n) then
		return 0
	end
    n = tostring(n)
    local dp = string.find(n, "%.") or #n+1
	for i=dp-4, 1, -3 do
		n = n:sub(1, i) .. "," .. n:sub(i+1)
    end
    return n
end
 
-- Atlas chat shared config.
if (atlaschat) then

	-- We don't want rank icons or avatars.
	atlaschat.enableAvatars = atlaschat.config.New("Enable avatars?", "avatars", false, true, true, true, true)
	atlaschat.enableRankIcons = atlaschat.config.New("Enable rank icons?", "rank_icons", false, true, true, true, true)
end