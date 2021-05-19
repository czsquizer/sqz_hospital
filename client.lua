ESX = nil
local isOnBed = false
local timer = 0
local doctorPed
local currentBedCoords
local hasLeft = true
local shouldDrawMarker = false
local markerCoords

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function GetFreeBed()
    local closestBed = nil
    local found = false

    for k, v in pairs(Config.Beds) do
        local cPlayer, cDist = ESX.Game.GetClosestPlayer(v.Loc)
        if cPlayer == -1 or cDist > 1.5 then
            found = true
            isOnBed = true
            closestBed = v
            break
        end
    end

    if not found then
        ESX.ShowNotification(_U('all_beds_occupied'))
        return closestBed
    end

    return closestBed

end

function GetOnTheBed(bed)
    local ped = PlayerPedId()

    SetEntityCoords(ped, bed.Loc + bed.OffSet)
    SetEntityHeading(ped, bed.Heading)
    currentBedCoords = bed.Loc
    hasLeft = false

    RequestAnimDict('anim@gangops@morgue@table@')
    while not HasAnimDictLoaded('anim@gangops@morgue@table@') do
        Wait(10)
    end

    timer = Config.HealingTimer

    TaskPlayAnim(ped, 'anim@gangops@morgue@table@', 'ko_front', 8.0, -8.0, -1, 1, 0, false, false, false)
    startTimer()

    SetTimeout(Config.HealingTimer * 1000 + 500, healingDone)
end

function healingDone()

    if not hasLeft and currentBedCoords and isOnBed then
        TriggerServerEvent('sqz_hospital:PayForHeal')
        Wait(500)
        ClearAround()
    end


end

RegisterNetEvent('sqz_hospital:HasEnoughMoney')
AddEventHandler('sqz_hospital:HasEnoughMoney', function()

    if not hasLeft and currentBedCoords and isOnBed then
        local ped = PlayerPedId()
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ClearPedWetness(ped)
        ClearPedBloodDamage(ped)
    else
        TriggerServerEvent('sqz_hospital:IamCheating')
    end

end)

Citizen.CreateThread(function()
    
    while true do
        if timer>0 then
            timer=timer-1
            Wait(1000)
        else
            Wait(500)
        end
    end

end)

Citizen.CreateThread(function()

    while true do
        Wait(0)
        if shouldDrawMarker then
            DrawMarker(20, markerCoords + vector3(0.0, 0.0, 0.65), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 0.8, true, true, 2, false, nil, nil, false)
        else
            Wait(1000)
        end
    end

end)

function startTimer()
    Citizen.CreateThread(function()
        while timer>0 do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
                Discharge()
                break
            end
            SetTextFont(4)
            SetTextScale(0.45, 0.45)
            SetTextColour(185, 185, 185, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(timeToDisp(timer).._U('doctor_healing'))
            EndTextCommandDisplayText(0.05, 0.55)

            DisableAllControlActions(1)
            DisableAllControlActions(0)
            DisableAllControlActions(2)
            DisableAllControlActions(3)
            EnableControlAction(0, 1, true)
			EnableControlAction(0, 2, true)
        end
    end)
end

function Discharge()
    --TaskGoStraightToCoord(doctorPed, Config.DoctorPos, 30000, 1.2, 1.0, 1073741824, 0)
    --TaskGoStraightToCoord(doctorPed, Config.DoctorPos,  0.3,  -1,  0.0,  0.0)
    ClearAround()
end

function ClearAround()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    RequestAnimDict('switch@franklin@bed')
    while not HasAnimDictLoaded('switch@franklin@bed') do
        Wait(50)
    end
    SetEntityHeading(ped, GetEntityHeading(ped) + 90.0)
    TaskPlayAnim(ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', -8.0, 8.0, 5000, 0, 0, 0, 0, 0)
    Wait(5000)
    FreezeEntityPosition(ped, false)
    isOnBed = false
    hasLeft = true
    timer = 0
    currentBedCoords = nil
    markerCoords = nil
    shouldDrawMarker = false
end

function timeToDisp(time)
    local minutes = math.floor((time%3600/60))
    local seconds = math.floor((time%60))
    return string.format("%02dm %02ds",minutes,seconds)
end

function CreateDoctor()

    Wait(1000)

    RequestModel(`s_m_m_doctor_01`)
    while not HasModelLoaded(`s_m_m_doctor_01`) do
        Wait(10)
    end

    doctorPed = CreatePed(2, `s_m_m_doctor_01`, Config.DoctorPos, 156.0, false, true) -- I am not sure with the 20 as a param of pedType

    while not DoesEntityExist(doctorPed) do
        print('Waiting until the ped is created')
        Wait(10)
    end

    TaskGoStraightToCoord(doctorPed, vector3(315.53173828125,-581.87268066406,43.284164428711),  0.3,  -1,  0.0,  0.0)
    Wait(4000)
    ClearPedTasks(doctorPed)
    Wait(100)
    TaskGoStraightToCoord(doctorPed, GetEntityCoords(PlayerPedId()),  0.3,  -1,  0.0,  0.0)
    SetEntityMaxSpeed(doctorPed, 1.3)
    while (#(GetEntityCoords(doctorPed) - GetEntityCoords(PlayerPedId()))) > 1.5 do
        if isOnBed then
            Wait(500)
        else
            break
        end
        Wait(0)
    end

    ClearPedTasksImmediately(doctorPed)
    TaskLookAtEntity(doctorPed, PlayerPedId(), 10000, 2048, 3)

    if isOnBed then

        local clipModel = CreateObject(GetHashKey('p_amb_clipboard_01'), GetEntityCoords(doctorPed), true, true, true)
        local penModel = CreateObject(GetHashKey('prop_pencil_01'), GetEntityCoords(doctorPed), true, true, true)

        while not DoesEntityExist(clipModel) or not DoesEntityExist(penModel) do
            Wait(0)
        end

        AttachEntityToEntity(penModel, doctorPed,  GetPedBoneIndex(doctorPed, 58866), 0.12, 0.00, 0.001, -150.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        AttachEntityToEntity(clipModel, doctorPed,  GetPedBoneIndex(doctorPed, 18905), 0.10, 0.02, 0.08, -68.0, 0.0, -40.0, 1, 1, 0, 1, 0, 1)
        TaskPlayAnim(doctorPed, 'missheistdockssetup1clipboard@base', 'base', 8.0, -8.0, 5000, 49, 0, false, false, false)

        Wait(5000)
        ClearPedTasks(doctorPed)
        DeleteObject(clipModel)
        DeleteObject(penModel)

    end

    --TaskGoStraightToCoord(doctorPed, Config.DoctorPos, 30000, 1.5, 1.0, 1073741824, 0) -- For me the bellow was better

    TaskGoStraightToCoord(doctorPed, vector3(315.53173828125,-581.87268066406,43.284164428711),  0.3,  -1,  0.0,  0.0)
    Wait(4000)
    ClearPedTasks(doctorPed)
    Wait(100)

    TaskGoStraightToCoord(doctorPed, Config.DoctorPos,  0.3,  -1,  0.0,  0.0)

    while (#(GetEntityCoords(doctorPed) - Config.DoctorPos)) > 1.5 do
        Wait(500)
    end

    DeleteEntity(doctorPed)

end

function StartClipBoardAnim(closestBed)
    local ped = PlayerPedId()

    RequestAnimDict('missheistdockssetup1clipboard@base')
    while not HasAnimDictLoaded('missheistdockssetup1clipboard@base') do
        Wait(10)
    end

    local clipModel = CreateObject(GetHashKey('p_amb_clipboard_01'), GetEntityCoords(ped), true, true, true)
    local penModel = CreateObject(GetHashKey('prop_pencil_01'), GetEntityCoords(ped), true, true, true)
    while not DoesEntityExist(clipModel) or not DoesEntityExist(penModel) do
        Wait(0)
    end

    AttachEntityToEntity(penModel, ped,  GetPedBoneIndex(PlayerPedId(), 58866), 0.12, 0.00, 0.001, -150.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
    AttachEntityToEntity(clipModel, ped,  GetPedBoneIndex(PlayerPedId(), 18905), 0.10, 0.02, 0.08, -68.0, 0.0, -40.0, 1, 1, 0, 1, 0, 1)
    TaskPlayAnim(ped, 'missheistdockssetup1clipboard@base', 'base', 8.0, -8.0, 5000, 49, 0, false, false, false)
    Wait(5000)

    DeleteEntity(clipModel)
    DeleteEntity(penModel)
    ClearPedTasks(ped)
    Wait(10)

    -- For now TaskGoToCoord does not work in the interiors, not sure why, I will be testing it in the future
    --[[for i=1, #Config.CheckPoints do
        print('Going for checkpoint: %s', i)
        TaskGoToCoordAnyMeans(PlayerPedId(), Config.CheckPoints[i], 1.0, 0, 0, 786603, 1.0)
        while (#(GetEntityCoords(PlayerPedId()) - Config.CheckPoints[i])) > 0.5 do
            print(#(GetEntityCoords(PlayerPedId()) - Config.CheckPoints[i]))
            Wait(500)
        end
    end--]]

    FreezeEntityPosition(PlayerPedId(), false)

    markerCoords = closestBed.Loc
    shouldDrawMarker = true
    local attempt = 0

    while (#(GetEntityCoords(PlayerPedId()) - closestBed.Loc)) > 1.5 and attempt < 61 do
        Wait(500)
        attempt = attempt + 1
        SetNotificationTextEntry('STRING')
        AddTextComponentString("Jdi do místnosti, kde jsou postele.")
        DrawNotification(0,1)
    end
    shouldDrawMarker = false
    GetOnTheBed(closestBed)
    CreateDoctor()

end

Citizen.CreateThread(function()
    AddTextEntry('reception', '~INPUT_PICKUP~ Check in')
    while true do
        Wait(0)
        local pedPos = GetEntityCoords(PlayerPedId())
        local dist = #(Config.ReceptionPos - pedPos)
        if dist > 10.0 then
            Wait(500)
        else
            if dist < 2.0 then
                BeginTextCommandDisplayHelp('reception')
                EndTextCommandDisplayHelp(1, 0, 0, 0)
                SetFloatingHelpTextWorldPosition(0, Config.ReceptionPos)
                SetFloatingHelpTextStyle()
                if IsControlPressed(0, 38) then

                    --SetEntityHealth(PlayerPedId(), 100) -- Remove after testing !!! Used only for testing

                    FreezeEntityPosition(PlayerPedId(), true)
                    local closestBed = GetFreeBed()

                    if closestBed then
                        StartClipBoardAnim(closestBed)
                    end
                end
            end
        end

    end

end)

-- Used for animations testing
--[[RegisterCommand("r", function()
    
    RequestAnimDict('missfbi1')
    while not HasAnimDictLoaded('missfbi1') do
        Wait(50)
    end
    SetEntityHeading(PlayerPedId(), 350.0)
    FreezeEntityPosition(PlayerPedId(), true)
    TaskPlayAnim(PlayerPedId(), 'missfbi1', 'cpr_pumpchest_idle', -8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(5000)
    FreezeEntityPosition(PlayerPedId(), false)
    
end)

RegisterCommand('rr', function()

    ClearPedTasksImmediately(PlayerPedId())
    
end, false)]]