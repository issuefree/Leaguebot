local top=200;local topleft=60;local script_loaded=1;                       
local ctr=0
local a={}
local key=0x78;--F9
local reloadkey=0x79;
local lmouse=0
local toggle_timer=os.clock()
local save_timer=os.clock()-4000
local reloading=0
local movegui=0
function sample_CallBackGui()
	CLOCK=os.clock()
	ctr=ctr+1
	local i=1
	if (ctr==30) then
		local fileinfo={LoadFile("script_gui_backup.txt")}
		while (i<#fileinfo) do
			if (tonumber(fileinfo[i+1])==1) then
				EnableScript(fileinfo[i])
			else
				DisableScript(fileinfo[i])
			end
			i=i+2
		end
	end
	if (IsKeyDown(reloadkey)~=0) then reloading=1 else
		if (reloading==1) then ReloadLua();reloading=0; end
	end
	if (IsKeyDown(key)~=0 and CLOCK-toggle_timer>1.2) then
		toggle_timer=CLOCK
		script_loaded= ((script_loaded+1)%2)
		SetGuiParams(top,topleft,script_loaded)
	end
	--if (script_loaded==0) then return end
	local lmouseclick=0
	if (IsKeyDown(0x01)~=0) then
		if (lmouse==0) then lmouseclick=1 end
		lmouse=1
	else
		movegui=0
		if (lmouse==1) then lmouse=2 else lmouse=0 end
	end
	local a={ListScripts()}
	local len=#a
	if (CLOCK-save_timer<1.5) then
		a[len+1]="Saving";a[len+2]=1
	else
		a[len+1]="Click to Save"
		a[len+2]=0
	end
	i=1
	local sz=6
	local cc=0
	local posX, posY = GetCursorX(), GetCursorY()
	local filebuf="";
	--DrawBox(topleft-5,top-5,sz*30,#a*sz+20,0xFF222222)
	local moveguicolor=0xFF11EEDD
	DrawText("All Scripts, F9 Hide/Show,F10 Reload",topleft,top-sz,0xFF11EEDD);
	if (posX<(1*sz)+topleft and posX>topleft-2*sz-2 and posY<top+(1)*sz and posY>top-sz) then
		moveguicolor=0xFFDDDD11
		if (lmouseclick==1) then
			movegui=1;
		end
	end
	if (movegui==1) then
		topleft=posX+1+sz
		top=posY
		SetGuiParams(top,topleft,script_loaded)
	end
	DrawText("@",topleft-2*sz-2,top-sz,moveguicolor);
	if (script_loaded==0) then return end
	while (i<#a) do
		local saver=0
		if (i==#a-1) then
			saver=1
		else
			filebuf=filebuf .. a[i] .. "\r\n" .. a[i+1] .. "\r\n"
		end
		
		if (posX<(string.len(a[i])+5)*sz+topleft and posX>topleft and posY<top+(i+2)*sz and posY>top+i*sz) then
			if (lmouse==2) then
				if (a[i+1]==1) then
					if (saver==0) then
						DisableScript(a[i])
					end
				else
					if (saver==1) then 
						SaveFile("script_gui_backup.txt",filebuf);
						save_timer=CLOCK
					else
						EnableScript(a[i])
					end
				end
			end
			--local info=GetScriptInfo(a[i])
			--DrawText(info,topleft+200,top+i*sz,0xFFDDEE00);
			cc=0xFF
		else
			cc=0
		end
		if (saver==1) then cc=0xFFFF end
		if (a[i+1]==1) then
			DrawText("ON  " .. a[i],topleft,top+i*sz, 0xFF33EE00+cc);
		else
			DrawText("OFF " .. a[i],topleft,top+i*sz, 0xFFFF0000+cc);
		end
		i=i+2
	end
end
SetTimerCallback("sample_CallBackGui")