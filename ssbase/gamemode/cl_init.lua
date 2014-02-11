---------------------------
--       Bunny Hop       -- 
-- Created by xAaron113x --
--------------------------- 

for _,v in pairs(file.Find("ss_vgui/*.lua","LUA")) do -- Fix this later fagget  
	print(v) 
	-- include("ss_vgui/"..v) 
end

include("shared.lua")
include("sh_library.lua")
include("sh_profiles.lua") 
include("sh_store.lua") 
include("cl_chatbox.lua") 
include("cl_hud.lua") 
-- include("ss_vgui/ss_hub_store_icon.lua") 
include("cl_store.lua") 
include("cl_scoreboard.lua")

GM:HUDAddShouldNotDraw("CHudHealth") 
GM:HUDAddShouldNotDraw("CHudSecondaryAmmo") 
GM:HUDAddShouldNotDraw("CHudAmmo") 
GM:HUDAddShouldNotDraw("CHudChat") 

SS.ScrW = ScrW() 
SS.ScrH = ScrH()

GM.GUIBlurAmt = 0
GM.GUIBlurOverlay = Material("skeyler/blur_overlay") 

function ResolutionCheck() 
	local w = ScrW() 
	if w <= 640 then
		if !LocalPlayer or !LocalPlayer():IsValid() then timer.Simple(1, ResolutionCheck) return end
		LocalPlayer():ChatPrint("** We don't support this low of a resolution.")
		LocalPlayer():ChatPrint("** Please increase it for a better experience.") 
	end 
end 

function GM:SetGUIBlur(bool) 
	self.GUIBlur = bool or false 
end 

function GM:RenderScreenspaceEffects() 
	if self.GUIBlurAmt > 0 or self.GUIBlur then 
		if self.GUIBlur then 
			self.GUIBlurAmt = math.Approach(self.GUIBlurAmt, 10, 0.2) 
		else 
			self.GUIBlurAmt = math.Approach(self.GUIBlurAmt, 0, 0.5) 
		end 
		--DrawToyTown( self.GUIBlurAmt, ScrH() )  -- this is really hard on the gpu. is it really needed?
		surface.SetDrawColor(92, 92, 92, 210/10*self.GUIBlurAmt)
		surface.SetMaterial(self.GUIBlurOverlay) 
		surface.DrawTexturedRect(0, 0, 2480-(1920-ScrW()), 2480-(1080-ScrH())) 
	end 
end 

local MaxAmmo = {weapon_crowbar=0,weapon_physcannon=0,weapon_pysgun=0,weapon_pistol=18,gmod_tool=0,weapon_357=6,weapon_smg1=45,weapon_ar2=30,weapon_crossbow=1,weapon_frag=1,weapon_rpg=1,weapon_shotgun=6}
function GetPrimaryClipSize(wep) 
	if !wep or !wep:IsValid() then return false end 
	if MaxAmmo[wep:GetClass()] then 
		return MaxAmmo[wep:GetClass()] 
	elseif wep.Primary and wep.Primary.ClipSize then 
		return wep.Primary.ClipSize 
	end 
end 

local mag_left, mag_extra, mag_clip 
local function HUDAmmoCalc()
	local wep = LocalPlayer():GetActiveWeapon()  
	if(!wep or wep == "Camera" or !wep.Clip1 or wep:Clip1() == -1) then return 1, 1, "" end
	mag_left = wep:Clip1() 
	mag_extra = LocalPlayer():GetAmmoCount(wep:GetPrimaryAmmoType()) 
	max_clip = MaxAmmo[wep:GetClass()] or wep.Primary.ClipSize 
	return mag_left, max_clip, tostring(mag_left).."/"..tostring(mag_extra) 
end 

--[[---------------------------------------------------------
   Name: gamemode:PostDrawViewModel()
   Desc: Called after drawing the view model
-----------------------------------------------------------]]
function GM:PostDrawViewModel( ViewModel, Player, Weapon )

	if ( !IsValid( Weapon ) ) then return false end

	if ( Weapon.UseHands || !Weapon:IsScripted() ) then
		local hands = LocalPlayer():GetHands()
		if ( IsValid( hands ) ) then hands:DrawModel() end
	end

	player_manager.RunClass( Player, "PostDrawViewModel", ViewModel, Weapon )

	if ( Weapon.PostDrawViewModel == nil ) then return false end		
	return Weapon:PostDrawViewModel( ViewModel, Weapon, Player )

end