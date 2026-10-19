local L = Config.Locale

local models = {}
for i = 1, #Config.Colors do
    models[Config.Colors[i].name] = Config.Colors[i].model
end

-- serverId -> { ent = entity, color = colour name }
local active = {}

local function despawn(serverId)
    local data = active[serverId]
    if not data then return end
    if data.ent and DoesEntityExist(data.ent) then DeleteEntity(data.ent) end
    active[serverId] = nil
end

local function spawn(serverId, color)
    local model = models[color] or models[Config.DefaultColor]
    if not model or not IsModelInCdimage(model) then
        print(('^3[plumbob]^7 model for colour "%s" is not streamed'):format(tostring(color)))
        return
    end

    -- Claim the slot before the model loads (that yields), so the scope loop and the
    -- state bag handler can't spawn a second prop that would be left floating
    local data = { color = color }
    active[serverId] = data

    local loaded = pcall(lib.requestModel, model)
    -- colour changed or plumbob hidden while loading: a newer call owns the slot
    if active[serverId] ~= data then return end
    if not loaded then active[serverId] = nil return end

    local player = GetPlayerFromServerId(serverId)
    local ped = player ~= -1 and GetPlayerPed(player) or 0
    if ped == 0 or not DoesEntityExist(ped) then
        active[serverId] = nil
        return
    end

    local head = GetPedBoneCoords(ped, Config.Bone, 0.0, 0.0, 0.0)
    local pos = head + Config.Offset
    local prop = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
    SetModelAsNoLongerNeeded(model)

    SetEntityCollision(prop, false, false)
    FreezeEntityPosition(prop, true)
    SetEntityInvincible(prop, true)
    SetEntityLodDist(prop, 0xFFFF)
    -- hidden until the render loop has placed it above the head
    SetEntityVisible(prop, false, false)

    data.ent = prop
    data.visible = false
end

-- Bring one player's prop in line with their state bag
local function evaluate(serverId)
    local state = Player(serverId).state.plumbob
    local current = active[serverId]

    if not (state and state.active) then
        if current then despawn(serverId) end
        return
    end

    if GetPlayerFromServerId(serverId) == -1 then return end -- not in scope yet

    local color = state.color or Config.DefaultColor
    if current and current.color == color and (not current.ent or DoesEntityExist(current.ent)) then
        return -- up to date, or still loading this colour
    end

    despawn(serverId)
    spawn(serverId, color)
end

AddStateBagChangeHandler('plumbob', nil, function(bagName)
    local serverId = tonumber(bagName:match('^player:(%d+)$'))
    if not serverId then return end
    -- the handler runs before the value is applied
    SetTimeout(0, function() evaluate(serverId) end)
end)

-- Players entering scope + cleanup of props whose owner left
CreateThread(function()
    while true do
        Wait(1500)

        local players = GetActivePlayers()
        for i = 1, #players do
            evaluate(GetPlayerServerId(players[i]))
        end

        for serverId in pairs(active) do
            if GetPlayerFromServerId(serverId) == -1 then despawn(serverId) end
        end
    end
end)

-- Move every prop above its owner's head each frame
CreateThread(function()
    local anim = Config.Animation
    local spin, phase = 0.0, 0.0

    while true do
        if next(active) then
            local bob = 0.0
            if anim.enabled then
                local dt = GetFrameTime()
                spin = (spin + anim.spinSpeed * dt) % 360.0
                phase = (phase + anim.bobSpeed * dt) % 1.0
                bob = math.sin(phase * 2.0 * math.pi) * anim.bobHeight
            end

            for serverId, data in pairs(active) do
                if data.ent and DoesEntityExist(data.ent) then
                    local player = GetPlayerFromServerId(serverId)
                    local ped = player ~= -1 and GetPlayerPed(player) or 0
                    -- follow the ped's visibility (noclip, character select); never leave it hanging in the air
                    local visible = ped ~= 0 and DoesEntityExist(ped) and IsEntityVisible(ped)

                    if visible then
                        local head = GetPedBoneCoords(ped, Config.Bone, 0.0, 0.0, 0.0)
                        SetEntityCoordsNoOffset(data.ent,
                            head.x + Config.Offset.x,
                            head.y + Config.Offset.y,
                            head.z + Config.Offset.z + bob,
                            false, false, false)
                        SetEntityRotation(data.ent, 0.0, 0.0, spin, 2, true)
                    end

                    if visible ~= data.visible then
                        SetEntityVisible(data.ent, visible, false)
                        data.visible = visible
                    end
                end
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for serverId in pairs(active) do despawn(serverId) end
end)

local function request(show, color)
    TriggerServerEvent('double_plumbob:setState', show, color)
end

local menuRegistered = false

local function registerMenu()
    if menuRegistered then return end

    local colorOptions = {}
    for i = 1, #Config.Colors do
        local c = Config.Colors[i]
        colorOptions[i] = { title = c.label, onSelect = function() request(true, c.name) end }
    end

    lib.registerContext({
        id = 'double_plumbob_colors',
        title = L.menu_color,
        menu = 'double_plumbob',
        options = colorOptions,
    })

    lib.registerContext({
        id = 'double_plumbob',
        title = L.menu_title,
        options = {
            { title = L.menu_show, icon = 'eye', onSelect = function() request(true, nil) end },
            { title = L.menu_hide, icon = 'eye-slash', onSelect = function() request(false, nil) end },
            { title = L.menu_color, icon = 'palette', menu = 'double_plumbob_colors' },
        },
    })

    menuRegistered = true
end

RegisterNetEvent('double_plumbob:openMenu', function()
    registerMenu()
    lib.showContext('double_plumbob')
end)

exports('Show', function(color) request(true, color) end)
exports('Hide', function() request(false, nil) end)
exports('SetColor', function(color) request(nil, color) end)

exports('GetColor', function()
    local state = LocalPlayer.state.plumbob
    return state and state.color or Config.DefaultColor
end)

exports('IsShown', function()
    local state = LocalPlayer.state.plumbob
    return state and state.active or false
end)
