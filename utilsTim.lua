--[[
    ====================================
    |    Leaguebot Utility Library     |
    |          Version 2.1.0           |
    |                                  |
    ====================================

        This library consolidates functions that are often repeated in scripts as well as including
        multiple classes and additional functions.

    ====================================
    |            How To Use            |
    ====================================
        - add 'require "utils"' to the top of your script, without single quotes.
        - the require is no longer needed in version 2+ since it is now loaded by script_gui

    ====================================
    |            Version Log           |
    ====================================

    1.0.0:
        - Initial Release

    1.0.1:
        - Added additional functions

    1.2.0:
        - Added Script Configuration Menu
        - Fixed 'Class' class.
        - Added support for OnWndMsg function

    1.2.1:
        - Added two new param types to script configuration menu (thanks Dasia!)
        - Fixed some bugs with script configuration menu
        - Added additional functions

    1.2.2:
        - Fixed callback issues caused by latest Leaguebot update
        - Fixed bug where new objects would be checked even if script didn't use the function
        - Added PrintChat as a placeholder function to avoid errors when porting scripts.
        - Updated OnProcessSpell to also return target
        - Added API
        - Added GetTickCount()

    1.2.3:
        - Added Color class

    1.2.4:
        - Added UseItemLocation(item, x, y, z)
        - Added CustomCircle(radius,thickness,color,object,x,y,z) (thanks PEDO)
        - Added mousePos variable which represents your cursor. E.g. GetDistance(mousePos)
        - Added item support with 3 functions - UseAllItems(target), UseTargetItems(target), UseSelfItems(target)

    1.2.5:
        - Fixed a bug that stopped NUMERICUPDOWN loading decimals correctly

    1.3.0:
        - Added GetMEC(radius, range, target) - > Will return the best location for aoe spells to hit as many enemies around the target as possible
        - Added Minion Manager
        - Added constants TEAM_BLUE, TEAM_RED, TEAM_ENEMY
        - Util__OnTick() is no longer required in your scripts. Please remove it.
        - Added ValidTarget(target)
    1.3.1:
        - Added callback for deleted objects. Use function OnDeleteObj(object)

    1.3.2:
        - Fixed bug with ValidTarget
        - Updated GetMEC
        - Added summoner spell functions:
            CastSummonerIgnite(target)
            CastSummonerExhaust(target)
            CastSummonerHeal()
            CastSummonerClarity()
            CastSummonerBarrier()
            CastSummonerClairvoyance(x, y x)
    1.3.3
        - Fixed a bug in Class that would overwrite parent class with member if member was a class created during __init
        - Fixed a bug in GetMEC checking nil vector
        - GetMEC results are now found with pos.x, pos.y, pos.z rather than pos.center.x, pos.center.y, pos.center.z
    1.3.4
        - Fixed bug caused by using GetMEC on single target
    1.3.5
        - Fixed bug in GetLowestHealthEnemyMinion
    1.3.6
        - Updated to hotfix 5

    2.0.0 - 5/19/2012 11:39:00 AM
          - requires script_loader v04
          - requires script_gui v02
          - overhaul of tick system to fix script interop when using OnDraw, OnProcessSpell, OnWndMsg
          - Removed DoSpells, UpdateMessage, checkAndRunFunction
          - Removed print assignment, it is now in script_loader

    2.0.1 - 5/20/2013 12:40:05 PM
          - fix for utils being loaded multiple times for some scripts, due to require casing

    2.0.2 - 5/20/2013 2:04:19 PM
          - undo 2.0.1 change in favor of a case insensitive require wrapper in script_loader

    2.0.3 - 5/20/2013 7:24:36 PM
          - looks like OnCreateObj needed the same fix the rest got, removed FindNewObjects

    2.0.4 - 5/31/2013 12:04:39 PM
          - RegisterLibraryOnTick, RegisterLibraryOnWndMsg, RegisterLibraryOnProcessSpell, RegisterLibraryOnCreateObj

    2.0.5 - 6/3/2013 8:49:27 AM
          - added Common to lua path and SCRIPT_PATH global for easier porting, no longer uses ListScripts for sending to scripts, no more myHero messages when lol not loaded

    2.0.6 - 6/3/2013 11:29:19 AM
          - throws an error if not using the lua jit

    2.0.7 - 6/3/2013 9:56:28 PM
          - added IsScriptActive, fixing the problem knowingly introduced in 2.0.5 where callbacks still ran for disabled scripts

    2.0.8 - 6/9/2013 5:58:59 PM
          - deprecated Util__Ontick(), tick now called directly from dotimercallback in script_loader

    2.0.9 - 6/10/2013 9:18:42 AM
          - revert the change in 2.0.8 for calling tick directly from dotimercallback, cannot support LOADSCRIPT

    2.1.0 - 6/14/2013 11:50:51 AM
          - added UTILS_VERSION global, for script authors

    ====================================
    |               API                |
    ====================================

    Globals

        ----- Callback Functions -----
            These functions can be added to your script and will be automatically called when necessary.

                function OnDraw()                        -- Do any drawing here (circles, text etc).
                function OnProcessSpell(unit, spell)    -- This function is called whenever any spell is cast by anyone, including auto attacks and detected for players,
                                                                minions, towers, everything. This is only called when a spell is first cast so store the spell object if
                                                                you wish to use it later.
                function OnCreateObj(obj)                -- This function is called whenever an object is created in memory, e.g. a new minion or a spell particle.
                                                                This function is only called when the object is first created so store the object if you wish to use
                                                                it later.
                function OnDeleteObj(obj)                -- This function is called whenever an object is deleted, for example a spell particle vanishes like Trynd's ult
                                                                particle, or minions die (including ghost vanished), or shields expire etc.
                function OnWndMsg(msg, key)                -- This function is called whenever a windows message is detected, such as key presses or mouse clicks.
                                                            msg can be something like KEY_DOWN or KEY_UP (see below for details) and key will be the ascii code
                                                            of the key that was pressed e.g. 32 for space.
                                                                : Example usage
                                                                    function OnWndMsg(msg, key)
                                                                        if msg == KEY_DOWN and key == 32 then printtext("We pressed space!") end
                                                                    end

        ----- Global Functions -----
            These functions can simply be used whenever you want them.

                printtext("text")                -- Prints text to the console
                ValidTarget(target)                -- Returns whether the target is valid to attack (alive, enemy etc)
                KeyDown(key)                    -- Returns true or false if key is or isn't pressed. Accepts only ascii key codes e.g. KeyDown(32)
                CanCastSpell(spell)                -- Returns true or false if spell can or cannot be used. Accepts string e.g. CanCastSpell("R")
                MoveToMouse()                    -- Moves your hero to your mouse position
                GetInventorySlot(item)            -- Returns the inventory slot for the given item code. Returns nil if not found
                UseItemOnTarget(item, target)    -- Uses the given item (code) on the given target
                UseItemLocation(item, x, y, z)    -- Uses the given item (code) at the given coords
                GetDistance(p1, p2)                -- Returns the distance in game units between object p1 and p2. Passing only p1 will return the distance
                                                    between you and the given object.
                GetTickCount()                    -- Returns the time passed in milliseconds
                UseAllItems(target)                -- Will use all available items, both those that are cast on an enemy and those cast on yourself
                UseTargetItems(target)            -- Will use all available items that are cast on a target
                UseSelfItems(target)            -- Will use all items that are cast on yourself when close to a target
                                                    Supported Items:
                                                        Blade of the Ruined King
                                                        Bilgewater Cutlass
                                                        Hextech Gunblade
                                                        Deathfire Grasp
                                                        Youmuu's Ghostblade
                                                        Sword of the Divine
                                                        Ravenous Hydra
                                                        Tiamat
                                                        Executioner's Calling
                                                        Randuin's Omen
                CastSummonerIgnite(target)        -- Cast ignite on target
                CastSummonerExhaust(target)        -- Cast exhaust on target
                CastSummonerHeal()                -- Cast summoner heal
                CastSummonerClarity()            -- Cast summoner clarity
                CastSummonerBarrier()            -- Cast summoner barrier
                CastSummonerClairvoyance(x, y x)-- Cast summoner clairvoyance at given coordinates

                CustomCircle(radius,thickness,color,object,x,y,z) -- Draws a custom circle around an object

        ----- Windows Messages -----
            When using the OnWndMsg callback, the following are available as messages

                KEY_DOWN                                -- Keyboard key was pressed
                KEY_UP                                    -- Keyboard key was released
                WM_LBUTTONDOWN                            -- Left mouse button was pressed
                WM_LBUTTONUP                            -- Left mouse button was released
                WM_RBUTTONDOWN                            -- Right mouse button was pressed
                WM_RBUTTONUP                            -- Right mouse button was released

        ----- Global Variables -----
            These variables can be used in your script without having to create them.

                TEAM_BLUE, TEAM_RED, TEAM_ENEMY            -- Represents the teams
                myHero                                    -- Returns your hero object
                mousePos                                 -- Represents your cursor. E.g. GetDistance(mousePos)
                Color                                    -- Returns a colour code.
                                                            Usage: Color.Red
                                                            Available Colours:
                                                                    Black
                                                                    Gray
                                                                    White
                                                                    Azure
                                                                    Brown
                                                                    Olive
                                                                    Red
                                                                    Maroon
                                                                    Coral
                                                                    Orange
                                                                    Yellow
                                                                    Lime
                                                                    Green
                                                                    Cyan
                                                                    LightBlue
                                                                    SkyBlue
                                                                    Blue
                                                                    Purple
                                                                    Pink
                                                                    DeepPink

    Classes

        -----> Medium Enclosing Circle <-----
            This class allows you to return the position that would hit the most
            enemies around your target when using an aoe spell

            Functions:
                GetMEC(radius, range, target)                    -- returns pos

        -----> Class <-----
            This class allows you to treat code as a class object similar to those found in other languages.
            Simply use ClassName = class(). See classes below for examples.

        -----> Minion Manager <-----
            This class alows you to retrieve lists of minions

            Functions:
                GetLowestHealthEnemyMinion(range)        -- returns the lowest health enemy minion in the given range
                GetAllyMinions(sortMode)                -- returns a list of ally minions sorted by the given sort mode
                GetEnemyMinions(sortMode)                -- returns a list of enemy minions sorted by the given sort mode
                    Sort Modes:
                        MINION_SORT_HEALTH_ASC            -- sort by health in ascending order (lowest hp first)
                        MINION_SORT_HEALTH_DEC            -- sort by health in descending order (highest hp first)
                        MINION_SORT_MAXHEALTH_ASC        -- sort by max health in ascending order
                        MINION_SORT_MAXHEALTH_DEC        -- sort by max health in descending order
                        MINION_SORT_AD_ASC                -- sort by ad in ascending order
                        MINION_SORT_AD_DEC                -- sort by ad in descending order

        -----> Vector <-----
            Allows you to create and manipulate vectors.

            Functions:
                VectorType(v)                          -- return if as vector
                VectorIntersection(a1,b1,a2,b2)        -- return the Intersection of 2 lines
                VectorDirection(v1,v2,v)               -- return direction of a vector
                VectorPointProjectionOnLine(v1, v2, v) -- return a vector on line v1-v2 closest to v
                Vector(a,b,c)                          -- return a vector from x,y,z pos or from another vector

            Members:
                x
                y
                z

            Vector Functions:
                vector:clone()                           -- return a new Vector from vector
                vector:unpack()                          -- x, z
                vector:len2()                            -- return vector^2
                vector:len2(v)                           -- return vector^v
                vector:len()                             -- return vector length
                vector:dist(v)                           -- distance between 2 vectors (v and vector)
                vector:normalize()                       -- normalize vector
                vector:normalized()                      -- return a new Vector normalize from vector
                vector:rotate(phiX, phiY, phiZ)          -- rotate the vector by phi angle
                vector:rotated(phiX, phiY, phiZ)         -- return a new Vector rotate from vector by phi angle
                vector:projectOn(v)                      -- return a new Vector from vector projected on v
                vector:mirrorOn(v)                       -- return a new Vector from vector mirrored on v
                vector:center(v)                         -- return center between vector and v
                    vector:crossP()                      -- return cross product of vector
                    vector:dotP()                        -- return dot product of vector

                vector:polar()                           -- return the angle from axe
                vector:angleBetween(v1, v2)              -- return the angle formed from vector to v1,v2
                vector:compare(v)                        -- compare vector and v
                vector:perpendicular()                   -- return new Vector rotated 90? rigth
                vector:perpendicular2()                  -- return new Vector rotated 90? left

        -----> Script Configuration Menu <-----
            Allows you to create in-game menus.

                Functions:
                    scriptConfig("Visible Name", "UniqueIdentifier")
                    :addParam
                    :permaShow

                Available param types:
                    SCRIPT_PARAM_ONKEYDOWN                 -- Returns true/false
                    SCRIPT_PARAM_ONOFF                     -- Returns true/false
                    SCRIPT_PARAM_ONKEYTOGGLE             -- Returns true/false
                    SCRIPT_PARAM_INFO                     -- No return
                    SCRIPT_PARAM_NUMERICUPDOWN             -- Returns selected value
                    SCRIPT_PARAM_DOMAINUPDOWN             -- Returns selected index

                Usage:
                    TestMenu = scriptConfig("Test Script Config", "test")
                        This will create a new menu with the visible name "Test Script Config" and "test" as the unique identifier.

                    TestMenu:addParam("TestP1", "Test Param 1", SCRIPT_PARAM_ONKEYDOWN, false, 32)
                        This will create a parameter called "TestP1", it will be displayed as "Test Param 1".
                        SCRIPT_PARAM_ONKEYDOWN means it will be true when the key is pressed.
                        false means it's disabled by default. 32 is the key.

                    TestMenu:addParam("TestP2", "Test Param 2", SCRIPT_PARAM_ONOFF, false)
                        This will create a parameter called "TestP2", it will be displayed as "Test Param 2".
                        SCRIPT_PARAM_ONOFF means you can toggle it on or off with the in-game menu.
                        false means it's disabled by default.

                    TestMenu:addParam("TestP3", "Test Param 3", SCRIPT_PARAM_ONKEYTOGGLE, false, 32)
                        This will create a parameter called "TestP3", it will be displayed as "Test Param 3".
                        SCRIPT_PARAM_ONKEYTOGGLE means you can toggle it on or off with the in-game menu and with a key.
                        false means it's disabled by default. 32 is the key.

                    TestMenu:addParam("TestP4", "Test Param 4", SCRIPT_PARAM_INFO)
                        This will create a parameter called "TestP4", it will be displayed as "Test Param 4".
                        SCRIPT_PARAM_INFO is used simply for displaying a row of text in the menu. It has no return value.

                    TestMenu:addParam("TestP5", "Test Number Spin", SCRIPT_PARAM_NUMERICUPDOWN, 5, 72, 0, 100, 10)
                        This will create a parameter called "TestP5", it will be displayed as "Test Number Spin".
                        SCRIPT_PARAM_NUMERICUPDOWN is used for allowing users to iterate through a list of numbers.
                        5 is the default value, 72 is the key, 0 is min value, 100 is max value, 10 is step.
                        This example would start at 5, pressing the key would loop through 5-15-25-35-45-55-65-75-85-95 then return back to 5.

                    TestMenu:addParam("TestP6", "Test String Spin", SCRIPT_PARAM_DOMAINUPDOWN, 5, 84, {"one","two","three","four","five","six","seven","eight","nine","ten"})
                        This will create a parameter called "TestP6", it will be displayed as "Test String Spin".
                        SCRIPT_PARAM_DOMAINUPDOWN allows you to create the same behaviour as NUMERICUPDOWN but with strings.
                        5 is default index, 84 is key, finally the list of strings. This example would start at index 5 and would display "five" to the user.
                        Pressing the key would iterate as "six"-"seven"-"eight"-"nine"-"ten"-"one" etc.
                        The param holds the index of the selected value, so if the user has selected six...TestMenu.TestP6 == 6.

                Example Script:
                    require "Utils"

                    function Run()
                        if TestConfig.TestP2 then MoveToMouse() end
                        if TestConfig.TestP3 then printtext("I turned on TestP3!\n") end
                    end

                    TestConfig = scriptConfig("Test Script Config", "test")
                    TestConfig:addParam("TestP1", "Test Param 1", SCRIPT_PARAM_ONKEYDOWN, false, 32)
                    TestConfig:addParam("TestP2", "Test Param 2", SCRIPT_PARAM_ONOFF, false)
                    TestConfig:addParam("TestP3", "Test Param 3", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("A"))
                    TestConfig:addParam("TestP4", "Test Param 4", SCRIPT_PARAM_INFO)
                    TestConfig:addParam("TestNumSpin", "Test Number Spin", SCRIPT_PARAM_NUMERICUPDOWN, 5, 72, 0, 200, 10)
                    TestConfig:addParam("TestStrSpin", "Test String Spin", SCRIPT_PARAM_DOMAINUPDOWN, 5, 84, {"one","two","three","four","five","six","seven","eight","nine","ten"})
                    TestConfig:permaShow("TestP1")
                    TestConfig:permaShow("TestP2")
                    SetTimerCallback("Run")

--]]

------------ > Don't touch anything below here < --------------

if not jit then
    local msg = "ERROR: The Lua JIT dll is required to use utils 2+"
    PrintError(msg)
    error(msg)
end

UTILS_VERSION = 210

--print=printtext -- new print is defined in script_loader
KEY_DOWN = 256
KEY_UP = 257
WM_LBUTTONDOWN = 513
WM_LBUTTONUP = 514
WM_RBUTTONDOWN = 516
WM_RBUTTONUP = 517
HookWnd()
HookSpell()
myHero = GetSelf()
mousePos = {}
TEAM_BLUE, TEAM_RED = 100, 200
if myHero ~= nil then
    TEAM_ENEMY = (myHero.team == TEAM_BLUE and TEAM_RED or TEAM_BLUE)
end

local libraryOnTick = {}
local libraryOnWndMsg = {}
local libraryOnProcessSpell = {}
local libraryOnCreateObj = {}

Color = {
    Black = 0xFF000000,
    Gray = 0xFF808080,
    White = 0xFFFFFFFF,
    Azure = 0xFFF0FFFF,
    Brown = 0xFFCD853F,
    Olive = 0xFF8FBC8F,
    Red = 0xFFFF0000,
    Maroon = 0xFF800000,
    Coral = 0xFFFF7F50,
    Orange = 0xFFFF8000,
    Yellow = 0xFFFFFF00,
    Lime = 0xFFADFF2F,
    Green = 0xFF32CD32,
    Cyan = 0xFF00FFFF,
    LightBlue = 0xFF1E90FF,
    SkyBlue = 0xFF87CEFA,
    Blue = 0xFF0000FF,
    Purple = 0xFFFF00FF,
    Pink = 0xFFFFA8CC,
    DeepPink = 0xFFFF1493
}

local Summoners =
                {
                    Ignite = {Key = nil, Name = 'SummonerDot'},
                    Exhaust = {Key = nil, Name = 'SummonerExhaust'},
                    Heal = {Key = nil, Name = 'SummonerHeal'},
                    Clarity = {Key = nil, Name = 'SummonerMana'},
                    Barrier = {Key = nil, Name = 'SummonerBarrier'},
                    Clairvoyance = {Key = nil, Name = 'SummonerClairvoyance'}
                }

if myHero ~= nil then
    for _, Summoner in pairs(Summoners) do
        if myHero.SummonerD == Summoner.Name then
            Summoner.Key = "D"
        elseif myHero.SummonerF == Summoner.Name then
            Summoner.Key = "F"
        end
    end
end

mousePos = {x=0,y=0,z=0}
function Util__Callback()
    --printtext('~')
    SendTickToLibraries()
    HandleOnDraw()
    HandleOnProcessSpell()
    HandleOnWndMsg()
    HandleOnCreateObj()
    --FindDeletedObjects()
    minionManager__OnTick()
    mousePos.x = GetCursorWorldX() -- faster
    mousePos.y = GetCursorWorldY()
    mousePos.z = GetCursorWorldZ()
end

function Util__OnTick()
    -- deprecated to prevent double ticking
end

-- library callbacks, dont need draw --
function RegisterLibraryOnTick(fn)
    libraryOnTick[fn] = true
end

function RegisterLibraryOnWndMsg(fn)
    libraryOnWndMsg[fn] = true
end

function RegisterLibraryOnProcessSpell(fn)
    libraryOnProcessSpell[fn] = true
end

function RegisterLibraryOnCreateObj(fn)
    libraryOnCreateObj[fn] = true
end

function SendMessagesToFunction(messages, fn)
    assert(messages~=nil, 'messages cannot be nil')
    assert(fn~=nil, 'fn cannot be nil')
    for i=1,#messages do
        local msg, key = unpack(messages[i])
        fn(msg, key)
    end
end

function SendObjectsToFunction(objects, fn)
    assert(objects~=nil, 'objects cannot be nil')
    assert(fn~=nil, 'fn cannot be nil')
    for i=1,#objects do
        local object = objects[i]
        fn(object)
    end
end

function SendSpellsToFunction(spells, fn)
    assert(spells~=nil, 'spells cannot be nil')
    assert(fn~=nil, 'fn cannot be nil')
    for i=1,#spells do
        local spell = spells[i]
        fn(spell.unit, spell)
    end
end

function SendMessagesToLibraries(messages)
    local dict = libraryOnWndMsg
    for fn,bool in pairs(dict) do
        if bool then
            SendMessagesToFunction(messages, fn)
        end
    end
end

function SendObjectsToLibraries(objects)
    local dict = libraryOnCreateObj
    for fn,bool in pairs(dict) do
        if bool then
            SendObjectsToFunction(objects, fn)
        end
    end
end

function SendSpellsToLibraries(spells)
    local dict = libraryOnProcessSpell
    for fn,bool in pairs(dict) do
        if bool then
            SendSpellsToFunction(spells, fn)
        end
    end
end

function SendTickToLibraries()
    local dict = libraryOnTick
    for fn,bool in pairs(dict) do
        if bool then
            fn()
        end
    end
end

-- send msg to all script
function HandleOnWndMsg()
    local messages = {}
    local msg, key, param = GetMessage()
    local g=0
    while (msg ~= nil) do
        table.insert(messages, {msg,key,param})
        msg,key,param=GetMessage()
    end
    SendMessagesToLibraries(messages)
    SendMessagesToFunction(messages, SC__OnWndMsg)
    for i,fn in ipairs(GetScriptFunctions('OnWndMsg')) do
        SendMessagesToFunction(messages, fn)
    end
end

function HandleOnCreateObj()
    local objects = {}
    for i=1, objManager:GetMaxNewObjects() do
        local object = objManager:GetNewObject(i)
        if object ~= nil then
            table.insert(objects, object)
        end
    end
    SendObjectsToLibraries(objects)
    SendObjectsToFunction(objects, minionManager__OnCreateObj)
    for i,fn in ipairs(GetScriptFunctions('OnCreateObj')) do
        SendObjectsToFunction(objects, fn)
    end
end

-- send spells to all scripts' OnProcessSpell
function HandleOnProcessSpell()
    local spells={}
    local a={GetCastSpell()}
    local g=0
    while (a~=nil and a[1] ~= nil and g<200) do
        local spell={}
        local startPos={}
        local endPos={}
        spell.unit=a[1]
        spell.name=a[2]
        startPos.x=a[3]
        startPos.y=a[4]
        startPos.z=a[5]
        endPos.x=a[6]
        endPos.y=a[7]
        endPos.z=a[8]
        spell.target=a[12]
        spell.startPos=startPos
        spell.endPos=endPos
        --
        table.insert(spells, spell)
        --
        a={GetCastSpell()}
        g=g+1
    end
    SendSpellsToLibraries(spells)
    for i,fn in ipairs(GetScriptFunctions('OnProcessSpell')) do
        SendSpellsToFunction(spells, fn)
    end
end

function HandleOnDraw()
    --printtext('.')
    for i,fn in ipairs(GetScriptFunctions('OnDraw')) do
        fn()
    end
    SC__OnDraw()
end

function IsScriptActive(num)
    local key = tostring(num)
    return activescripts[key]
end

-- return list of functions with the name func_name for all scripts
function GetScriptFunctions(function_name)
    local functions = {}
    -- now we actually loop the scriptlist
    -- skip 0, which is script_gui and utils
    for i=1,#scriptlist do
        if IsScriptActive(i) then
            local scriptenv = scriptlist[i]
            if scriptenv~=nil then
                local fn = scriptenv[function_name]
                if fn ~= nil then
                    table.insert(functions, fn)
                end
            end
        end
    end
    return functions
end

---

function KeyDown(key)
    return (IsKeyDown(key) == 1)
end

function CanCastSpell(spell)
    return (CanUseSpell(spell) == 1)
end

function MoveToMouse()
    MoveToXYZ(GetCursorWorldX(), GetCursorWorldY(), GetCursorWorldZ())
end

function GetTickCount()
    return GetClock()
end

function PrintChat(text)
    --Function to supress errors while porting
end

function CastSummonerIgnite(target)
    if ValidTarget(target) and Summoners.Ignite.Key ~= nil then
        CastSpellTarget(Summoners.Ignite.Key, target)
    end
end

function CastSummonerExhaust(target)
    if ValidTarget(target) and Summoners.Exhaust.Key ~= nil then
        CastSpellTarget(Summoners.Exhaust.Key, target)
    end
end

function CastSummonerHeal()
    if Summoners.Heal.Key ~= nil then
        CastSpellTarget(Summoners.Heal.Key, myHero)
    end
end

function CastSummonerClarity()
    if Summoners.Clarity.Key ~= nil then
        CastSpellTarget(Summoners.Clarity.Key, myHero)
    end
end

function CastSummonerBarrier()
    if Summoners.Barrier.Key ~= nil then
        CastSpellTarget(Summoners.Barrier.Key, myHero)
    end
end

function CastSummonerClairvoyance(x, y, z)
    if Summoners.Clairvoyance.Key ~= nil then
        CastSpellXYZ(Summoners.Clairvoyance.Key, x, y, z)
    end
end

function GetInventorySlot(item)
    if GetInventoryItem(1) == item then
        return 1
    elseif GetInventoryItem(2) == item then
        return 2
    elseif GetInventoryItem(3) == item then
        return 3
    elseif GetInventoryItem(4) == item then
        return 4
    elseif GetInventoryItem(5) == item then
        return 5
    elseif GetInventoryItem(6) == item then
        return 6
    end
    return nil
end

function UseItemOnTarget(item, target)
    local itemSlot = GetInventorySlot(item)
    if itemSlot ~= nil then
        CastSpellTarget(tostring(itemSlot), target)
    end
end

function UseItemLocation(item, x, y, z)
    local itemSlot = GetInventorySlot(item)
    if itemSlot ~= nil then
        CastSpellXYZ(tostring(itemSlot),x,y,z)
    end
end

function FindDeletedObjects()
    if functionExists("OnDeleteObj") then
        for i = 1, objManager:GetMaxDelObjects(), 1 do
            local object = {objManager:GetDelObject(i)}
            local ret={}
            ret.index=object[1]
            ret.name=object[2]
            ret.charName=object[3]
            ret.x=object[4]
            ret.y=object[5]
            ret.z=object[6]
            if object ~= nil then
                scriptlist[GetScriptNumber()]["OnDeleteObj"](ret)
            end
        end
    end
end

function GetDistance(p1, p2)
    p2 = p2 or myHero
    if not p1 or not p1.x or not p2.x then
				print(debug.traceback())
                return 99999
         end

    return math.sqrt(GetDistanceSqr(p1, p2))

end

function ValidTarget(object, distance, enemyTeam)
    if distance == nil and enemyTeam == nil then
        return (object ~= nil and object.visible == 1 and object.dead == 0 and object.invulnerable == 0)
    end
    local enemyTeam = (enemyTeam ~= false)
    return object ~= nil and (object.team ~= myHero.team) == enemyTeam and object.visible == 1 and object.dead == 0 and (enemyTeam == false or object.invulnerable == 0) and (distance == nil or GetDistance(object) <= distance)
end

function ValidTargetNear(object, distance, target)
    return object ~= nil and object.team == target.team and object.visible == 1 and object.dead == 0 and GetDistanceSqr(target, object) <= distance * distance
end

function GetDistanceSqr(p1, p2)
    p2 = p2 or myHero
    return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

local items = {
        BRK = {id=3153, range = 500, reqTarget = true, slot = nil},        -- Blade of the Ruined King
        BWC = {id=3144, range = 400, reqTarget = true, slot = nil},        -- Bilgewater Cutlass
        HGB = {id=3146, range = 400, reqTarget = true, slot = nil},        -- Hextech Gunblade
        DFG = {id=3128, range = 750, reqTarget = true, slot = nil},        -- Deathfire Grasp
        YGB = {id=3142, range = 350, reqTarget = false, slot = nil},    -- Youmuu's Ghostblade
        STD = {id=3131, range = 350, reqTarget = false, slot = nil},    -- Sword of the Divine
        RSH = {id=3074, range = 350, reqTarget = false, slot = nil},    -- Ravenous Hydra
        TMT = {id=3077, range = 350, reqTarget = false, slot = nil},    -- Tiamat
        EXE = {id=3123, range = 350, reqTarget = false, slot = nil},    -- Executioner's Calling
        RAN = {id=3143, range = 350, reqTarget = false, slot = nil},    -- Randuin's Omen
        }

function UseAllItems(target)
    for _,item in pairs(items) do
        item.slot = GetInventorySlot(item.id)
        if item.slot ~= nil then
            if item.reqTarget and GetDistance(target) < item.range then
                CastSpellTarget(tostring(item.slot), target)
            elseif GetDistance(target) < 450 then
                CastSpellTarget(tostring(item.slot), myHero)
            end
        end
    end
end

function UseTargetItems(target)
    for _,item in pairs(items) do
        item.slot = GetInventorySlot(item.id)
        if item.slot ~= nil then
            if item.reqTarget and GetDistance(target) < item.range then
                CastSpellTarget(tostring(item.slot), target)
            end
        end
    end
end

function UseSelfItems(target)
    for _,item in pairs(items) do
        item.slot = GetInventorySlot(item.id)
        if item.slot ~= nil then
            if not item.reqTarget and GetDistance(target) < 450 then
                    CastSpellTarget(tostring(item.slot), target)
            end
        end
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

function functionExists(name)
    return scriptlist[GetScriptNumber()][name] ~= nil
end

--################## CLASS ##################--
function class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function (c, ...)
        local instance = setmetatable({}, cls)
        if cls.__init then
            cls.__init(instance, ...)
        end
        return instance
    end})
end
--################## END CLASS ##################--

--################## VECTOR CLASS ##################--
Vector = class()

function VectorType(v)
    return v and v.x and type(v.x) == "number" and ((v.y and type(v.y) == "number") or (v.z and  type(v.z) == "number"))
end

function VectorIntersection(a1, b1, a2, b2)
    assert(VectorType(a1) and VectorType(b1) and VectorType(a2) and VectorType(b2), "VectorIntersection: wrong argument types (4 <Vector> expected)")
    if math.close(b1.x, 0) and math.close(b2.z, 0) then return Vector(a1.x, a2.z) end
    if math.close(b1.z, 0) and math.close(b2.x, 0) then return Vector(a2.x, a1.z) end
    local m1 = (not math.close(b1.x, 0)) and b1.z / b1.x or 0
    local m2 = (not math.close(b2.x, 0)) and b2.z / b2.x or 0
    if math.close(m1, m2) then return nil end
    local c1 = a1.z - m1 * a1.x
    local c2 = a2.z - m2 * a2.x
    local ix = (c2 - c1) / (m1 - m2)
    local iy = m1 * ix + c1
    if math.close(b1.x, 0) then return Vector(a1.x, a1.x * m2 + c2) end
    if math.close(b2.x, 0) then return Vector(a2.x, a2.x * m1 + c1) end
    return Vector(ix, iy)
end

function VectorDirection(v1, v2, v)
    assert(VectorType(v1) and VectorType(v2) and VectorType(v), "VectorDirection: wrong argument types (3 <Vector> expected)")
    return (v1.x - v2.x) * (v.z - v2.z) - (v.x - v2.x) * (v1.z - v2.z)
end

function VectorPointProjectionOnLine(v1, v2, v)
    assert(VectorType(v1) and VectorType(v2) and VectorType(v), "VectorPointProjectionOnLine: wrong argument types (3 <Vector> expected)")
    local line = Vector(v2) - v1
    local t = ((-(v1.x * line.x - line.x * v.x + (v1.z - v.z) * line.z)) / line:len2())
    return (line * t) + v1
end

-- INSTANCED FUNCTIONS
function Vector:__init(a, b, c)
    if a == nil then
        self.x, self.y, self.z = 0.0, 0.0, 0.0
    elseif b == nil then
        assert(VectorType(a), "Vector: wrong argument types (expected nil or <Vector> or 2 <number> or 3 <number>)")
        self.x, self.y, self.z = a.x, a.y, a.z
    else
        assert(type(a) == "number" and (type(b) == "number" or type(c) == "number"), "Vector: wrong argument types (<Vector> or 2 <number> or 3 <number>)")
        self.x = a
        if b and type(b) == "number" then self.y = b end
        if c and type(c) == "number" then self.z = c end
    end
end

function Vector:__type()
    return "Vector"
end

function Vector:__add(v)
    assert(VectorType(v) and VectorType(self), "add: wrong argument types (<Vector> expected)")
    return Vector(self.x + v.x, (v.y and self.y) and self.y + v.y, (v.z and self.z) and self.z + v.z)
end


function Vector:__sub(v)
    assert(VectorType(v) and VectorType(self), "Sub: wrong argument types (<Vector> expected)")
    return Vector(self.x - v.x, (v.y and self.y) and self.y - v.y, (v.z and self.z) and self.z - v.z)
end

function Vector.__mul(a, b)
    if type(a) == "number" and VectorType(b) then
        return Vector({ x = b.x * a, y = b.y and b.y * a, z = b.z and b.z * a })
    elseif type(b) == "number" and VectorType(a) then
        return Vector({ x = a.x * b, y = a.y and a.y * b, z = a.z and a.z * b })
    else
        assert(VectorType(a) and VectorType(b), "Mul: wrong argument types (<Vector> or <number> expected)")
        return a:dotP(b)
    end
end

function Vector.__div(a, b)
    if type(a) == "number" and VectorType(b) then
        return Vector({ x = a / b.x, y = b.y and a / b.y, z = b.z and a / b.z })
    else
        assert(VectorType(a) and type(b) == "number", "Div: wrong argument types (<number> expected)")
        return Vector({ x = a.x / b, y = a.y and a.y / b, z = a.z and a.z / b })
    end
end

function Vector.__lt(a, b)
    assert(VectorType(a) and VectorType(b), "__lt: wrong argument types (<Vector> expected)")
    return a:len() < b:len()
end

function Vector.__le(a, b)
    assert(VectorType(a) and VectorType(b), "__le: wrong argument types (<Vector> expected)")
    return a:len() <= b:len()
end

function Vector:__eq(v)
    assert(VectorType(v), "__eq: wrong argument types (<Vector> expected)")
    return self.x == v.x and self.y == v.y and self.z == v.z
end

function Vector:__unm() --redone, added check for y and z
    return Vector(-self.x, self.y and -self.y, self.z and -self.z)
end

function Vector:__vector(v)
    assert(VectorType(v), "__vector: wrong argument types (<Vector> expected)")
    return self:crossP(v)
end

function Vector:__tostring()
    if self.y and self.z then
        return "(" .. self.x .. "," .. self.y .. "," .. self.z")"
    else
        return "(" .. self.x .. "," .. self.y or self.z .. ")"
    end
end

function Vector:clone()
    return Vector(self)
end

function Vector:unpack()
    return self.x, self.y, self.z
end

function Vector:len2(v)
    assert(v == nil or VectorType(v), "dist: wrong argument types (<Vector> expected)")
    local v = v and Vector(v) or self
    return self.x * v.x + (self.y and self.y * v.y or 0) + (self.z and self.z * v.z or 0)
end

function Vector:len()
    return math.sqrt(self:len2())
end

function Vector:dist(v)
    assert(VectorType(v), "dist: wrong argument types (<Vector> expected)")
    local a = self - v
    return a:len()
end

function Vector:normalize()
    local a = self:len()
    self.x = self.x / a
    self.y = self.y / a
    self.z = self.z / a
end

function Vector:normalized()
    local a = self:clone()
    a:normalize()
    return a
end

function Vector:center(v)
    assert(VectorType(v), "center: wrong argument types (<Vector> expected)")
    return Vector((self + v) / 2)
end

function Vector:crossP(other)
    assert(self.y and self.z and other.y and other.z, "crossP: wrong argument types (3 Dimensional <Vector> expected)")
    return Vector({
        x = other.z * self.y - other.y * self.z,
        y = other.x * self.z - other.z * self.x,
        z = other.y * self.x - other.x * self.y
    })
end

function Vector:dotP(other)
    assert(VectorType(other), "dotP: wrong argument types (<Vector> expected)")
    return self.x * other.x + (self.y and (self.y * other.y) or 0) + (self.z and (self.z * other.z) or 0)
end

function Vector:projectOn(v)
    assert(VectorType(v), "projectOn: invalid argument: cannot project Vector on " .. type(v))
    if type(v) ~= "Vector" then v = Vector(v) end
    local s = self:len2(v) / v:len2()
    return Vector(v * s)
end

function Vector:mirrorOn(v)
    assert(VectorType(v), "mirrorOn: invalid argument: cannot mirror Vector on " .. type(v))
    return self:projectOn(v) * 2
end

function Vector:sin(v)
    assert(VectorType(v), "sin: wrong argument types (<Vector> expected)")
    if type(v) ~= "Vector" then v = Vector(v) end
    local a = self:__vector(v)
    return math.sqrt(a:len2() / (self:len2() * v:len2()))
end

function Vector:cos(v)
    assert(VectorType(v), "cos: wrong argument types (<Vector> expected)")
    if type(v) ~= "Vector" then v = Vector(v) end
    return self:len2(v) / math.sqrt(self:len2() * v:len2())
end

function Vector:angle(v)
    assert(VectorType(v), "angle: wrong argument types (<Vector> expected)")
    return math.acos(self:cos(v))
end

function Vector:affineArea(v)
    assert(VectorType(v), "affineArea: wrong argument types (<Vector> expected)")
    if type(v) ~= "Vector" then v = Vector(v) end
    local a = self:__vector(v)
    return math.sqrt(a:len2())
end

function Vector:triangleArea(v)
    assert(VectorType(v), "triangleArea: wrong argument types (<Vector> expected)")
    return self:affineArea(v) / 2
end

function Vector:rotateXaxis(phi)
    assert(type(phi) == "number", "Rotate: wrong argument types (expected <number> for phi)")
    local c, s = math.cos(phi), math.sin(phi)
    self.y, self.z = self.y * c - self.z * s, self.z * c + self.y * s
end

function Vector:rotateYaxis(phi)
    assert(type(phi) == "number", "Rotate: wrong argument types (expected <number> for phi)")
    local c, s = math.cos(phi), math.sin(phi)
    self.x, self.z = self.x * c + self.z * s, self.z * c - self.x * s
end

function Vector:rotateZaxis(phi)
    assert(type(phi) == "number", "Rotate: wrong argument types (expected <number> for phi)")
    local c, s = math.cos(phi), math.sin(phi)
    self.x, self.y = self.x * c - self.z * s, self.y * c + self.x * s
end

-- TODO
function Vector:rotate(phiX, phiY, phiZ)
    assert(type(phiX) == "number" and type(phiY) == "number" and type(phiZ) == "number", "Rotate: wrong argument types (expected <number> for phi)")
    if phiX ~= 0 then self:rotateXaxis(phiX) end
    if phiY ~= 0 then self:rotateYaxis(phiY) end
    if phiZ ~= 0 then self:rotateZaxis(phiZ) end
end

function Vector:rotated(phiX, phiY, phiZ)
    assert(type(phiX) == "number" and type(phiY) == "number" and type(phiZ) == "number", "Rotated: wrong argument types (expected <number> for phi)")
    local a = self:clone()
    a:rotate(phiX, phiY, phiZ)
    return a
end

-- not yet full 3D functions

function Vector:polar()
    if math.close(self.x, 0) then
        if self.z > 0 then return 90
        elseif self.z < 0 then return 270
        else return 0
        end
    else
        local theta = math.deg(math.atan(self.z / self.x))
        if self.x < 0 then theta = theta + 180 end
        if theta < 0 then theta = theta + 360 end
        return theta
    end
end

function Vector:angleBetween(v1, v2)
    assert(VectorType(v1) and VectorType(v2), "angleBetween: wrong argument types (2 <Vector> expected)")
    local p1, p2 = (-self + v1), (-self + v2)
    local theta = p1:polar() - p2:polar()
    if theta < 0 then theta = theta + 360 end
    if theta > 180 then theta = 360 - theta end
    return theta
end

function Vector:compare(v)
    assert(VectorType(v), "compare: wrong argument types (<Vector> expected)")
    local ret = self.x - v.x
    if ret == 0 then ret = self.z - v.z end
    return ret
end

function Vector:perpendicular()
    return Vector(-self.z, self.y, self.x)
end

function Vector:perpendicular2()
    return Vector(self.z, self.y, -self.x)
end
--################## END VECTOR CLASS ##################--

--################## START SCRIPT CONFIG CLASS ##################--
scriptConfig = class()

SCRIPT_PARAM_ONOFF = 1
SCRIPT_PARAM_ONKEYDOWN = 2
SCRIPT_PARAM_ONKEYTOGGLE = 3
SCRIPT_PARAM_SLICE = 4 -- Do not use
SCRIPT_PARAM_INFO = 5
SCRIPT_PARAM_HIDDEN = 6
SCRIPT_PARAM_NUMERICUPDOWN = 7
SCRIPT_PARAM_DOMAINUPDOWN = 8

_SC = {init = true, initDraw = true, menuKey = 16, configFile = "./scripts.cfg", useTS = false, menuIndex = -1, instances = {}, _changeKey = false, _slice = false}

function CreateConfig()
    local f=io.open("./scripts.cfg","r")
    if f~=nil then
        io.close(f)
    else
        f = io.open("./scripts.cfg", "w")
        f:write("[Master]\npx = 10\npy = 600\ny = 500\nx = 23\niCount = 0")
        f:close()
    end
end
CreateConfig()

function __SC__remove(name)
    local file = io.open(_SC.configFile, "a+")
    local nameFound, keepLine, content = false, true, {}
    for line in file:lines() do
        if not keepLine and string.find(line, "%[") then keepLine = true end
        if keepLine and string.find(line, "%["..name.."%]") then keepLine, nameFound = false, true end
        if keepLine then table.insert(content, line) end
    end
    file:close()
    if nameFound then
        file = io.open(_SC.configFile, "w+")
        for i = 1, #content do
            file:write(string.format("%s\n", content[i]))
        end
        file:close()
    end
end

function __SC__load(name)
    local keepLine, config = false, {}
    local file = io.open(_SC.configFile, "a+")
    for line in file:lines() do
        if keepLine and string.find(line, "%[") then keepLine = false end
        if not keepLine and string.find(line, "%["..name.."%]") then keepLine = true
        elseif keepLine then
            local key, value = line:match("(.-)="), line:match("=(.+)")
            key = key:find('^%s*$') and '' or key:match('^%s*(.*%S)')
            value = value:find('^%s*$') and '' or value:match('^%s*(.*%S)')
            if value == "false" or value == "true" then value = (value == "true")
            elseif string.gsub(value,"%d+", ""):gsub("%-", ""):gsub("%.", "") == "" then
                value = tonumber(value)
            end
            if name ~= "Master" then config[key..'.'] = value else config[key] = value end
        end
    end
    return config
end

function __SC__save(name, content)
    __SC__remove(name)
    local file = io.open(_SC.configFile, "a")
    file:write("["..name.."]\n")
    for i = 1, #content do
        file:write(string.format("%s\n", content[i]))
    end
    file:close()
end

function __SC__saveMenu()
    __SC__save("Menu", {"menuKey = "..tostring(_SC.menuKey), "draw.x = "..tostring(_SC.draw.x), "draw.y = "..tostring(_SC.draw.y), "pDraw.x = "..tostring(_SC.pDraw.x), "pDraw.y = "..tostring(_SC.pDraw.y)})
    _SC.master.x = _SC.draw.x
    _SC.master.y = _SC.draw.y
    _SC.master.px = _SC.pDraw.x
    _SC.master.py = _SC.pDraw.y
    __SC__saveMaster()
end

function __SC__saveMaster()
    local config = {}
    local P, PS, I = 0, 0, 0
    for index, instance in pairs(_SC.instances) do
        I = I + 1
        P = P + #instance._param
        PS = PS + #instance._permaShow
    end
    _SC.master["I".._SC.masterIndex] = I
    _SC.master["P".._SC.masterIndex] = P
    _SC.master["PS".._SC.masterIndex] = PS
    if not _SC.master.useTS and _SC.useTS then _SC.master.useTS = true end
    for var, value in pairs(_SC.master) do
        table.insert(config, tostring(var).." = "..tostring(value))
    end
    __SC__save("Master", config)
end

function __SC__updateMaster()
    _SC.master = __SC__load("Master")
    _SC.masterY, _SC.masterYp = 1, 0
    _SC.masterY = (_SC.master.useTS and 1 or 0)
    for i = 1, _SC.masterIndex - 1 do
        _SC.masterY = _SC.masterY + _SC.master["I"..i]
        _SC.masterYp = _SC.masterYp + _SC.master["PS"..i]
    end
    local size, sizep = (_SC.master.useTS and 2 or 1), 0
    for i = 1, _SC.master.iCount do
        size = size + _SC.master["I"..i]
        sizep = sizep + _SC.master["PS"..i]
    end
    _SC.draw.heigth = size * _SC.draw.cellSize
    _SC.pDraw.heigth = sizep * _SC.pDraw.cellSize
    _SC.draw.x = _SC.master.x
    _SC.draw.y = _SC.master.y
    _SC.pDraw.x = _SC.master.px
    _SC.pDraw.y = _SC.master.py
    _SC._Idraw.x = _SC.draw.x + _SC.draw.width + _SC.draw.border * 2
end

function __SC__init_draw()
    if _SC.initDraw then
        WINDOW_H = GetScreenY()
        WINDOW_W = GetScreenX()

        _SC.draw = {
            x = WINDOW_W and math.floor(WINDOW_W / 50) or 20,
            y = WINDOW_H and math.floor(WINDOW_H / 4) or 190,
            y1 = 0,
            heigth = 0,
            --fontSize = WINDOW_H and math.round(WINDOW_H / 54) or 14,
            fontSize = WINDOW_H and math.round(WINDOW_H / 72) or 10,
            width = WINDOW_W and math.round(WINDOW_W / 4.8) or 213,
            border = 2,
            background = 1413167931,
            textColor = 4290427578,
            trueColor = 1422721024,
            falseColor = 1409321728,
            move = false
        }

        _SC.pDraw = {
            x = WINDOW_W and math.floor(WINDOW_W * 0.66) or 675,
            y = WINDOW_H and math.floor(WINDOW_H * 0.8) or 608,
            y1 = 0,
            heigth = 0,
            fontSize = WINDOW_H and math.round(WINDOW_H / 72) or 10,
            width = WINDOW_W and math.round(WINDOW_W / 6.4) or 160,
            border = 1,
            background = 1413167931,
            textColor = 4290427578,
            trueColor = 1422721024,
            falseColor = 1409321728,
            move = false
        }

        local menuConfig = __SC__load("Menu")
        for var, value in pairs(menuConfig) do
            vars = {var:match((var:gsub("[^%.]*%.", "([^.]*).")))}
            if #vars == 1 then
                _SC[vars[1]] = value
            elseif #vars == 2 then
                _SC[vars[1]][vars[2]] = value
            end
        end
        _SC.color = {lgrey = 1413167931, grey = 4290427578, red = 1422721024, green = 1409321728, ivory = 4294967280}
        _SC.draw.cellSize, _SC.draw.midSize, _SC.draw.row4, _SC.draw.row3, _SC.draw.row2, _SC.draw.row1 = _SC.draw.fontSize + _SC.draw.border, _SC.draw.fontSize / 2, _SC.draw.width * 0.9, _SC.draw.width * 0.8, _SC.draw.width * 0.7, _SC.draw.width * 0.6
        _SC.pDraw.cellSize, _SC.pDraw.midSize, _SC.pDraw.row = _SC.pDraw.fontSize + _SC.pDraw.border, _SC.pDraw.fontSize / 2, _SC.pDraw.width * 0.7
        _SC._Idraw = {x = _SC.draw.x + _SC.draw.width + _SC.draw.border * 2 ,y = _SC.draw.y, heigth = 0}
        if WINDOW_H < 500 or WINDOW_W < 500 then return true end
        _SC.initDraw = nil
    end
    return _SC.initDraw
end

function __SC__init(name)
    if name == nil then
        return (_SC.init or __SC__init_draw())
    end
    if _SC.init then
        _SC.init = nil
        __SC__init_draw()
        --local gameStart = GetStart()
        _SC.master = __SC__load("Master")

            for i = 1, _SC.master.iCount do
                if _SC.master["name"..i] == name then _SC.masterIndex = i end
            end
            if _SC.masterIndex == nil then
                _SC.masterIndex = _SC.master.iCount + 1
                _SC.master["name".._SC.masterIndex] = name
                _SC.master.iCount = _SC.masterIndex
                __SC__saveMaster()
            end

    end
    __SC__updateMaster()
end

function __SC__txtKey(key)
    return (key > 32 and key < 96 and " "..string.char(key).." " or "("..tostring(key)..")")
end

function SC__OnDraw()
    if __SC__init() then return end
    if KeyDown(_SC.menuKey) or _SC._changeKey then
        if _SC.draw.move then
            local cursor = {x=GetCursorX(), y=GetCursorY()}
            _SC.draw.x = cursor.x - _SC.draw.offset.x
            _SC.draw.y = cursor.y - _SC.draw.offset.y
            _SC._Idraw.x = _SC.draw.x + _SC.draw.width + _SC.draw.border * 2
        elseif _SC.pDraw.move then
            local cursor = {x = GetCursorX(), y = GetCursorY()}
            _SC.pDraw.x = cursor.x - _SC.pDraw.offset.x
            _SC.pDraw.y = cursor.y - _SC.pDraw.offset.y
        end
        if _SC.masterIndex == 1 then
            DrawBox(_SC.draw.x, _SC.draw.y, _SC.draw.width + _SC.draw.border * 2, _SC.draw.heigth, 1414812756)
            _SC.draw.y1 = _SC.draw.y
            local menuText = _SC._changeKey and not _SC._changeKeyVar and "press key for Menu" or "Menu"
            DrawText(menuText, _SC.draw.x, _SC.draw.y1, _SC.color.ivory) -- ivory
            DrawText(__SC__txtKey(_SC.menuKey), _SC.draw.x + _SC.draw.width * 0.9, _SC.draw.y1, _SC.color.grey)
        end
        _SC.draw.y1 = _SC.draw.y + _SC.draw.cellSize
        if _SC.useTS then
            __SC__DrawInstance("Target Selector", (_SC.menuIndex == 0))
            if _SC.menuIndex == 0 then
                DrawLine(_SC._Idraw.x + _SC.draw.width / 2, _SC.draw.y, _SC._Idraw.x + _SC.draw.width / 2, _SC.draw.y + _SC._Idraw.heigth, _SC.draw.width + _SC.draw.border * 2, 1414812756) -- grey
                DrawText("Target Selector", _SC.draw.fontSize, _SC._Idraw.x, _SC.draw.y, _SC.color.ivory)
                _SC._Idraw.y = TS__DrawMenu(_SC._Idraw.x, _SC.draw.y + _SC.draw.cellSize)
                _SC._Idraw.heigth = _SC._Idraw.y - _SC.draw.y
            end
        end
        _SC.draw.y1 = _SC.draw.y + _SC.draw.cellSize + (_SC.draw.cellSize * _SC.masterY)
        for index,instance in ipairs(_SC.instances) do
            __SC__DrawInstance(instance.header, (_SC.menuIndex == index))
            if _SC.menuIndex == index then instance:OnDraw() end
        end
    end
    local y1 = _SC.pDraw.y + (_SC.pDraw.cellSize * _SC.masterYp)
    for index,instance in ipairs(_SC.instances) do
        if #instance._permaShow > 0 then
            for i,varIndex in ipairs(instance._permaShow) do
                local pVar = instance._param[varIndex].var
                DrawBox(_SC.pDraw.x - _SC.pDraw.border, y1, _SC.pDraw.row, _SC.pDraw.cellSize, _SC.color.lgrey)
                DrawText(instance._param[varIndex].text, _SC.pDraw.x, y1, _SC.color.grey)
                if instance._param[varIndex].pType == SCRIPT_PARAM_SLICE then

                elseif instance._param[varIndex].pType == SCRIPT_PARAM_INFO then
                    DrawBox(_SC.pDraw.x + _SC.pDraw.row, y1, _SC.pDraw.width + _SC.pDraw.border, _SC.pDraw.cellSize, _SC.color.lgrey)
                    DrawText("      "..tostring(instance[pVar]), _SC.pDraw.x + _SC.pDraw.row + _SC.pDraw.border, y1, _SC.color.grey)

                elseif instance._param[varIndex].pType == SCRIPT_PARAM_NUMERICUPDOWN then
                    DrawBox(_SC.pDraw.x + _SC.pDraw.row, y1, (_SC.pDraw.width - _SC.pDraw.row) + _SC.pDraw.border, _SC.pDraw.cellSize, _SC.color.lgrey)
                    DrawText("      "..tostring(instance[pVar]), _SC.pDraw.x + _SC.pDraw.row + _SC.pDraw.border, y1, _SC.color.grey)

                elseif instance._param[varIndex].pType == SCRIPT_PARAM_DOMAINUPDOWN then
                    DrawBox(_SC.pDraw.x + _SC.pDraw.row, y1, (_SC.pDraw.width - _SC.pDraw.row) + _SC.pDraw.border, _SC.pDraw.cellSize, _SC.color.lgrey)
                    DrawText("      "..tostring(instance._param[varIndex].vls[instance[pVar]]), _SC.pDraw.x + _SC.pDraw.row + _SC.pDraw.border, y1, _SC.color.grey)

                else
                    DrawBox(_SC.pDraw.x + _SC.pDraw.row, y1, (_SC.pDraw.width - _SC.pDraw.row) + _SC.pDraw.border, _SC.pDraw.cellSize, (instance[pVar] and _SC.color.green or _SC.color.lgrey))
                    DrawText((instance[pVar] and "      ON" or "      OFF"), _SC.pDraw.x + _SC.pDraw.row + _SC.pDraw.border, y1, _SC.color.grey)

                end
                y1 = y1 + _SC.pDraw.cellSize
            end
        end
    end
end

function __SC__DrawInstance(header, selected)
    DrawBox(_SC.draw.x, _SC.draw.y1, _SC.draw.width + _SC.draw.border * 2,_SC.draw.cellSize , (selected and _SC.color.red or _SC.color.lgrey))
    DrawText(header, _SC.draw.x, _SC.draw.y1, (selected and _SC.color.ivory or _SC.color.grey))
    _SC.draw.y1 = _SC.draw.y1 + _SC.draw.cellSize
end

function SC__OnWndMsg(msg,key)
    if __SC__init() then return end

    local msg, key = msg, key
    if key == _SC.menuKey and _SC.lastKeyState ~= msg then
        _SC.lastKeyState = msg
        __SC__updateMaster()
    end
    if _SC._changeKey then
        if msg == KEY_DOWN then
            if _SC._changeKeyMenu then return end
            _SC._changeKey = false
            if _SC._changeKeyVar == nil then
                _SC.menuKey = key
                if _SC.masterIndex == 1 then __SC__saveMenu() end
            else
                _SC.instances[_SC.menuIndex]._param[_SC._changeKeyVar].key = key
                _SC.instances[_SC.menuIndex]:save()
            end
            return
        else
            if _SC._changeKeyMenu and key == _SC.menuKey then _SC._changeKeyMenu = false end
        end
    end
    if msg == WM_LBUTTONDOWN then
        if CursorIsUnder(_SC.draw.x, _SC.draw.y, _SC.draw.width, _SC.draw.heigth) then
            _SC.menuIndex = -1
            if CursorIsUnder(_SC.draw.x + _SC.draw.width - _SC.draw.fontSize * 1.5, _SC.draw.y, _SC.draw.fontSize, _SC.draw.cellSize) then
                _SC._changeKey, _SC._changeKeyVar, _SC._changeKeyMenu = true, nil, true
                return
            elseif CursorIsUnder(_SC.draw.x, _SC.draw.y, _SC.draw.width, _SC.draw.cellSize) then
                _SC.draw.offset = Vector(GetCursorX(), GetCursorY()) - _SC.draw
                _SC.draw.move = true
                return
            else
                if _SC.useTS and CursorIsUnder(_SC.draw.x, _SC.draw.y + _SC.draw.cellSize, _SC.draw.width, _SC.draw.cellSize) then _SC.menuIndex = 0 end
                local y1 = _SC.draw.y + _SC.draw.cellSize + (_SC.draw.cellSize * _SC.masterY)
                for index,instance in ipairs(_SC.instances) do
                    if CursorIsUnder(_SC.draw.x, y1, _SC.draw.width, _SC.draw.cellSize) then _SC.menuIndex = index end
                    y1 = y1 + _SC.draw.cellSize
                end
            end
        elseif CursorIsUnder(_SC.pDraw.x, _SC.pDraw.y, _SC.pDraw.width, _SC.pDraw.heigth) then
            _SC.instances[1]:OnPWndMsg()
            _SC.pDraw.offset = Vector(GetCursorX(), GetCursorY()) - _SC.pDraw
            _SC.pDraw.move = true
        elseif _SC.menuIndex == 0 then
            TS_ClickMenu(_SC._Idraw.x, _SC.draw.y + _SC.draw.cellSize)
        elseif _SC.menuIndex > 0 and CursorIsUnder(_SC._Idraw.x, _SC.draw.y, _SC.draw.width, _SC._Idraw.heigth) then
            _SC.instances[_SC.menuIndex]:OnWndMsg()
        end
    elseif msg == WM_LBUTTONUP then
        if _SC.draw.move or _SC.pDraw.move then
            _SC.draw.move = false
            _SC.pDraw.move = false
            if _SC.masterIndex == 1 then __SC__saveMenu() end
            return
        elseif _SC._slice then
            _SC._slice = false
            _SC.instances[_SC.menuIndex]:save()
            return
        end
    else
        for index,instance in ipairs(_SC.instances) do
            for i,param in ipairs(instance._param) do
                if param.pType == SCRIPT_PARAM_ONKEYTOGGLE and key == param.key and msg == KEY_DOWN then
                    instance[param.var] = not instance[param.var]
                elseif param.pType == SCRIPT_PARAM_ONKEYDOWN and key == param.key then
                    instance[param.var] = (msg == KEY_DOWN)
                elseif param.pType == SCRIPT_PARAM_NUMERICUPDOWN then
                    if param.key ~= nil and key == param.key and msg == KEY_DOWN then
                        local newNum = instance[param.var] + param.stp
                        if newNum < param.min then newNum = param.max
                        elseif newNum > param.max then newNum = param.min end
                        instance[param.var] = newNum
                        instance:save()
                    end
                elseif param.pType == SCRIPT_PARAM_DOMAINUPDOWN then
                    if param.key ~= nil and key == param.key and msg == KEY_DOWN then
                        local newNum = instance[param.var] + 1
                        if newNum > table.getn(param.vls) then newNum = 1
                        elseif newNum < 1 then newNum = table.getn(param.vls) end
                        instance[param.var] = newNum
                        instance:save()
                    end
                end
            end
        end
    end
end

function scriptConfig:__init(header, name)
    assert((type(header) == "string") and (type(name) == "string"), "scriptConfig: expected <string>, <string>)")
    __SC__init(name)
    self.header = header
    self.name = name
    self._tsInstances = {}
    self._param = {}
    self._permaShow = {}
    table.insert(_SC.instances, self)
end

function GetVarArg(...)
    if arg==nil then
        local n = select('#', ...)
        local t = {}
        local v
        for i=1,n do
            v = select(i, ...)
            --print('\nv = '..tostring(v))
            table.insert(t,v)
        end
        return t
    else
        return arg
    end
end

function scriptConfig:addParam(pVar, pText, pType, defaultValue, defaultKey, ...)
    assert(type(pVar) == "string" and type(pText) == "string" and type(pType) == "number", "addParam: wrong argument types (<string>, <string>, <pType> expected)")
    assert(string.find(pVar,"[^%a%d]") == nil, "addParam: pVar should contain only char and number")
    assert(self[pVar] == nil, "addParam: pVar should be unique, already existing "..pVar)
    local newParam = {var = pVar, text = pText, pType = pType, key = defaultKey}
    local arg = GetVarArg(...)
    if pType == SCRIPT_PARAM_ONOFF or pType == SCRIPT_PARAM_ONKEYDOWN or pType == SCRIPT_PARAM_ONKEYTOGGLE then
        assert(type(defaultValue) == "boolean", "addParam: wrong argument types (pVar, pText, pType, defaultValue, defaultKey, enabled) expected.")
    elseif pType == SCRIPT_PARAM_SLICE then
        assert(type(defaultValue) == "number" and type(arg[1]) == "number" and type(arg[2]) == "number" and (type(arg[3]) == "number" or arg[3] == nil), "addParam: wrong argument types (pVar, pText, pType, defaultValue, valMin, valMax, [decimal]) expected")
        newParam.min = arg[1]
        newParam.max = arg[2]
        newParam.idc = arg[3] or 0
        newParam.cursor = 0
    elseif pType == SCRIPT_PARAM_INFO then
        assert(type(arg[1]) == "boolean" or arg[1] == nil, "addParam: wrong argument types (pVar, pText, pType, defaultValue, defaultKey, save) expected.")
        newParam.rec = arg[1] or false
    elseif pType == SCRIPT_PARAM_NUMERICUPDOWN then
        assert(type(defaultValue) == "number" and type(arg[1]) == "number" and type(arg[2]) == "number" and type(arg[3]) == "number", "addParam: wrong argument types (pVar, pText, pType, defaultValue, defaultKey, min, max, step) expected.")
        newParam.min = arg[1]
        newParam.max = arg[2]
        newParam.stp = arg[3]
    elseif pType == SCRIPT_PARAM_DOMAINUPDOWN then
        assert(type(defaultValue) == "number" and type(arg[1]) == "table", "addParam: wrong argument types (pVar, pText, pType, defaultValue, defaultKey, valuesTable) expected.")
        newParam.vls = arg[1]
    end

    self[pVar] = defaultValue
    table.insert(self._param, newParam)
    self:load()
    __SC__saveMaster()
end

function scriptConfig:addTS(tsInstance)
    assert(type(tsInstance.mode) == "number", "addTS: expected TargetSelector)")
    _SC.useTS = true
    table.insert(self._tsInstances, tsInstance)
    self:load()
    __SC__saveMaster()
end

function scriptConfig:permaShow(pVar)
    assert(type(pVar) == "string" and self[pVar] ~= nil, "permaShow: existing pVar expected)")
    for index,param in ipairs(self._param) do
        if param.var == pVar then
            table.insert(self._permaShow, index)
        end
    end
    __SC__saveMaster()
end

function scriptConfig:_txtKey(key)
    return (key > 32 and key < 96 and " "..string.char(key).." " or "("..tostring(key)..")")
end

function scriptConfig:OnDraw()
    if _SC._slice then
        local cursorX = math.min(math.max(0, GetCursorPos().x - _SC._Idraw.x - _SC.draw.row3), _SC.draw.width - _SC.draw.row3)
        self[self._param[_SC._slice].var] = math.round(cursorX / (_SC.draw.width - _SC.draw.row3) * (self._param[_SC._slice].max - self._param[_SC._slice].min),self._param[_SC._slice].idc)
    end
    _SC._Idraw.y = _SC.draw.y
    DrawBox(_SC._Idraw.x, _SC._Idraw.y, _SC.draw.width + _SC.draw.border * 2,_SC._Idraw.heigth, 1414812756) -- grey
    local menuText = _SC._changeKey and _SC._changeKeyVar and "press key for ".._SC.instances[_SC.menuIndex]._param[_SC._changeKeyVar].var or self.header
    DrawText(menuText, _SC._Idraw.x, _SC._Idraw.y, 4294967280) -- ivory
    _SC._Idraw.y = _SC._Idraw.y + _SC.draw.cellSize
    if # self._tsInstances > 0 then
        --_SC._Idraw.y = TS__DrawMenu(_SC._Idraw.x, _SC._Idraw.y)
        for i,tsInstance in ipairs(self._tsInstances) do
            _SC._Idraw.y = tsInstance:DrawMenu(_SC._Idraw.x, _SC._Idraw.y)
        end
    end
    for index,param in ipairs(self._param) do
        self:_DrawParam(index)
    end
    _SC._Idraw.heigth = _SC._Idraw.y - _SC.draw.y
end

function scriptConfig:_DrawParam(varIndex)
    local pVar = self._param[varIndex].var
    DrawBox(_SC._Idraw.x - _SC.draw.border, _SC._Idraw.y + _SC.draw.midSize, _SC.draw.cellSize, _SC.draw.midSize, _SC.color.lgrey)
    DrawText(self._param[varIndex].text, _SC._Idraw.x, _SC._Idraw.y, _SC.color.grey)

    if self._param[varIndex].pType == SCRIPT_PARAM_SLICE then

        DrawText(tostring(self[pVar]), _SC._Idraw.x + _SC.draw.row2, _SC._Idraw.y, _SC.color.grey)
        DrawLine(_SC._Idraw.x + _SC.draw.row3, _SC._Idraw.y + _SC.draw.midSize, _SC._Idraw.x + _SC.draw.width + _SC.draw.border, _SC._Idraw.y + _SC.draw.midSize, _SC.draw.cellSize, _SC.color.lgrey, 1)
        -- cursor
        self._param[varIndex].cursor =  self[pVar] / (self._param[varIndex].max - self._param[varIndex].min) * (_SC.draw.width - _SC.draw.row3)
        DrawLine(_SC._Idraw.x + _SC.draw.row3 + self._param[varIndex].cursor - _SC.draw.border, _SC._Idraw.y + _SC.draw.midSize, _SC._Idraw.x + _SC.draw.row3 + self._param[varIndex].cursor + _SC.draw.border, _SC._Idraw.y + _SC.draw.midSize, _SC.draw.cellSize, 4292598640, 1)

    elseif self._param[varIndex].pType == SCRIPT_PARAM_INFO then
        DrawText("      "..tostring(self[pVar]), _SC.draw.fontSize, _SC._Idraw.x + _SC.draw.row3 + _SC.draw.border, _SC._Idraw.y, _SC.color.grey)

    elseif self._param[varIndex].pType == SCRIPT_PARAM_NUMERICUPDOWN then
        if self._param[varIndex].key ~= nil then DrawText(self:_txtKey(self._param[varIndex].key), _SC._Idraw.x + _SC.draw.row2, _SC._Idraw.y, _SC.color.grey) end
        DrawBox(_SC._Idraw.x + _SC.draw.row3, _SC._Idraw.y, (_SC._Idraw.x + _SC.draw.width + _SC.draw.border)-(_SC._Idraw.x + _SC.draw.row3),_SC.draw.cellSize, _SC.color.lgrey)
        DrawText("        "..tostring(self[pVar]), _SC._Idraw.x + _SC.draw.row3 + _SC.draw.border, _SC._Idraw.y, _SC.color.grey)

    elseif self._param[varIndex].pType == SCRIPT_PARAM_DOMAINUPDOWN then
        if self._param[varIndex].key ~= nil then DrawText(self:_txtKey(self._param[varIndex].key), _SC._Idraw.x + _SC.draw.row2, _SC._Idraw.y, _SC.color.grey) end
        DrawBox(_SC._Idraw.x + _SC.draw.row3, _SC._Idraw.y, (_SC._Idraw.x + _SC.draw.width + _SC.draw.border)-(_SC._Idraw.x + _SC.draw.row3),_SC.draw.cellSize, _SC.color.lgrey)
        DrawText("        "..tostring(self._param[varIndex].vls[self[pVar]]), _SC._Idraw.x + _SC.draw.row3 + _SC.draw.border, _SC._Idraw.y, _SC.color.grey)

    else
        if (self._param[varIndex].pType == SCRIPT_PARAM_ONKEYDOWN or self._param[varIndex].pType == SCRIPT_PARAM_ONKEYTOGGLE) then
            DrawText(self:_txtKey(self._param[varIndex].key), _SC._Idraw.x + _SC.draw.row2, _SC._Idraw.y, _SC.color.grey)
        end
        DrawBox(_SC._Idraw.x + _SC.draw.row3, _SC._Idraw.y, (_SC._Idraw.x + _SC.draw.width + _SC.draw.border)-(_SC._Idraw.x + _SC.draw.row3),_SC.draw.cellSize, (self[pVar] and _SC.color.green or _SC.color.lgrey))
        DrawText((self[pVar] and "        ON" or "        OFF"), _SC._Idraw.x + _SC.draw.row3 + _SC.draw.border, _SC._Idraw.y, _SC.color.grey)
    end
    _SC._Idraw.y = _SC._Idraw.y + _SC.draw.cellSize
end

function scriptConfig:load()
    local config = __SC__load(self.name)
    for v, value in pairs(config) do
        local var = v:match"([^.]*).(.*)"
        local val = value
        if self[var] ~= nil then
            local vals = split(val, ";")
            self[var] = (string.match(vals[1], "%d*%.?%d*") and tonumber(string.match(vals[1], "%d*%.?%d*")) or (string.match(val, "%a+") == "true" and true or false))
            for i=2, #vals do
                local temp = split(vals[i], "=")
                for _, params in pairs(self._param) do
                    if params.var == var then
                        if params[temp[1]] then params[temp[1]] = tonumber(temp[2]) end
                    end
                end
            end
        end
    end
end

function split (s, delim)
    local start = 1
    local t = {}
    while true do
        local pos = string.find (s, delim, start, true)
        if not pos then
            break
        end
        table.insert (t, string.sub (s, start, pos - 1))
        start = pos + string.len (delim)
    end
    table.insert (t, string.sub (s, start))
    return t
end

function scriptConfig:save()
    local content = {}
    for var,param in pairs(self._param) do
        if param.pType == SCRIPT_PARAM_ONOFF or param.pType == SCRIPT_PARAM_ONKEYDOWN or param.pType == SCRIPT_PARAM_ONKEYTOGGLE then
            table.insert(content, param.var.."="..tostring(self[param.var])..";key="..tostring(param.key)..";")

        elseif param.pType == SCRIPT_PARAM_NUMERICUPDOWN then
            table.insert(content, param.var.."="..tostring(self[param.var])..";key="..tostring(param.key)..";")

        elseif param.pType == SCRIPT_PARAM_DOMAINUPDOWN then
            local domainStr = ""
            table.insert(content, param.var.."="..tostring(self[param.var])..";key="..tostring(param.key)..";")
        elseif param.pType == SCRIPT_PARAM_HIDDEN or (param.pType == SCRIPT_PARAM_INFO and param.rec == true) then
            table.insert(content, param.var.."="..tostring(self[param.var])..";key="..tostring(param.key)..";")
        end
    end
    for i,ts in pairs(self._tsInstances) do
        table.insert (content, "_tsInstances."..i..".mode="..tostring(ts.mode))
    end
    -- for i,pShow in pairs(self._permaShow) do
        -- table.insert (content, "_permaShow."..i.."="..tostring(pShow))
    -- end
    __SC__save(self.name, content)
end

function scriptConfig:OnPWndMsg()
   for i,param in ipairs(self._param) do
      if CursorIsUnder(_SC.pDraw.x, _SC.pDraw.y + (i-1)*_SC.pDraw.cellSize, _SC.pDraw.width, _SC.pDraw.fontSize) then
         self[param.var] = not self[param.var]
         self:save()
         return
      end
   end
end
function scriptConfig:OnWndMsg()
    local y1 = _SC.draw.y + _SC.draw.cellSize
    if # self._tsInstances > 0 then
        for i,tsInstance in ipairs(self._tsInstances) do
            y1 = tsInstance:ClickMenu(_SC._Idraw.x, y1)
        end
    end
    for i,param in ipairs(self._param) do
        if param.pType == SCRIPT_PARAM_ONKEYDOWN or param.pType == SCRIPT_PARAM_ONKEYTOGGLE then
            if CursorIsUnder(_SC._Idraw.x + _SC.draw.row2, y1, _SC.draw.fontSize, _SC.draw.fontSize) then
                _SC._changeKey, _SC._changeKeyVar, _SC._changeKeyMenu = true, i, true
                return
            end
        end
        if param.pType == SCRIPT_PARAM_ONOFF or param.pType == SCRIPT_PARAM_ONKEYTOGGLE then
            if CursorIsUnder(_SC._Idraw.x + _SC.draw.row3, y1, _SC.draw.width - _SC.draw.row3, _SC.draw.fontSize) then
                self[param.var] = not self[param.var]
                self:save()
                return
            end
        end
        if param.pType == SCRIPT_PARAM_SLICE then
            if CursorIsUnder(_SC._Idraw.x + _SC.draw.row3 + param.cursor - _SC.draw.border, y1, _SC.draw.border * 2, _SC.draw.fontSize) then
                _SC._slice = i
                return
            end
        end
        if param.pType == SCRIPT_PARAM_NUMERICUPDOWN then
            if CursorIsUnder(_SC._Idraw.x + _SC.draw.row2, y1, _SC.draw.fontSize, _SC.draw.fontSize) then
                if param.key ~= nil then
                    _SC._changeKey, _SC._changeKeyVar, _SC._changeKeyMenu = true, i, true
                    return
                end
            end
            if CursorIsUnder(_SC._Idraw.x + _SC.draw.row3, y1, _SC.draw.width - _SC.draw.row3, _SC.draw.fontSize) then
                local newNum = self[param.var] + param.stp
                if newNum < param.min then newNum = param.max
                elseif newNum > param.max then newNum = param.min end
                self[param.var] = newNum
                self:save()
            end
        end
        if param.pType == SCRIPT_PARAM_DOMAINUPDOWN then
            if CursorIsUnder(_SC._Idraw.x + _SC.draw.row2, y1, _SC.draw.fontSize, _SC.draw.fontSize) then
                if param.key ~= nil then
                    _SC._changeKey, _SC._changeKeyVar, _SC._changeKeyMenu = true, i, true
                    return
                end
            end
            if CursorIsUnder(_SC._Idraw.x + _SC.draw.row3, y1, _SC.draw.width - _SC.draw.row3, _SC.draw.fontSize) then
                local newNum = self[param.var] + 1
                if newNum > table.getn(param.vls) then newNum = 1
                elseif newNum < 1 then newNum = table.getn(param.vls) end
                self[param.var] = newNum
                self:save()
            end
        end
        y1 = y1 + _SC.draw.cellSize
    end
end

function math.round(num, idp)
    assert(type(num) == "number", "math.round: wrong argument types (<number> expected for num)")
    assert(type(idp) == "number" or idp == nil, "math.round: wrong argument types (<integer> expected for idp)")
    local mult = math.floor(10^(idp or 0))
    local value = (num >= 0 and math.floor(num * mult + 0.5) / mult or math.ceil(num * mult - 0.5) / mult)
    return tonumber(string.format("%." .. (idp or 0) .. "f", value))
end

function CursorIsUnder(x, y, sizeX, sizeY)
    assert(type(x) == "number" and type(y) == "number" and type(sizeX) == "number", "CursorIsUnder: wrong argument types (at least 3 <number> expected)")
    local posX, posY = GetCursorX(), GetCursorY()
    if sizeY == nil then sizeY = sizeX end
    if sizeX < 0 then
        x = x + sizeX
        sizeX = - sizeX
    end
    if sizeY < 0 then
        y = y + sizeY
        sizeY = - sizeY
    end
    return (posX >= x and posX <= x + sizeX and posY >= y and posY <= y + sizeY)
end

--################## END SCRIPT CONFIG CLASS ##################--

--################## START CIRCLE CLASS ##################--

Circle = class()
function Circle:__init(center, radius)
    assert((VectorType(center) or center == nil) and (type(radius) == "number" or radius == nil), "Circle: wrong argument types (expected <Vector> or nil, <number> or nil)")
    self.center = Vector(center) or Vector()
    self.radius = radius or 0
end

function Circle:Contains(v)
    assert(VectorType(v), "Contains: wrong argument types (expected <Vector>)")
    return math.close(self.center:dist(v), self.radius)
end

function Circle:__tostring()
    return "{center: " .. tostring(self.center) .. ", radius: " .. tostring(self.radius) .. "}"
end

--################## END CIRCLE CLASS ##################--

--################## START MEC CLASS ##################--

MEC = class()

function MEC:__init(points)
    self.circle = Circle()
    self.points = {}
    if points then
        self:SetPoints(points)
    end
end

function MEC:SetPoints(points)
    -- Set the points
    self.points = {}
    for i, p in ipairs(points) do
        table.insert(self.points, Vector(p))
    end
end

function MEC:HalfHull(left, right, pointTable, factor)
    -- Computes the half hull of a set of points
    local input = pointTable
    table.insert(input, right)
    local half = {}
    table.insert(half, left)
    for i, p in ipairs(input) do
        table.insert(half, p)
        while #half >= 3 do
            local dir = factor * VectorDirection(half[(#half + 1) - 3], half[(#half + 1) - 1], half[(#half + 1) - 2])
            if dir <= 0 then
                table.remove(half, #half - 1)
            else
                break
            end
        end
    end
    return half
end

function MEC:ConvexHull()
    -- Computes the set of points that represent the convex hull of the set of points
    local left, right = self.points[1], self.points[#self.points]
    local upper, lower, ret = {}, {}, {}
    -- Partition remaining points into upper and lower buckets.
    for i = 2, #self.points - 1 do
        if VectorType(self.points[i]) == false then PrintChat("self.points[i]") end
        table.insert((VectorDirection(left, right, self.points[i]) < 0 and upper or lower), self.points[i])
    end
    local upperHull = self:HalfHull(left, right, upper, -1)
    local lowerHull = self:HalfHull(left, right, lower, 1)
    local unique = {}
    for i, p in ipairs(upperHull) do
        unique["x" .. p.x .. "z" .. p.z] = p
    end
    for i, p in ipairs(lowerHull) do
        unique["x" .. p.x .. "z" .. p.z] = p
    end
    for i, p in pairs(unique) do
        table.insert(ret, p)
    end
    return ret
end

function MEC:Compute()
    -- Compute the MEC.
    -- Make sure there are some points.
    if #self.points == 0 then return nil end
    -- Handle degenerate cases first
    if #self.points == 1 then
        self.circle.center = self.points[1]
        self.circle.radius = 0
        self.circle.radiusPoint = self.points[1]
    elseif #self.points == 2 then
        local a = self.points
        self.circle.center = a[1]:center(a[2])
        self.circle.radius = a[1]:dist(self.circle.center)
        self.circle.radiusPoint = a[1]
    else
        local a = self:ConvexHull()
        local point_a = a[1]
        local point_b = nil
        local point_c = a[2]
        if not point_c then
            self.circle.center = point_a
            self.circle.radius = 0
            self.circle.radiusPoint = point_a
            return self.circle
        end
        -- Loop until we get appropriate values for point_a and point_c
        while true do
            point_b = nil
            local best_theta = 180.0
            -- Search for the point "b" which subtends the smallest angle a-b-c.
            for i, point in ipairs(self.points) do
                if (not point == point_a) and (not point == point_c) then
                    local theta_abc = point:angleBetween(point_a, point_c)
                    if theta_abc < best_theta then
                        point_b = point
                        best_theta = theta_abc
                    end
                end
            end
            -- If the angle is obtuse, then line a-c is the diameter of the circle,
            -- so we can return.
            if best_theta >= 90.0 or (not point_b) then
                self.circle.center = point_a:center(point_c)
                self.circle.radius = point_a:dist(self.circle.center)
                self.circle.radiusPoint = point_a
                return self.circle
            end
            local ang_bca = point_c:angleBetween(point_b, point_a)
            local ang_cab = point_a:angleBetween(point_c, point_b)
            if ang_bca > 90.0 then
                point_c = point_b
            elseif ang_cab <= 90.0 then
                break
            else
                point_a = point_b
            end
        end
        local ch1 = (point_b - point_a) * 0.5
        local ch2 = (point_c - point_a) * 0.5
        local n1 = ch1:perpendicular2()
        local n2 = ch2:perpendicular2()
        ch1 = point_a + ch1
        ch2 = point_a + ch2
        self.circle.center = VectorIntersection(ch1, n1, ch2, n2)
        self.circle.radius = self.circle.center:dist(point_a)
        self.circle.radiusPoint = point_a
    end
    return self.circle
end

function GetMEC(radius, range, target)
    assert(type(radius) == "number" and type(range) == "number" and (target == nil or target.team ~= nil), "GetMEC: wrong argument types (expected <number>, <number>, <object> or nil)")
    local points = {}
    for i = 1, objManager:GetMaxHeroes() do
        local object = objManager:GetHero(i)
        if (target == nil and ValidTarget(object, (range + radius))) or (target and ValidTarget(object, (range + radius), (target.team ~= myHero.team)) and (ValidTargetNear(object, radius * 2, target) or object.networkID == target.networkID)) then
            table.insert(points, Vector(object))
        end
    end
    return _CalcSpellPosForGroup(radius, range, points)
end

function _CalcSpellPosForGroup(radius, range, points)
    if #points == 0 then
        return nil
    elseif #points == 1 then
        local cir = Circle(Vector(points[1]))
        tmp = {x = cir.center.x, y = cir.center.y, z = cir.center.z}
        return tmp
    end
    local mec = MEC()
    local combos = {}
    for j = #points, 2, -1 do
        local spellPos = nil
        combos[j] = {}
        _CalcCombos(j, points, combos[j])
        for i, v in ipairs(combos[j]) do
            mec:SetPoints(v)
            local c = mec:Compute()
            if c ~= nil and c.radius <= radius and c.center:dist(myHero) <= range and (spellPos == nil or c.radius < spellPos.radius) then
                spellPos = Circle(c.center, c.radius)
            end
        end
        if spellPos ~= nil then
            local ret = {x = spellPos.center.x, y = spellPos.center.y, z = spellPos.center.z}
            return ret
        end
    end
end

function _CalcCombos(comboSize, targetsTable, comboTableToFill, comboString, index_number)
    local comboString = comboString or ""
    local index_number = index_number or 1
    if string.len(comboString) == comboSize then
        local b = {}
        for i = 1, string.len(comboString), 1 do
            local ai = tonumber(string.sub(comboString, i, i))
            table.insert(b, targetsTable[ai])
        end
        return table.insert(comboTableToFill, b)
    end
    for i = index_number, #targetsTable, 1 do
        _CalcCombos(comboSize, targetsTable, comboTableToFill, comboString .. i, i + 1)
    end
end

--################## END MEC CLASS ##################--

--################## START MINION MANAGER CLASS ##################--
local allyMinions = {}
local enemyMinions = {}
MINION_SORT_HEALTH_ASC = function(a, b)  if a.health~=nil and b.health~=nil then return a.health < b.health else return false end end
MINION_SORT_HEALTH_DEC = function(a, b) return a.health > b.health end
MINION_SORT_MAXHEALTH_ASC = function(a, b) return a.maxHealth < b.maxHealth end
MINION_SORT_MAXHEALTH_DEC = function(a, b) return a.maxHealth > b.maxHealth end
MINION_SORT_AD_ASC = function(a, b) return a.ad < b.ad end
MINION_SORT_AD_DEC = function(a, b) return a.ad > b.ad end
local _minionManager = {ally = "##", enemy = "##"}

if myHero ~= nil then
    _minionManager.ally = (myHero.team == TEAM_BLUE and "Blue" or "Red")
    _minionManager.enemy = (myHero.team == TEAM_BLUE and "Red" or "Blue")
end

function minionManager__OnCreateObj(object)
    if object ~= nil then
    local name = object.name
        if name:sub(1, #_minionManager.ally) == _minionManager.ally then
            table.insert(allyMinions, object)
        elseif name:sub(1, #_minionManager.enemy) == _minionManager.enemy then
            table.insert(enemyMinions, object)
        end
    end
end

for i = 1, objManager:GetMaxObjects() do
    minionManager__OnCreateObj(objManager:GetObject(i))
end

function minionManager__OnTick()
    for i,object in pairs(allyMinions) do
        if object == nil or object.dead == 1 then table.remove(allyMinions, i) end
    end
    for i,object in pairs(enemyMinions) do
        if object == nil or object.dead == 1 then table.remove(enemyMinions, i) end
    end
end

function GetAllyMinions(sortMode)
    table.sort(allyMinions, sortMode)
    return allyMinions
end

function GetEnemyMinions(sortMode)
    table.sort(enemyMinions, sortMode)
    return enemyMinions
end

function GetLowestHealthEnemyMinion(range)
    table.sort(enemyMinions, MINION_SORT_HEALTH_ASC)
    for i = 1, #enemyMinions, 1 do
        if GetDistance(enemyMinions[i]) <= range then
            return enemyMinions[i]
        end
    end
    return nil
end
--################## END MINION MANAGER CLASS ##################--

SetTimerCallback("Util__Callback")
print('*** UTILS SetTimerCallback ***', GetScriptNumber())

if SCRIPT_PATH == nil then SCRIPT_PATH = '' end

-- help in porting, also serves as the first lb lib directory, even if we want to use a different lib directory officially
if package.path:find([[;.\Common\?]], 1, true) == nil then
    package.path = package.path..[[;.\Common\?]]
    package.path = package.path..[[;.\Common\?.lua]]
end