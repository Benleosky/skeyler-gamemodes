---------------------------- 
--        Bunny Hop       -- 
-- Created by Skeyler.com -- 
---------------------------- 

GM.Styles = {} 

function GM:AddStyle(id, blockkeys, cmd, name) 
	GM.Styles[id] = {id=id,blockkeys=blockkeys,cmd=cmd,name=name} 
end 

STYLE_CLASSIC = 1 
STYLE_SW = 2 
STYLE_W = 3 

GM:AddStyle(STYLE_CLASSIC, {cl={},sv={}}, "normal", "Normal") --erry key
GM:AddStyle(STYLE_SW, {cl={"moveright","moveleft"},sv={IN_MOVERIGHT,IN_MOVELEFT}}, "sw", "Sideways") --no W or S
GM:AddStyle(STYLE_W, {cl={"moveright","back","moveleft"},sv={IN_MOVERIGHT,IN_BACK,IN_MOVELEFT}}, "w", "W-Only") --no S or A or D

if CLIENT then 
	hook.Add("PlayerBindPress","CheckIllegalKey",function(ply,bind,pressed)
		if(tonumber(ply:GetNWInt("Style",1)) != 1) then
			local s = GAMEMODE.Styles[ply:GetNWInt("Style",1)]
			for k,v in pairs(s.blockkeys.cl) do
				if(string.find(bind,v)) then
					if(pressed) then
						ply:ChatPrint("This key is not allowed in "..s.name..".")
					end
					return true
				end
			end
		end
	end)
	return 
end

for k,v in pairs(GM.Styles) do
	concommand.Add("ss_"..v.cmd,function(ply)
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
	end)
	
	SS.AddCommand(v.cmd,"ss_"..v.cmd)
end

hook.Add("SetupMove","ALLYOURBASEAREBELONGTOUS",function(ply,data)
	local style = ply.Style
	if(ply:Team() == TEAM_BHOP && style != 1) then
		local buttons = data:GetButtons()
		
		local s = GAMEMODE.Styles[style]
		for k,v in pairs(s.blockkeys.sv) do
			print('key')
			if(bit.band(buttons,v)>0) then
				buttons = bit.band(buttons, bit.bnot(v))
				print('removed')
			end
		end
		
		data:SetButtons(buttons)
	end
end)