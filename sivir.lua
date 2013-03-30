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
   {charName = "Taric", spellName = "dazzle", spellType = "Stun"}
   {charName = "Sion", spellName = "Cryptic Gaze", spellType = "Stun"}
   {charName = "Malzahar", spellName = "Nether Grasp", spellType = "Stun"}
   {charName = "Darius", spellName = "Noxian Guillotine", spellType = "Stun"}
   {charName = "Darius", spellName = "Crippling Strike", spellType = "Slow"}
   {charName = "Irelia", spellName = "Equilibrium Strike", spellType = "Slow"}
   {charName = "Twisted Fate", spellName = "Red Card", spellType = "Slow"}
   {charName = "Twisted Fate", spellName = "Yellow Card", spellType = "Stun"}    
   {charName = "Malphite", spellName = "Unstoppable Force", spellType = "Stun"}
   {charName = "Malphite", spellName = "Seismic Shard", spellType = "Slow"}
   {charName = "Sona", spellName = "Crescendo", spellType = "Stun"}
   {charName = "Leona", spellName = "Solar Flare", spellType = "Stun"}
   {charName = "Leona", spellName = "Shield of Daybreak", spellType = "Stun"}
   {charName = "Leona", spellName = "Zenith Blade", spellType = "Stun"}
   {charName = "Fiddlesticks", spellName = "Terrify", spellType = "Silence"}
   {charName = "Fiddlesticks", spellName = "Drain", spellType = "Silence"}
   {charName = "Vi", spellName = "Assault and Battery", spellType = "Stun"}
   {charName = "Garen", spellName = "Decisive Strike", spellType = "Silence"}
   {charName = "Garen", spellName = "Demacian Justice", spellType = "Silence"}
   {charName = "Kayle", spellName = "Reckoning", spellType = "Slow"}
   {charName = "Ryze", spellName = "Rune Prison", spellType = "Stun"}
   {charName = "Tryndamere", spellName = "Mocking Shout", spellType = "Slow"}
   {charName = "NuNu", spellName = "Ice Blast", spellType = "Slow"}
   {charName = "Singed", spellName = "Fling", spellType = "Slow"}
   {charName = "Dr. Mundo", spellName = "Infected Cleaver", spellType = "Slow"}
   {charName = "Gangplank", spellName = "Parrrley", spellType = "Slow"}
   {charName = "Renekton", spellName = "Ruthless Predator", spellType = "Stun"}
   {charName = "Nautilus", spellName = "Depth Charge", spellType = "Stun"}
   {charName = "Rammus", spellName = "Puncturing Taunt", spellType = "Silence"}
   {charName = "Rengar", spellName = "Bola Strike", spellType = "Stun"}
   {charName = "Rengar", spellName = "Empowered Bola Strike", spellType = "Stun"}
}

function checkBlock(unit, spell)
   if CanUse("E") and spell.target.name == me.name then
      for _,s in ipairs(spells) do
         if s.charName == unit.name and s.spellName == spell.name then
      		CastSpellTarget("E", me)
      		break
         end
      end
   end
end

AddOnSpell(checkBlock)
SetTimerCallback("Run")