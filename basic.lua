local hotkey = GetScriptKey() 	

function Run()	
	local key = IsKeyDown(hotkey) 						
	
	if key == 1 then 									
		DrawCircleObject(GetSelf(), 250, 1)
	end
end

SetTimerCallback("Run")