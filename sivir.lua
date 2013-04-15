require "Utils"
require "timCommon"
require "modules"

print("\nTim's Sivir")

AddToggle("lasthit", {on=true, key=112, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("block", {on=true, key=113, label="SpellShield"})

spells["boomerang"] = {key="Q", range=1000, color=yellow, base={60,105,150,195,240}, ap=.5, adBonus=1.1, type="P"}

function Run()
	TimTick()	

   if IsOn("lasthit") and not GetWeakEnemy("PHYSICAL", 950) then
      KillWeakMinion("AA", 100)
   end
end

local spells = {
   {charName = "Akali", spellName = "akalimota", spellType = "Damage"},
   {charName = "Alistar", spellName = "headbutt", spellType = "Stun"},
   {charName = "Amumu", spellName = "bandagetoss", spellType = "Stun"},
   {charName = "Anivia", spellName = "flashfrost", spellType = "Stun"},
   {charName = "Anivia", spellName = "frostbite", spellType = "Damage"},
   {charName = "Annie", spellName = "disintigrate", spellType = "Stun"},
   {charName = "Annie", spellName = "infernalguardian", spellType = "Stun"},   
   {charName = "Ahri", spellName = "ahriseduce", spellType = "Stun"},   
   {charName = "Ashe", spellName = "volley", spellType = "Slow"},
   {charName = "Blitzcrank", spellName = "rocketgrab", spellType = "Stun"},   
   {charName = "Brand", spellName = "brandblaze", spellType = "Damage"},   
   {charName = "Brand", spellName = "brandconflagration", spellType = "Damage"},   
   {charName = "Brand", spellName = "brandwildfire", spellType = "Damage"},   
   {charName = "Caitlyn", spellName = "caitlynpiltoverpeacemaker", spellType = "Damage"},   
   {charName = "Caitlyn", spellName = "caitlynentrapment", spellType = "Slow"},   
   {charName = "Caitlyn", spellName = "caitlynaceinthehole", spellType = "Damage"},   
   {charName = "Chogath", spellName = "rupture", spellType = "Damage"},   
   {charName = "Chogath", spellName = "feralscream", spellType = "Damage"},   
   {charName = "Chogath", spellName = "feast", spellType = "Damage"},   
   {charName = "Corki", spellName = "missilebarrage", spellType = "Damage"},   
   {charName = "Darius", spellName = "dariusaxegrabcone", spellType = "Stun"},
   {charName = "Darius", spellName = "dariusexecute", spellType = "Damage"},
   {charName = "Draven", spellName = "dravendoubleshot", spellType = "Slow"},
   {charName = "Draven", spellName = "dravenrcast", spellType = "Damage"},
   {charName = "Dr. Mundo", spellName = "infectedcleavermissilecast", spellType = "Slow"},
   {charName = "Fiddlesticks", spellName = "terrify", spellType = "Stun"},
   {charName = "Fiddlesticks", spellName = "drain", spellType = "Damage"},
   {charName = "Fizz", spellName = "fizzmarinerdoom", spellType = "Damage"},
   {charName = "Galio", spellName = "galioresolutesmite", spellType = "Damage"},
   {charName = "Gangplank", spellName = "parley", spellType = "Damage"},
   {charName = "Garen", spellName = "garenjustice", spellType = "Silence"},
   {charName = "Graves", spellName = "gravesclustershot", spellType = "Damage"},
   {charName = "Graves", spellName = "graveschargeshot", spellType = "Damage"},
   {charName = "Heimerdinger", spellName = "hextechmicrorockets", spellType = "Damage"},
   {charName = "Irelia", spellName = "ireliaequilibriumstrike", spellType = "Stun"},
   {charName = "Janna", spellName = "sowthewind", spellType = "Slow"},
   {charName = "Jayce", spellName = "jayceshockblast", spellType = "Damage"},
   {charName = "Karthus", spellName = "fallenone", spellType = "Damage"},
   {charName = "Kassadin", spellName = "nulllance", spellType = "Damage"},
   {charName = "Kassadin", spellName = "forcepulse", spellType = "Damage"},
   {charName = "Kayle", spellName = "judicatorreckoning", spellType = "Slow"},
   {charName = "LeBlanc", spellName = "leblancchaosorb", spellType = "Slow"},
   {charName = "LeBlanc", spellName = "leblancsoulshackle", spellType = "Slow"},
   {charName = "LeeSin", spellName = "blindmonkqone", spellType = "Damage"},
   {charName = "Leona", spellName = "leonasolarflare", spellType = "Stun"},
   {charName = "Lulu", spellName = "luluw", spellType = "Slow"},
   {charName = "Lux", spellName = "luxlightbinding", spellType = "Stun"},
   {charName = "Malphite", spellName = "ufslash", spellType = "Stun"},
   {charName = "Malphite", spellName = "seismicshard", spellType = "Slow"},
   {charName = "Malzahar", spellName = "alzaharnethergrasp", spellType = "Stun"},
   {charName = "Malzahar", spellName = "alzaharmaleficvisions", spellType = "Damage"},
   {charName = "Maoki", spellName = "maokaitrunkline", spellType = "Stun"},
   {charName = "Maoki", spellName = "maokaiunstablegrowth", spellType = "Stun"},
   {charName = "MasterYi", spellName = "alphastrike", spellType = "Damage"},
   {charName = "MissFortune", spellName = "missfortunericochetshot", spellType = "Damage"},
   {charName = "Mordekaiser", spellName = "mordekaiserchildrenofthegrave", spellType = "Damage"},
   {charName = "Morgana", spellName = "darkbinding", spellType = "Stun"},
   {charName = "Nasus", spellName = "wither", spellType = "Slow"},
   {charName = "Nautilus", spellName = "nautilusanchordrag", spellType = "Stun"},
   {charName = "Nautilus", spellName = "nautilusgrandline", spellType = "Stun"},
   {charName = "Nidalee", spellName = "javelintoss", spellType = "Damage"},
   {charName = "Nocturne", spellName = "nocturneduskbringer", spellType = "Damage"},
   {charName = "Nunu", spellName = "iceblast", spellType = "Slow"},
   {charName = "Olaf", spellName = "olafaxethrowcast", spellType = "Slow"},
   {charName = "Olaf", spellName = "olafrecklessstrike", spellType = "Slow"},
   {charName = "Pantheon", spellName = "pantheon_throw", spellType = "Slow"},
   {charName = "Rammus", spellName = "puncturingtaunt", spellType = "Stun"},
   {charName = "Rengar", spellName = "rengarE", spellType = "Stun"},
   {charName = "Ryze", spellName = "runeprison", spellType = "Stun"},
   {charName = "Ryze", spellName = "overload", spellType = "Damage"},
   {charName = "Shen", spellName = "shenshadowdash", spellType = "Stun"},
   {charName = "Sion", spellName = "crypticgaze", spellType = "Stun"},
   {charName = "Skarner", spellName = "skarnerimpale", spellType = "Stun"},
   {charName = "Sona", spellName = "sonacrescendo", spellType = "Stun"},
   {charName = "Taric", spellName = "dazzle", spellType = "Stun"},
   {charName = "Teemo", spellName = "blindingdart", spellType = "Damage"},
   {charName = "Tristana", spellName = "detonatingshot", spellType = "Damage"},
   {charName = "Tristana", spellName = "bustershot", spellType = "Damage"},
   {charName = "Tryndamere", spellName = "mockingshout", spellType = "Slow"},
   {charName = "Twisted Fate", spellName = "redcard", spellType = "Slow"},
   {charName = "Twisted Fate", spellName = "yellowcard", spellType = "Stun"},    
   {charName = "Twisted Fate", spellName = "wildcards", spellType = "Stun"},    
   {charName = "Twitch", spellName = "TwitchVenomCask", spellType = "Slow"},    
   {charName = "Varus", spellName = "varusr", spellType = "Stun"},    
   {charName = "Vayne", spellName = "VayneCondemn", spellType = "Stun"},    
   {charName = "Veigar", spellName = "veigarbalefulstrike", spellType = "Damage"},    
   {charName = "Veigar", spellName = "veigareventhorizon", spellType = "Stun"},    
   {charName = "Veigar", spellName = "veigarprimordialburst", spellType = "Damage"},    
   {charName = "Volibear", spellName = "volibearq", spellType = "Stun"},    
   {charName = "Vi", spellName = "assaultandbattery", spellType = "Stun"},
   {charName = "Xerath", spellName = "xeratharcanopulse", spellType = "Damage"},
   {charName = "Zyra", spellName = "ZyraGraspingRoots", spellType = "Stun"}
}

function checkBlock(unit, spell)
   if CanUse("E") and spell.target and spell.target.name == me.name then
      for _,s in ipairs(spells) do
         if find(spell.name, s.spellName) then
      		CastSpellTarget("E", me)
      		break
         end
      end
   end
end

AddOnSpell(checkBlock)
SetTimerCallback("Run")