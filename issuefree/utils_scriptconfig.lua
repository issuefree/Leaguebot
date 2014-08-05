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
            -- this is probably a decent place to fix old SC saving, just call __SC__saveMenu() without an if check
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
--################## END SCRIPT CONFIG CLASS ##################--
