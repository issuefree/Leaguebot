--[[
    Script: IGER's Ryze Spammer v0.4
    Author: PedobearIGER
]]--

if GetSelf().name == "Ryze" then
    local print = printtext
    local version = "0.4"
    
    local masterKey = 32       -- Spacebar (set to nil if you wanna use only one hk for each combo)
    local masterActive = true  -- true: the masterKey has to be pressed for every hotkey feature in this script ; false: You don't have to press the masterKey to use the other hotkeys
    local qKey = 81            -- [Auto-Q Minions; casts a Q on the nearest minion that should die from it] [default: q]
    local wKey = 87            -- [W,Q,E,Q; targets the enemy champion that would most likely die from your attack] [default: w]
    local eKey = 69            -- [Q,W,E,Q; targets the enemy champion that would most likely die from your attack] [default: e]
    local rKey = 84            -- [Q,R,W,Q,E; targets the enemy champion that would most likely die from your attack] [default: t]
    local iKey = 68            -- [Ignite,Q,W,E,Q; targets the enemy champion that would most likely die from your attack] [default: d]
    --local customTarget = 65    -- [Q,W,E,Q; targets the unit targeted by clicking on it] use it if you wanna kill some buffs, the dragon, baron or if you just wanna attack a specific champion.. [default: a]
                               -- SPECIAL: Press the qKey,wKey and eKey at the same time to automatically use Q,W,E and normal autoAttacks on a minions that should die from it  
    local igniteSlot = "D"     --If your ignite is your summonerspell_1  use "D" id it is summonerspell_2 use "F"
    
    local qRange = 650
    local wRange = 625
    local eRange = 675
    local iRange = 600
    local qCombo = false
    local wCombo = false
    local eCombo = false
    local rCombo = false
    local iCombo = false
    local QWEobjects = {}
    local minion = nil
    local bestQMinion = nil
    local player = GetSelf()
    local target = nil
    local playerTeam = nil
    local enemies = {}
    local dont = false
    
    repeat
        if string.format(player.team) == "100" then
            playerTeam = "blue"
        elseif  string.format(player.team) == "200" then  
            playerTeam = "red"
        end
    until playerTeam ~= nil and playerTeam ~= "0"
    for i=1, objManager:GetMaxObjects(), 1 do
        object = objManager:GetObject(i)
        if object ~= nil and ((((object.name == "Blue_Minion_Basic" or object.name == "Blue_Minion_Wizard" or object.name == "Blue_Minion_MechCannon" or object.name == "Blue_Minion_MechMelee") and playerTeam == "red") or ((object.name == "Red_Minion_Basic" or object.name == "Red_Minion_Wizard" or object.name == "Red_Minion_MechCannon" or object.name == "Red_Minion_MechMelee") and playerTeam == "blue")) or object.name == "Dragon" or object.name == "Worm" or object.name == "AncientGolem" or object.name == "LizardElder" or object.name == "GiantWolf" or object.name == "Wraith") then table.insert(QWEobjects,object) end
    end
    
    function OnTick()
        player = GetSelf()
        OnWndMsg()
        OnDraw()
        qDmg = 35+(25*GetSpellLevel("Q"))+(0.4*player.ap)+(player.maxMana*0.065)
        wDmg = 25+(35*GetSpellLevel("W"))+(0.6*player.ap)+(0.045*player.maxMana)
        eDmg = 30+(20*GetSpellLevel("E"))+(0.35*player.ap)+(0.01*player.maxMana)
        iDmg = 45+(25*player.selflevel)
        UpdateMinionTable()
        if masterActive then 
            target = nil
            target = GetWeakEnemy('MAGIC',qRange)
            if iCombo then IgniteCombo(target)
            elseif rCombo then UltCombo(target)
            elseif eCombo and not qCombo and not wCombo then DPSCombo(target)
            elseif wCombo and not qCombo then SnareCombo(target) end
            if #QWEobjects > 0 then
                if qCombo and wCombo and eCombo then
                    AutoQWEMinions()
                elseif qCombo then 
                    AutoQMinions() 
                end
            end
        end
    end
    
    function OnDraw()
        if player.dead == 0 then
            CustomCircle(qRange,6,3,player)
            if target ~= nil then CustomCircle(100,10,3,target) end
        end 
        if bestLasthitMinion ~= nil then CustomCircle(70,10,1,bestLasthitMinion) end
        if bestQMinion ~= nil then CustomCircle(70,10,1,bestQMinion) end
    end
    
    function OnWndMsg()
        if IsKeyDown(masterKey) == 1 then masterActive = true
        else masterActive = false end
        if IsKeyDown(qKey) == 1 then qCombo = true
        else qCombo = false end
        if IsKeyDown(wKey) == 1 then wCombo = true
        else wCombo = false end
        if IsKeyDown(eKey) == 1 then eCombo = true
        else eCombo = false end
        if IsKeyDown(rKey) == 1 then rCombo = true
        else rCombo = false end
        if IsKeyDown(iKey) == 1 then iCombo = true
        else iCombo = false end
        --if IsKeyDown(customTarget) == 1 then cCombo = true
        --else cCombo = false end
    end
    
    function IgniteCombo(target)
        DrawTextObject("IgniteCombo",player,0xFF00FFFF)
        if target == nil then return end
        if IsSpellReady(igniteSlot) == 1 then CastSpellTarget(igniteSlot,target) end
        if IsSpellReady(igniteSlot) == 0 then 
            if IsSpellReady('Q') == 1 then CastSpellTarget("Q",target) end
            if IsSpellReady('Q') == 0 then 
                if IsSpellReady('R') == 1 then CastSpellTarget("R",target) end
                if IsSpellReady('R') == 0 then 
                    if IsSpellReady('W') == 1 then CastSpellTarget("W",target) end
                    if IsSpellReady('W') == 0 then 
                        if IsSpellReady('E') == 1 then CastSpellTarget("E",target) end
                    end
                end
            end
        end
    end
    
    function UltCombo(target)
        DrawTextObject("UltCombo",player,0xFF00FFFF)
        if target == nil then return end
        if IsSpellReady('Q') == 1 then CastSpellTarget("Q",target) end
        if IsSpellReady('Q') == 0 then 
            if IsSpellReady('R') == 1 then CastSpellTarget("R",target) end
            if IsSpellReady('R') == 0 then 
                if IsSpellReady('W') == 1 then CastSpellTarget("W",target) end
                if IsSpellReady('W') == 0 then 
                    if IsSpellReady('E') == 1 then CastSpellTarget("E",target) end
                end
            end
        end
    end
    
    function DPSCombo(target)
        DrawTextObject("DPSCombo",player,0xFF00FFFF)
        if target == nil then return end
        if IsSpellReady('Q') == 1 then CastSpellTarget("Q",target) end
        if IsSpellReady('Q') == 0 then 
            if IsSpellReady('W') == 1 then CastSpellTarget("W",target) end
            if IsSpellReady('W') == 0 then 
                if IsSpellReady('E') == 1 then CastSpellTarget("E",target) end
            end
        end
    end
    
    function SnareCombo(target)
        DrawTextObject("SnareCombo",player,0xFF00FFFF)
        if target == nil then return end
        if IsSpellReady('W') == 1 then CastSpellTarget("W",target) end
        if IsSpellReady('W') == 0 then 
            if IsSpellReady('Q') == 1 then CastSpellTarget("Q",target) end
            if IsSpellReady('Q') == 0 then 
                if IsSpellReady('E') == 1 then CastSpellTarget("E",target) end
            end
        end
    end
    
    function DPSComboB(target)
        if target == nil then return end
        if IsSpellReady('Q') == 1 then CastSpellTarget("Q",target) end
        if IsSpellReady('Q') == 0 then 
            if IsSpellReady('W') == 1 then CastSpellTarget("W",target) end
            if IsSpellReady('W') == 0 then 
                if IsSpellReady('E') == 1 then CastSpellTarget("E",target) end
            end
        end
    end
    
    function AutoQMinions()
        DrawTextObject("AutoQMinions",player,0xFF00FFFF)
        for i,minion in ipairs(QWEobjects) do
            if GetDistance(player,minion) <= qRange and CalcMagicDamage(minion,qDmg) > minion.health and (bestQMinion == nil or GetDistance(player,minion) < GetDistance(player,bestQMinion)) then bestQMinion = minion end
        end
        if bestQMinion ~= nil then CastSpellTarget('Q',bestQMinion) end
    end
    
    function AutoQWEMinions()
        DrawTextObject("AutoQWE",player,0xFF00FFFF)
        for i,unit in ipairs(QWEobjects) do
            if unit.visible == 1 and GetDistance(player,unit) <= qRange and (bestQMinion == nil or GetDistance(player,unit) < GetDistance(player,bestQMinion)) then bestQMinion = unit end
        end
        if bestQMinion ~= nil then DPSComboB(bestQMinion) end
    end
    
    function UpdateMinionTable()
        bestQMinion = nil
        for i,object in rpairs(QWEobjects) do 
            if object == nil or object.dead == 1 then table.remove(QWEobjects,i) end
        end
        for i=1, objManager:GetMaxNewObjects(), 1 do
            local object = objManager:GetNewObject(i)
            if object ~= nil and ((((object.name == "Blue_Minion_Basic" or object.name == "Blue_Minion_Wizard" or object.name == "Blue_Minion_MechCannon" or object.name == "Blue_Minion_MechMelee") and playerTeam == "red") or ((object.name == "Red_Minion_Basic" or object.name == "Red_Minion_Wizard" or object.name == "Red_Minion_MechCannon" or object.name == "Red_Minion_MechMelee") and playerTeam == "blue")) or object.name == "Dragon" or object.name == "Worm" or object.name == "AncientGolem" or object.name == "LizardElder" or object.name == "GiantWolf" or object.name == "Wraith") then table.insert(QWEobjects,object) end    
        end
    end
    
    function CalcMagicDamage(object,dmg)
        if object and dmg and object ~= nil and dmg  ~= nil then
            if object.magicArmor >= 0 then return dmg*(100/(100+object.magicArmor))
            elseif object.magicArmor < 0 then return dmg*(2-(100/(100-object.magicArmor))) end
        end
    end

    function CalcPhysDamage(object,dmg)
        if object and dmg and object ~= nil and dmg  ~= nil then
            if object.armor >= 0 then return dmg*(100/(100+object.armor))
            elseif object.armor < 0 then return dmg*(2-(100/(100-object.armor))) end
        end
    end
    
    function CustomCircle(radius,thickness,color,object,x,y,z)
        if object ~= "" then
            local count = math.floor(thickness/2)
            repeat
                DrawCircleObject(object,radius+count,color)
                count = count-2
            until count == (math.floor(thickness/2)-(math.floor(thickness/2)*2))-2
        elseif x ~= "" and y ~= "" and z~= "" then
            local count = math.floor(thickness/2)
            repeat
                DrawCircle(x,y,z,radius+count,color)
                count = count-2
            until count == (math.floor(thickness/2)-(math.floor(thickness/2)*2))-2
        end
    end
    
    function GetDistance(o1,o2)
        if o1 and o2 and o1 ~= nil and o2 ~= nil then return math.sqrt(math.pow(o1.x - o2.x, 2) + math.pow(o1.z - o2.z, 2)) end
    end
    
    function DistanceIsLessThan(distance,object_1,object_2)
        if object_1 and object_2 and object_1 ~= nil and object_2 ~= nil and (object_1.x-distance) < object_2.x and (object_1.x+distance) > object_2.x and (object_1.z-distance) < object_2.z and (object_1.z+distance) > object_2.z then return true end
        return false
    end
    
    SetTimerCallback("OnTick")
    printtext(" >> IGER's Ryze spammer "..version.." loaded!\n")
end