local L = Config.Locale

local colors = {}
for i = 1, #Config.Colors do
    colors[Config.Colors[i].name] = true
end

local colorList = {}
for i = 1, #Config.Colors do colorList[i] = Config.Colors[i].name end
colorList = table.concat(colorList, ', ')

local function getState(source)
    return Player(source).state.plumbob
end

-- active / color = nil keeps the current value
local function setState(source, active, color)
    local current = getState(source) or { active = false, color = Config.DefaultColor }
    if color ~= nil and not colors[color] then return false end
    if active == nil then active = current.active end
    if color == nil then color = current.color end

    Player(source).state:set('plumbob', { active = active == true, color = color }, true)
    return true
end

local function notify(source, ntype, msg)
    if source == 0 then
        print(('[plumbob] %s'):format(msg))
    else
        TriggerClientEvent('ox_lib:notify', source, { type = ntype, description = msg })
    end
end

local lastRequest = {}

AddEventHandler('playerDropped', function()
    lastRequest[source] = nil
end)

-- Request from a player to change their own plumbob (menu / client exports)
RegisterNetEvent('double_plumbob:setState', function(active, color)
    local src = source

    if not Config.AllowSelfToggle and not IsPlayerAceAllowed(src, Config.AdminAce) then
        return notify(src, 'error', L.self_disabled)
    end

    local now = GetGameTimer()
    if lastRequest[src] and now - lastRequest[src] < Config.Cooldown then return end
    lastRequest[src] = now

    if active ~= nil and type(active) ~= 'boolean' then return end
    if color ~= nil and type(color) ~= 'string' then return end

    setState(src, active, color)
end)

--   /plumbob                    -> menu (players)
--   /plumbob <id>               -> toggle
--   /plumbob <id> <colour>      -> show in that colour
--   /plumbob <id> hide          -> hide
RegisterCommand(Config.Command, function(source, args)
    local isConsole = source == 0

    if #args == 0 then
        if isConsole then
            print(('[plumbob] ' .. L.usage):format(Config.Command))
        elseif Config.AllowSelfToggle or IsPlayerAceAllowed(source, Config.AdminAce) then
            TriggerClientEvent('double_plumbob:openMenu', source)
        else
            notify(source, 'error', L.self_disabled)
        end
        return
    end

    if not isConsole and not IsPlayerAceAllowed(source, Config.AdminAce) then
        return notify(source, 'error', L.no_permission)
    end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        return notify(source, 'error', L.invalid_player:format(tostring(args[1])))
    end

    local action = args[2] and args[2]:lower()

    if not action then
        local state = getState(target)
        local wasActive = state and state.active or false
        setState(target, not wasActive, nil)
        notify(source, 'success', (wasActive and L.hidden or L.shown):format(target))
    elseif action == 'hide' then
        setState(target, false, nil)
        notify(source, 'success', L.hidden:format(target))
    elseif colors[action] then
        setState(target, true, action)
        notify(source, 'success', L.color_set:format(action, target))
    else
        notify(source, 'error', L.invalid_action:format(colorList))
    end
end, false)

exports('Show', function(source, color) return setState(source, true, color) end)
exports('Hide', function(source) return setState(source, false, nil) end)
exports('SetColor', function(source, color) return setState(source, nil, color) end)

exports('GetColor', function(source)
    local state = getState(source)
    return state and state.color or Config.DefaultColor
end)

exports('IsShown', function(source)
    local state = getState(source)
    return state and state.active or false
end)
