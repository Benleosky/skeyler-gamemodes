---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:ShouldHUDPaint()
	return LocalPlayer():IsPlayingMinigame()
end

---------------------------------------------------------
--
---------------------------------------------------------

function MINIGAME:HUDPaint()
end