--[[ 
--------Info------
Hotkeys can use globalvar_x where x is 1,2,3...
Hotkeys for lua include
1.RELOADLUA
2.STOPLUA
3.LOADSCRIPT=sample.lua
To start:Check Start Lua[x] or Push Reload Button

spell can be 'Q','W','E','R','1','2','3','4','5','6','D','F'
color is in the form ARGB (0xFF667788)

--------Draw Functions---------

printtext(text)  //prints to dos console box
DrawText(text,x,y,color)
DrawTextMinimap(text,x,y,z,color)
DrawTextObject(text,target,color)
DrawCircle(x,y,z,radius,color)
DrawCircleObject(target,radius,color)
DrawLine(x,y,z,length,color,angle,width)
DrawLineObject(target,length,color,angle,width)
DrawBox(x,y,width,height,color)

----------Action Functions---------//try to call only 1 per callback
AttackTarget(target)
CastSpellTarget(spell,target)
CastSpellXYZ(spell,x,y,z)
MoveToXYZ(x,y,z)
StopMove()

--------More Global Functions----------
setTimerCallback(function)         //you need this if you want your script to persist

GetSelf() returns Unit
SetGlobalVar(slot,value)
GetGlobalVar(slot) returns number
GetScriptVar(slot) returns number  //can set in hotkey with SETVARX=Y
GetScriptKey() returns number      //the hotkey that activated the script
GetWorldX() returns number  //center of camera X
GetWorldY() returns number  //center of camera y
GetWorldWidth() returns number //viewport width

IsKeyDown(number) returns number //accepts virtual key codes returns 0 if not pressed
IsSpellReady(spell) returns number
GetSpellLevel(spell) returns number
CanUseSpell(spell) returns number // same as (IsSpellReady(spell) and GetSpellLevel(spell)>0)

GetCursorX()
GetCursorY()
GetCursorWorldX()
GetCursorWorldY()
GetCursorWorldZ()
GetScreenX()
GetScreenY()
GetFontSize()

GetClock()
CastHotkey(hotkey_text)  //Example CastHotkey("AUTO 100,0 ATTACK:WEAKENEMY RANGE=600 FORCETARGET=" .. target.name)
						 //Example2 CastHotkey("AUTO 100,0 SPELLQ:WEAKENEMY RANGE=600 COOLDOWN");
GetWeakEnemy(damage_type,range) returns Unit		//damage type is 'PHYS' 'MAGIC' 'TRUE'
GetWeakEnemy(damage_type,range,"NEARMOUSE")
GetWeakEnemy(damage_type,range,"ONLYNEARMOUSE")
GetInventoryItem(slotnumber) returns id_number // slotnumber is 1,2,3,4,5,6
PlaySound("filename.wav") or PlaySound("Beep")
CalcDamage(target,damage) returns number // Ex:CalcDamage(enemy,100+(GetSelf()).ad*2)
CalcMagicDamage(target,damage) returns number
GetMap() returns number 1=SummonersRift
GetFireahead(target,delay,projectilespeed) returns x,y,z
IsWall(x,y,z) returns 1 or 0
WillHitWall(target,knockbackdistance) returns 1 or 0
CreepBlock(x,y,z,(optional) skillshot_width) returns 1 or 0





-----------[objManager]-----------

objManager:GetObject(index) returns Unit
objManager:GetCreature(index) returns Unit
objManager:GetNewObject(index) returns Unit
objManager:GetHero(index) returns Unit

objManager:GetMaxHeroes() returns number
objManager:GetMaxObjects() returns number
objManager:GetMaxCreatures() returns number
objManager:GetMaxNewObjects() returns number

-----------[Unit]-----------
GetMinBBox(Unit) returns pos
GetMaxBBox(Unit) returns pos
Unit.id
Unit.valid
Unit.index
Unit.x
Unit.y
Unit.z
Unit.visible
Unit.name
Unit.charName
Unit.dead
Unit.team
Unit.invulnerable
Unit.health
Unit.maxHealth
Unit.mana
Unit.maxMana
Unit.range
Unit.movespeed
Unit.addDamage
Unit.baseDamage
Unit.cdr
Unit.armor
Unit.magicArmor
Unit.ap
Unit.armorPen
Unit.magicPen
Unit.armorPenPercent
Unit.magicPenPercent
Unit.selflevel
Unit.SummonerD
Unit.SummonerF
Unit.SpellTimeQ
Unit.SpellLevelQ

]]--
print("sample loaded")
