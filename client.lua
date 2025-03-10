---@diagnostic disable: deprecated


local engineupmulti = 1.05
local incLin = 0.200
local incExp = 1.125
local incGear = 1.50



local vehicle = nil
local acc = 0
local hbrake = 0
local numgears = 0
local topspeedGTA = 0
local topspeedms = 0
local currspeedlimit = 0

local ready = false
local clutch = false
local selectedgear = 0
local targetgear = 0


local seqAssist = true

local manualon = false
local realistic = false









local function getinfo(gea)
    if gea == 0 then
        return "N"
    elseif gea == -1 then
        return "R"
    else
        return gea
    end
end

local function round(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

local function resetvehicle()
    if vehicle == GetLastDrivenVehicle() then
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", acc)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel",topspeedGTA)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
        SetVehicleHighGear(vehicle, numgears)
        ModifyVehicleTopSpeed(vehicle,1)
        --SetVehicleMaxSpeed(vehicle,topspeedms)
        SetVehicleHandbrake(vehicle, false)
    end

    vehicle = nil
    acc = 0
    hbrake = 0
    numgears = 0
    topspeedGTA = 0
    topspeedms = 0
    currspeedlimit = 0

    ready = false
    clutch = false
    selectedgear = 0
    targetgear = 0

end

local function SimulateGears()

    if selectedgear > 0 then

        local ratio

        -- ratio = Config.gears[numgears][selectedgear] * (1/0.9)
        ratio = ( ((numgears - selectedgear) * incLin) + math.pow(math.pow(incExp, numgears - selectedgear), math.pow((6 / numgears), incGear)) )
        if selectedgear == 1 and numgears > 1 then
            ratio = ratio + 1.2
        end
        if selectedgear == 2 and numgears > 2 then
            ratio = ratio + 0.7
        end
        if selectedgear == 3 and numgears > 3 then
            ratio = ratio + 0.4
        end

        -- SetVehicleHighGear(vehicle,selectedgear)
        SetVehicleHighGear(vehicle,1)
        local enginemulti = (math.pow(engineupmulti, (GetVehicleMod(vehicle,11) + 1)))

        local newacc = ratio * acc * enginemulti
        local newtopspeedGTA = topspeedGTA / ratio * enginemulti
        local newtopspeedms = topspeedms / ratio * enginemulti

        --if GetEntitySpeed(vehicle) > newtopspeedms then
            --selectedgear = selectedgear + 1
        --else

        SetVehicleHandbrake(vehicle, false)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", newacc)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", newtopspeedGTA)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
        ModifyVehicleTopSpeed(vehicle,1)

        -- SetVehicleMaxSpeed(vehicle,newtopspeedms)

        currspeedlimit = newtopspeedms
    elseif selectedgear == 0 then
        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", 0.0)
        currspeedlimit = 0
    elseif selectedgear == -1 then

        SetVehicleHandbrake(vehicle, false)
        SetVehicleHighGear(vehicle,numgears)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", acc)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
        ModifyVehicleTopSpeed(vehicle,1)

        --SetVehicleMaxSpeed(vehicle,topspeedms)

        currspeedlimit = topspeedms

    end
    if GetVehicleMod(vehicle, 18) ~= -1 then
        SetVehicleTurboPressure(vehicle, GetVehicleTurboPressure(vehicle) - 0.075)
    end
    -- SetVehicleMod(vehicle,11,engineup,false)

    exports('isManualOn', function()
        return manualon
    end)

    exports('getGear', function()
        if clutch == true then
            return getinfo(selectedgear).."("..getinfo(targetgear)..")"
        else
            return getinfo(selectedgear)
        end
    end)

end







RegisterCommand("manual", function()
    if vehicle then
        if GetVehicleType(vehicle) == "automobile" then
            if not manualon then
                manualon = true
                if realistic then
                    ESX.ShowNotification('Transmission: Manual')
                else
                    ESX.ShowNotification('Transmission: Sequential')
                end
                --TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode ON' .. '^7.')
            else
                resetvehicle()
                manualon = false
                ESX.ShowNotification('Transmission: Automatic')
                --TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode OFF' .. '^7.')
            end
        else
            ESX.ShowNotification('This feature is unavailable for this vehicle!', 'error')
        end
    else
        ESX.ShowNotification('You need to be in a vehicle to use this feature!', 'warning')
    end
end)

RegisterCommand("manualmode", function()
    if vehicle then
        if GetVehicleType(vehicle) == "automobile" then
            if not manualon then
            else
                if realistic then
                    realistic = false
                    clutch = false
                    ESX.ShowNotification('Transmission: Sequential')
                    --TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode SIMPLE' .. '^7.')
                else
                    realistic = true
                    ESX.ShowNotification('Transmission: Manual')
                    --TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode REALISTIC' .. '^7.')
                end
            end
        else
            ESX.ShowNotification('This feature is unavailable for this vehicle!', 'error')
        end
    else
        ESX.ShowNotification('You need to be in a vehicle to use this feature!', 'warning')
    end
end)

RegisterCommand("seqassist", function(source, args)
    if vehicle then
        if GetVehicleType(vehicle) == "automobile" then
            if not manualon then
            else
                if args[1] then
                    if args[1]:lower() == 'normal' then
                        seqAssist = true
                        ESX.ShowNotification('Sequential Assist Mode: Normal', 'info')
                    elseif args[1]:lower() == 'drift' then
                        seqAssist = args[1]:lower()
                        ESX.ShowNotification('Sequential Assist Mode: Drift', 'info')
                    elseif args[1]:lower() == 'cruise' then
                        seqAssist = args[1]:lower()
                        ESX.ShowNotification('Sequential Assist Mode: Cruise', 'info')
                    elseif args[1]:lower() == 'sport' then
                        seqAssist = args[1]:lower()
                        ESX.ShowNotification('Sequential Assist Mode: Sport', 'info')
                    end
                else
                    if type(seqAssist) ~= 'boolean' then
                        seqAssist = false
                        ESX.ShowNotification('Sequential Assist Mode: Off', 'info')
                    else
                        if seqAssist then
                            seqAssist = false
                            ESX.ShowNotification('Sequential Assist Mode: Off', 'info')
                        else
                            seqAssist = true
                            ESX.ShowNotification('Sequential Assist Mode: Nornal', 'info')
                        end
                    end
                end
            end
        else
            ESX.ShowNotification('This feature is unavailable for this vehicle!', 'error')
        end
    else
        ESX.ShowNotification('You need to be in a vehicle to use this feature!', 'warning')
    end
end)







RegisterKey('keyboard', 'LCONTROL', 'Vehicle (Manual): [H] Clutch',
function()
    if manualon and realistic and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
        if ready then
            clutch = true
            DisableControlAction(0, 71, true)
            targetgear = selectedgear
            selectedgear = 0
            SimulateGears()
        end
    end
end,
function()
    if manualon == true and realistic and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
        if ready then
            selectedgear = targetgear
            SimulateGears()
            DisableControlAction(0, 71, false)
            clutch = false
        end
    end
end)


RegisterKey('keyboard', 'PAGEUP', 'Vehicle (Manual): Shift +Up',
function()
    if manualon and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
        if ready then
            if selectedgear < numgears then
                if realistic == true and clutch == true and targetgear < numgears then
                    targetgear = targetgear + 1
                elseif realistic == false then
                    ready = false
                    DisableControlAction(0, 71, true)
                    selectedgear = selectedgear + 1
                    Wait(300)
                    DisableControlAction(0, 71, false)
                    SimulateGears()
                    ready = true
                end
            end
        end
    end
end)


RegisterKey('keyboard', 'PAGEDOWN', 'Vehicle (Manual): Shift -Down',
function()
    if manualon and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
        if ready then
            if selectedgear > -1 then
                if realistic == true and clutch == true and targetgear > -1 then
                    targetgear = targetgear - 1
                elseif realistic == false then
                    ready = false
                    -- DisableControlAction(0, 71, true)
                    selectedgear = selectedgear - 1
                    Wait(100)
                    -- DisableControlAction(0, 71, false)
                    SimulateGears()
                    ready = true
                end
            end
        end
    end
end)


RegisterKey('keyboard', 'DELETE', 'Vehicle (Manual): Shift >Neutral',
function()
    if manualon and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
        if ready then
            if realistic and clutch then
                targetgear = 0
            elseif realistic == false then
                ready = false
                -- DisableControlAction(0, 71, true)
                selectedgear = 0
                Wait(300)
                -- DisableControlAction(0, 71, false)
                SimulateGears()
                ready = true
            end
        end
    end
end)










Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)

        local ped = PlayerPedId()
        local newveh = GetVehiclePedIsIn(ped,false)

        if newveh == vehicle then

        elseif newveh == 0 and vehicle ~= nil then
            resetvehicle()
        else
            if GetPedInVehicleSeat(newveh,-1) == ped then
                resetvehicle()
                local class = GetVehicleClass(newveh)
                if class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16 and class ~= 21 then
                    vehicle = newveh
                   
                    
                    if GetVehicleMod(vehicle,13) < 0 then
                        numgears = GetVehicleHandlingInt(newveh, "CHandlingData", "nInitialDriveGears")
                    else
                        numgears = GetVehicleHandlingInt(newveh, "CHandlingData", "nInitialDriveGears") + 1
                    end
                    
                    

                    hbrake = GetVehicleHandlingFloat(newveh, "CHandlingData", "fHandBrakeForce")
                    
                    topspeedGTA = GetVehicleHandlingFloat(newveh, "CHandlingData", "fInitialDriveMaxFlatVel")
                    topspeedms = (topspeedGTA * 1.32)/3.6
                    currspeedlimit = 0

                    acc = GetVehicleHandlingFloat(newveh, "CHandlingData", "fInitialDriveForce")
                    --SetVehicleMaxSpeed(newveh,topspeedms)
                    selectedgear = 0
                    Citizen.Wait(50)
                    ready = true
                    -- SetVehicleEngineOn(vehicle,true,true,false)
                end
            end
        end

    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if manualon and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
            if selectedgear == -1 then
                if GetVehicleCurrentGear(vehicle) == 1 then
                    DisableControlAction(0, 71, true)
                end
            elseif selectedgear > 0 then
                if GetEntitySpeedVector(vehicle,true).y < 0.0 then   
                    DisableControlAction(0, 72, true)
                end
            elseif selectedgear == 0 then
                SetVehicleHandbrake(vehicle, true)
                if IsControlPressed(0, 76) == false then
                    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
                else
                    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                end
            end
        else
            Citizen.Wait(100)
        end
    end
end)



local isStalling = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if realistic then
            if manualon and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
                if IsControlPressed(0,71) then
                    local speed = GetEntitySpeed(vehicle) 
                    local minspeed = currspeedlimit / 7
                    if speed < minspeed and selectedgear > 3 then
                        if GetVehicleCurrentRpm(vehicle) < 0.45 then
                            isStalling = true

                            -- BeginTextCommandThefeedPost("STRING")
                            -- AddTextComponentSubstringPlayerName("Stalled.")
                            -- EndTextCommandThefeedPostTicker(true, true)

                            -- TriggerEvent('chat:addMessage', {
                            --     color = { 255, 255, 255},
                            --     multiline = true,
                            --     args = {"", ThefeedGetFirstVisibleDeleteRemaining()}
                            -- })

                            Citizen.Wait(3000)
                            -- ThefeedRemoveItem(-1)
                            -- ThefeedClearFrozenPost()
                            SetVehicleEngineOn(vehicle,false,true,true)
                            isStalling = false
                        end
                    end
                end
            else
                Citizen.Wait(100)
            end
        else
            Citizen.Wait(100)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if manualon == true and vehicle ~= nil and isStalling == true then
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 1.0)
            SetTextColour(128, 128, 128, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~r~STALL")
            DrawText(0.03, 0.80)
        else
            Citizen.Wait(100)
        end
    end
end)



Citizen.CreateThread(function()
    while true do

        Citizen.Wait(0)
        if vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
            if Config.enginebrake then

                local speed = GetEntitySpeed(vehicle)
                local enginemulti = (math.pow(engineupmulti, (GetVehicleMod(vehicle,11) + 1)))

                if manualon then
                    
                    if speed >= currspeedlimit and selectedgear >= 1 then
                        
                        if (speed / currspeedlimit) > 1 then
                            SetVehicleCurrentRpm(vehicle,1.0)
                            SetVehicleCheatPowerIncrease(vehicle,-100.0)
                            --SetVehicleBurnout(vehicle,true)
                        else
                            --SetVehicleBurnout(vehicle,false)
                            SetVehicleCheatPowerIncrease(vehicle,0.0)
                        end
                        
                        
                        --SetVehicleHandbrake(vehicle, true)
                        --if IsControlPressed(0, 76) == false then
                            --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
                    -- else
                            --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                        --end

                    else


                        --SetVehicleHandbrake(vehicle, false)
                        --if IsControlPressed(0, 76) == false then

                        --else
                            --SetVehicleHandbrake(vehicle, true)
                            --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                        --end  
                
                    end
                
                elseif topspeedms then
                    
                    if speed >= (topspeedms * enginemulti) then
                        -- SetVehicleCheatPowerIncrease(vehicle,0.0)
                        
                        if ((speed / topspeedms) * enginemulti) > 1 then
                            SetVehicleCurrentRpm(vehicle,1.0)
                            SetVehicleCheatPowerIncrease(vehicle,-100.0)
                            --SetVehicleBurnout(vehicle,true)
                        else
                            --SetVehicleBurnout(vehicle,false)
                            SetVehicleCheatPowerIncrease(vehicle,0.0)
                        end
                        --SetVehicleHandbrake(vehicle, true)
                        --if IsControlPressed(0, 76) == false then
                            --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
                        --else
                            --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                        --end
        
        
                    else
                        --SetVehicleHandbrake(vehicle, false)
                        --if IsControlPressed(0, 76) == false then
                            
                        --else
                            --SetVehicleHandbrake(vehicle, true)
                            --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                        --end 
        
                    end


                end
            

                
            
            
            end
        end

    end
end)



Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if manualon and vehicle == GetVehiclePedIsIn(PlayerPedId(),false) then
            DisableControlAction(0, 80, true)
            DisableControlAction(0, 21, true)
            SetVehicleHighGear(vehicle,1)

            if ready and seqAssist then

                local shiftThreshUp = 0.99
                local shiftThreshDn = 0.21
                if seqAssist == 'drift' then
                    shiftThreshUp = 0.99
                    shiftThreshDn = 0.90
                elseif seqAssist == 'cruise' then
                    shiftThreshUp = 0.80
                    shiftThreshDn = 0.60
                elseif seqAssist == 'sport' then
                    shiftThreshUp = 0.90
                    shiftThreshDn = 0.65
                end

                if GetVehicleCurrentRpm(vehicle) >= shiftThreshUp then
                    if 0 < selectedgear and selectedgear < numgears then
                        if realistic == false then
                            ready = false
                            DisableControlAction(0, 71, true)
                            selectedgear = selectedgear + 1
                            SimulateGears()
                            Wait(1000)
                            DisableControlAction(0, 71, false)
                            ready = true
                        end
                    end
                elseif GetVehicleCurrentRpm(vehicle) <= shiftThreshDn then
                    if 1 < selectedgear and selectedgear <= numgears then
                        if realistic == false then
                            ready = false
                            -- DisableControlAction(0, 71, true)
                            selectedgear = selectedgear - 1
                            SimulateGears()
                            Wait(200)
                            -- DisableControlAction(0, 71, false)
                            ready = true
                        end
                    end
                end

            end

        end
    end

end)











---------------debug

-- Citizen.CreateThread(function()

--     Citizen.Wait(100)

--     if Config.gearhud == 1 then
--         Citizen.CreateThread(function()
--             while true do
--                 Citizen.Wait(0)
--                 if manualon == true and vehicle ~= nil then
        
--                     SetTextFont(0)
--                     SetTextProportional(1)
--                     SetTextScale(0.0, 0.3)
--                     SetTextColour(128, 128, 128, 255)
--                     SetTextDropshadow(0, 0, 0, 0, 255)
--                     SetTextEdge(1, 0, 0, 0, 255)
--                     SetTextDropShadow()
--                     SetTextOutline()
--                     SetTextEntry("STRING")
                
--                     AddTextComponentString("~r~Gear: ~w~"..getinfo(selectedgear))
                
--                     DrawText(0.015, 0.78)
--                 else
--                     Citizen.Wait(100)
--                 end
--             end
--         end)
--     elseif Config.gearhud == 2 then  
--         Citizen.CreateThread(function()
--             while true do
--                 Citizen.Wait(0)
--                 if manualon == true and vehicle ~= nil then
        
--                     SetTextFont(0)
--                     SetTextProportional(1)
--                     SetTextScale(0.0, 0.3)
--                     SetTextColour(128, 128, 128, 255)
--                     SetTextDropshadow(0, 0, 0, 0, 255)
--                     SetTextEdge(1, 0, 0, 0, 255)
--                     SetTextDropShadow()
--                     SetTextOutline()
--                     SetTextEntry("STRING")

--                     if clutch == true then
--                         AddTextComponentString("~b~Gear: ~w~"..getinfo(selectedgear).."("..getinfo(targetgear)..")".." ~b~MPH: ~w~"..round((GetEntitySpeed(vehicle)*2.236936),0).." ~b~RPM: ~w~"..round(GetVehicleCurrentRpm(vehicle),2))
--                     else
--                         AddTextComponentString("~b~Gear: ~w~"..getinfo(selectedgear).." ~b~MPH: ~w~"..round((GetEntitySpeed(vehicle)*2.236936),0).." ~b~RPM: ~w~"..round(GetVehicleCurrentRpm(vehicle),2))
--                     end
                    
--                     DrawText(0.015, 0.79)

                
--                     -- if isStalling == true then
--                     --     SetTextFont(0)
--                     --     SetTextProportional(1)
--                     --     SetTextScale(0.0, 0.3)
--                     --     SetTextColour(128, 128, 128, 255)
--                     --     SetTextDropshadow(0, 0, 0, 0, 255)
--                     --     SetTextEdge(1, 0, 0, 0, 255)
--                     --     SetTextDropShadow()
--                     --     SetTextOutline()
--                     --     SetTextEntry("STRING")
--                     --     AddTextComponentString("~r~STALL")
--                     --     DrawText(0.015, 0.4)
--                     -- else
--                     --     Citizen.Wait(0)
--                     -- end

--                 else
--                     Citizen.Wait(100)
--                 end
--             end
--         end)
--     end

-- end)

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(0)
--         --if manualon == true and vehicle ~= nil then
    
        

--         SetTextFont(0)
--         SetTextProportional(1)
--         SetTextScale(0.0, 0.2)
--         SetTextColour(128, 128, 128, 255)
--         SetTextDropshadow(0, 0, 0, 0, 255)
--         SetTextEdge(1, 0, 0, 0, 255)
--         SetTextDropShadow()
--         SetTextOutline()
--         SetTextEntry("STRING")
--         if manualon == true then
--             if realistic == false then
--                 AddTextComponentString("~r~HRSGears: ~g~On ~r~Mode: ~g~Arcade")
--             else
--                 AddTextComponentString("~r~HRSGears: ~g~On ~r~Mode: ~g~Realistic")
--             end
--         else
--             AddTextComponentString("~r~HRSGears: ~w~Off")
--         end
        
--         DrawText(0.005, 0.005)

--     end
-- end)
