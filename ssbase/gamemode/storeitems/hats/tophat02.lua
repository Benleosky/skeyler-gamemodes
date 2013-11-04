ITEM.ID = "tophat02"										-- Should be a unique string that identifies the item
ITEM.Name = "Deluxe Top Hat"								-- The name the item should display
 
ITEM.Price = 2000
 
ITEM.Model = "models/mrgiggles/skeyler/hats/tophat02.mdl"	-- Model used by the item

ITEM.Type = "hat"											-- Also works for stuff like "mask" and such. Used for item compatibility

ITEM.Colorable = false										-- Used if the model is colorable via setcolor (or in a models case, setplayercolor)
ITEM.Tintable = false										-- Used if the model is colorable, but a translation is needed to $selfillumtint 

ITEM.Rotate = 45

ITEM.CamPos = Vector(60, 40, 0)								-- Used the modify the position of the camera on DModelPanels 
ITEM.LookAt = Vector(0, 0, 0) 								-- Used to change the angle at which the camera views the model 
ITEM.Fov = 20 

ITEM.Functions = {} 										-- Anything that can be called but not a gmod hook but more of a "store hook" goes here

ITEM.Functions["Equip"] = function ()						-- e.g miku hair attach with the models Equip
end

ITEM.Functions["Unequip"] = function ()						-- e.g miku hair attach with the models Equip
end

ITEM.Hooks = {}												-- Could run some shit in think hook maybe clientside only (e.g. repositioning or HEALTH CALCULATIONS OR SOMETHING LIKE THAT)

ITEM.Hooks["Think"] = function ()
end

/* HAT VARIABLES */
ITEM.Bone = "ValveBiped.Bip01_Head1"						-- Bone the item is attached to. ONLY NEED TO DEFINE FOR HATS/ACCESSORIES.
ITEM.BoneMerge = false										-- May be used for certain accessories to bonemerge the item instead. ONLY NEED TO DEFINE FOR HATS/ACCESSORIES.

ITEM.Models = {} 
ITEM.Models["elin"] = {pos=Vector(9.25, 1.25, -1.25), ang=Angle(0, -90, -90), scale=1} 
ITEM.Models["miku"] = {pos=Vector(10, 0.55, -1.3), ang=Angle(0, -90, -90), scale=1} 
ITEM.Models["tron"] = {pos=Vector(9.5, 1.25, -1.5), ang=Angle(0, -90, -90), scale=1} 
ITEM.Models["usif"] = {pos=Vector(6.75, 2.3, -0.75), ang=Angle(-4, -90, -90), scale=1} 
ITEM.Models["zer0"] = {pos=Vector(8.1, 1, -0.75), ang=Angle(-4, -90, -90), scale=0.9} 
/* ************* */