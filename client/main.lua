local QBCore = exports['qb-core']:GetCoreObject()
local InApartment = false
local ClosestHouse = nil
local CurrentApartment = nil
local IsOwned = false
local CurrentDoorBell = 0
local CurrentOffset = 0
local houseObj = {}
local POIOffsets = nil
local rangDoorbell = nil

-- Handlers

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CurrentApartment = nil
    InApartment = false
    CurrentOffset = 0
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if houseObj ~= nil then
            exports['qb-interior']:DespawnInterior(houseObj, function()
                CurrentApartment = nil
                TriggerEvent('qb-weathersync:client:EnableSync')
                DoScreenFadeIn(500)
                while not IsScreenFadedOut() do
                    Wait(10)
                end
                SetEntityCoords(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.x, Apartments.Locations[ClosestHouse].coords.enter.y,Apartments.Locations[ClosestHouse].coords.enter.z)
                SetEntityHeading(PlayerPedId(), Apartments.Locations[ClosestHouse].coords.enter.w)
                Wait(1000)
                InApartment = false
                DoScreenFadeIn(1000)
            end)
        end
    end
end)

-- Functions

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function openHouseAnim()
    loadAnimDict("anim@heists@keycard@")
    TaskPlayAnim( PlayerPedId(), "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, 0, 0, 0 )
    Wait(400)
    ClearPedTasks(PlayerPedId())
end

local function EnterApartment(house, apartmentId, new)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
    openHouseAnim()
    Wait(250)
    QBCore.Functions.TriggerCallback('apartments:GetApartmentOffset', function(offset)
        if offset == nil or offset == 0 then
            QBCore.Functions.TriggerCallback('apartments:GetApartmentOffsetNewOffset', function(newoffset)
                if newoffset > 230 then
                    newoffset = 210
                end
                CurrentOffset = newoffset
                TriggerServerEvent("apartments:server:AddObject", apartmentId, house, CurrentOffset)
                local coords = { x = Apartments.Locations[house].coords.enter.x, y = Apartments.Locations[house].coords.enter.y, z = Apartments.Locations[house].coords.enter.z - CurrentOffset}
                data = exports['qb-interior']:CreateApartmentFurnished(coords)
                Wait(100)
                houseObj = data[1]
                POIOffsets = data[2]
                InApartment = true
                CurrentApartment = apartmentId
                ClosestHouse = house
                rangDoorbell = nil
                Wait(500)
                TriggerEvent('qb-weathersync:client:DisableSync')
                Wait(100)
                TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, false)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
                TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", CurrentApartment)
            end, house)
        else
            if offset > 230 then
                offset = 210
            end
            CurrentOffset = offset
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
            TriggerServerEvent("apartments:server:AddObject", apartmentId, house, CurrentOffset)
            local coords = { x = Apartments.Locations[ClosestHouse].coords.enter.x, y = Apartments.Locations[ClosestHouse].coords.enter.y, z = Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset}
            data = exports['qb-interior']:CreateApartmentFurnished(coords)
            Wait(100)
            houseObj = data[1]
            POIOffsets = data[2]
            InApartment = true
            CurrentApartment = apartmentId
            Wait(500)
            TriggerEvent('qb-weathersync:client:DisableSync')
            Wait(100)
            TriggerServerEvent('qb-apartments:server:SetInsideMeta', house, apartmentId, true, true)
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
            TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", CurrentApartment)
        end
        if new ~= nil then
            if new then
                TriggerEvent('qb-interior:client:SetNewState', true)
            else
                TriggerEvent('qb-interior:client:SetNewState', false)
            end
        else
            TriggerEvent('qb-interior:client:SetNewState', false)
        end
    end, apartmentId)
end

local function LeaveApartment(house)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.1)
    openHouseAnim()
    TriggerServerEvent("qb-apartments:returnBucket")
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    exports['qb-interior']:DespawnInterior(houseObj, function()
        TriggerEvent('qb-weathersync:client:EnableSync')
        SetEntityCoords(PlayerPedId(), Apartments.Locations[house].coords.enter.x, Apartments.Locations[house].coords.enter.y,Apartments.Locations[house].coords.enter.z)
        SetEntityHeading(PlayerPedId(), Apartments.Locations[house].coords.enter.w)
        Wait(1000)
        TriggerServerEvent("apartments:server:RemoveObject", CurrentApartment, house)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', CurrentApartment, false)
        CurrentApartment = nil
        InApartment = false
        CurrentOffset = 0
        DoScreenFadeIn(1000)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_close", 0.1)
        TriggerServerEvent("QBCore:Server:SetMetaData", "currentapartment", nil)
    end)
end

local function SetClosestApartment()
    local pos = GetEntityCoords(PlayerPedId())
    local current = nil
    local dist = 100
    for id, house in pairs(Apartments.Locations) do
        local distcheck = #(pos - vector3(Apartments.Locations[id].coords.enter.x, Apartments.Locations[id].coords.enter.y, Apartments.Locations[id].coords.enter.z))

            if distcheck < dist then
                current = id
            end

    end
    if current ~= ClosestHouse and LocalPlayer.state.isLoggedIn and not InApartment then
        ClosestHouse = current
        QBCore.Functions.TriggerCallback('apartments:IsOwner', function(result)
            IsOwned = result
        end, ClosestHouse)
    end
end

local function MenuOwners()
    QBCore.Functions.TriggerCallback('apartments:GetAvailableApartments', function(apartments)
        if next(apartments) == nil then
            QBCore.Functions.Notify(Lang:t('error.nobody_home'), "error", 3500)
            closeMenuFull()
        else
            local vehicleMenu = {
                {
                    header = Lang:t('text.tennants'),
                    isMenuHeader = true
                }
            }

            for k, v in pairs(apartments) do
                vehicleMenu[#vehicleMenu+1] = {
                    header = v,
                    txt = "",
                    params = {
                        event = "apartments:client:RingMenu",
                        args = {
                            apartmentId = k
                        }
                    }

                }
            end

            vehicleMenu[#vehicleMenu+1] = {
                header = Lang:t('text.close_menu'),
                txt = "",
                params = {
                    event = "qb-menu:client:closeMenu"
                }

            }
            exports['qb-menu']:openMenu(vehicleMenu)
        end
    end, ClosestHouse)
end

function closeMenuFull()
    exports['qb-menu']:closeMenu()
end

-- Events
RegisterNetEvent('apartments:client:setupSpawnUI', function(cData)
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result then
            TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
            TriggerEvent('qb-spawn:client:openUI', true)
            TriggerEvent("apartments:client:SetHomeBlip", result.type)
        else
            if Apartments.Starting then
                TriggerEvent('qb-spawn:client:setupSpawns', cData, true, Apartments.Locations)
                TriggerEvent('qb-spawn:client:openUI', true)
            else
                TriggerEvent('qb-spawn:client:setupSpawns', cData, false, nil)
                TriggerEvent('qb-spawn:client:openUI', true)
            end
        end
    end, cData.citizenid)
end)

RegisterNetEvent('apartments:client:SpawnInApartment', function(apartmentId, apartment)
    local pos = GetEntityCoords(PlayerPedId())
    if rangDoorbell ~= nil then
        local doorbelldist = #(pos - vector3(Apartments.Locations[rangDoorbell].coords.enter.x, Apartments.Locations[rangDoorbell].coords.enter.y,Apartments.Locations[rangDoorbell].coords.enter.z))
        if doorbelldist > 5 then
            QBCore.Functions.Notify(Lang:t('error.to_far_from_door'))
            return
        end
    end
    ClosestHouse = apartment
    EnterApartment(apartment, apartmentId, true)
    IsOwned = true
end)

RegisterNetEvent('qb-apartments:client:LastLocationHouse', function(apartmentType, apartmentId)
    ClosestHouse = apartmentType
    EnterApartment(apartmentType, apartmentId, false)
end)

RegisterNetEvent('apartments:client:SetHomeBlip', function(home)
    CreateThread(function()
        SetClosestApartment()
        for name, apartment in pairs(Apartments.Locations) do
            RemoveBlip(Apartments.Locations[name].blip)

            Apartments.Locations[name].blip = AddBlipForCoord(Apartments.Locations[name].coords.enter.x, Apartments.Locations[name].coords.enter.y, Apartments.Locations[name].coords.enter.z)
            if (name == home) then
                SetBlipSprite(Apartments.Locations[name].blip, 475)
            else
                SetBlipSprite(Apartments.Locations[name].blip, 476)
            end
            SetBlipDisplay(Apartments.Locations[name].blip, 4)
            SetBlipScale(Apartments.Locations[name].blip, 0.65)
            SetBlipAsShortRange(Apartments.Locations[name].blip, true)
            SetBlipColour(Apartments.Locations[name].blip, 3)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Apartments.Locations[name].label)
            EndTextCommandSetBlipName(Apartments.Locations[name].blip)
        end
    end)
end)

RegisterNetEvent('apartments:client:RingMenu', function(data)
    rangDoorbell = ClosestHouse
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
    TriggerServerEvent("apartments:server:RingDoor", data.apartmentId, ClosestHouse)
end)

RegisterNetEvent('apartments:client:RingDoor', function(player, house)
    CurrentDoorBell = player
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
    QBCore.Functions.Notify(Lang:t('info.at_the_door'))
end)

RegisterNetEvent('apartments:client:DoorbellMenu', function()
    MenuOwners()
end)

RegisterNetEvent('apartments:client:EnterApartment', function()
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(result)
        if result ~= nil then
            EnterApartment(ClosestHouse, result.name)
        end
    end)
end)

RegisterNetEvent('apartments:client:UpdateApartment', function()
    local apartmentType = ClosestHouse
    local apartmentLabel = Apartments.Locations[ClosestHouse].label
    TriggerServerEvent("apartments:server:UpdateApartment", apartmentType, apartmentLabel)
    IsOwned = true
end)

-- Threads

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn and not InApartment then
            SetClosestApartment()
        end
        Wait(5000)
    end
end)

CreateThread(function()
    local shownHeader = false
    while true do
        local sleep = 1000
        if LocalPlayer.state.isLoggedIn and ClosestHouse then
            sleep = 5
            if InApartment then
                local headerMenu = {}
                local inRange = false
                local pos = GetEntityCoords(PlayerPedId())
                local entrancedist = #(pos - vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.exit.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.exit.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.exit.z))
                local stashdist = #(pos - vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.stash.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.stash.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.stash.z))
                local outfitsdist = #(pos - vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.clothes.x, Apartments.Locations[ClosestHouse].coords.enter.y - POIOffsets.clothes.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.clothes.z))
                local logoutdist = #(pos - vector3(Apartments.Locations[ClosestHouse].coords.enter.x - POIOffsets.logout.x, Apartments.Locations[ClosestHouse].coords.enter.y + POIOffsets.logout.y, Apartments.Locations[ClosestHouse].coords.enter.z - CurrentOffset + POIOffsets.logout.z))

                -- Enter
                if CurrentDoorBell ~= 0 then
                    if entrancedist <= 1 then
                        inRange = true
                        headerMenu = Lang:t('text.open_door')
                        if IsControlJustPressed(0, 47) then -- G
                            TriggerServerEvent("apartments:server:OpenDoor", CurrentDoorBell, CurrentApartment, ClosestHouse)
                            CurrentDoorBell = 0
                        end
                    end
                end

                --Exit
                if entrancedist <= 1 then
                    inRange = true
                    headerMenu = Lang:t('text.leave')
                    if IsControlJustPressed(0, 74) then -- H
                        LeaveApartment(ClosestHouse)
                    end
                end


                --Stash
                if stashdist <= 1.2 then
                    inRange = true
                    headerMenu = Lang:t('text.open_stash')
                    if IsControlJustPressed(0, 74) then -- H
                        if CurrentApartment ~= nil then
                            TriggerServerEvent("inventory:server:OpenInventory", "stash", CurrentApartment)
                            TriggerServerEvent("InteractSound_SV:PlayOnSource", "StashOpen", 0.4)
                            TriggerEvent("inventory:client:SetCurrentStash", CurrentApartment)
                        end
                    end
                end

                --Outfits
                if outfitsdist <= 1 then
                    inRange = true
                    headerMenu = Lang:t('text.change_outfit')
                    if IsControlJustPressed(0, 47) then -- G
                        TriggerServerEvent("InteractSound_SV:PlayOnSource", "Clothes1", 0.4)
                        TriggerEvent('qb-clothing:client:openOutfitMenu')
                    end
                end

                --Logout
                if logoutdist <= 1 then
                    inRange = true
                    headerMenu = Lang:t('text.logout')
                    if IsControlJustPressed(0, 74) then -- H
                        TriggerServerEvent('qb-houses:server:LogoutLocation')
                    end
                end

                if inRange and not shownHeader then
                    shownHeader = true
                    exports["qb-ui"]:showInteraction(headerMenu, 'info')
                end

                if not inRange and shownHeader then
                    shownHeader = false
                    exports["qb-ui"]:hideInteraction()
                end

            else
                local headerMenu = {}
                local inRange = false
                local pos = GetEntityCoords(PlayerPedId())
                local entrance = #(pos - vector3(Apartments.Locations[ClosestHouse].coords.enter.x, Apartments.Locations[ClosestHouse].coords.enter.y,Apartments.Locations[ClosestHouse].coords.enter.z))

                if IsOwned then
                    if entrance <= 1 then
                        inRange = true
                        headerMenu = Lang:t('text.enter_move')
                        if IsControlJustPressed(0, 74) then --H
                            TriggerEvent('apartments:client:EnterApartment')
                        elseif IsControlJustPressed(0, 47) then -- G
                            local MenuOwnApartment = {
                                {
                                    header = "Apartments Options",
                                    isMenuHeader = true
                                },
                                {
                                    header = Lang:t('text.enter'),
                                    txt = "Enter Your Apartment",
                                    params = {
                                        event = 'apartments:client:EnterApartment',
                                        args = {}
                                    }
                                },
                                {
                                    header = Lang:t('text.ring_doorbell'),
                                    txt = "Ring Door Bell Online Players",
                                    params = {
                                        event = 'apartments:client:DoorbellMenu',
                                        args = {}
                                    }
                                },
                                {
                                    header = Lang:t('text.close_menu'),
                                    params = {
                                        event = "qb-menu:closeMenu",
                                    }
                                }
                            }
                            exports['qb-menu']:openMenu(MenuOwnApartment)
                        end
                    end
                elseif not IsOwned then
                    if entrance <= 1 then
                        inRange = true
                        headerMenu = "[G] For More"
                        if IsControlJustPressed(0, 47) then -- G
                            local MenuNotOwnApartment = {
                                {
                                    header = "Apartments Options",
                                    isMenuHeader = true
                                },
                                {
                                    header = Lang:t('text.move_here'),
                                    txt = "Change Apartment",
                                    params = {
                                        event = 'apartments:client:UpdateApartment',
                                        args = {}
                                    }
                                },
                                {
                                    header = Lang:t('text.ring_doorbell'),
                                    txt = "Ring Door Bell Online Players",
                                    params = {
                                        event = 'apartments:client:DoorbellMenu',
                                        args = {}
                                    }
                                },
                                {
                                    header = Lang:t('text.close_menu'),
                                    params = {
                                        event = "qb-menu:closeMenu",
                                    }
                                }
                            }
                            exports['qb-menu']:openMenu(MenuNotOwnApartment)
                        end
                    end
                end

                if inRange and not shownHeader then
                    shownHeader = true
                    exports["qb-ui"]:showInteraction(headerMenu, 'info')
                end
        
                if not inRange and shownHeader then
                    shownHeader = false
                    exports["qb-ui"]:hideInteraction()
                end
            end
        end
        Wait(sleep)
    end
end)
