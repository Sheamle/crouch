-- ############################################
-- --------------------------------------------
-- Accroupi discret et ramper
-- --------------------------------------------
-- ############################################

-- --------------------------------------------
-- Variables
-- --------------------------------------------

-- ## Enumérations

-- Différentes positions
local Stances = {
    Idle = 1,
    Stealth = 2,
    Crouch = 3,
    Prone = 4,
}

-- Contrôles
local Control = {
    ChangeState = 36,  -- CTRL
    FrontToBack = 21,   -- SHIFT
    Cancel = 22,        -- SPACE
    MoveFront = 32,
    MoveBack = 33,
    MoveLeft = 34,
    MoveRight = 35,
}

-- ## Informations "cache"

local playerPed = nil
local Player = {
    Cuffed = false,
    Swimming = false,
}

local playerStance = Stances.Idle
local proneFront = true
local lastProneChange = 0

-- --------------------------------------------
-- Fonctions
-- --------------------------------------------

-- ## Mouvements généraux

local function AbleToChangeState()
    return true
end

local function CancelState()
    ClearPedTasks(playerPed)
    ForcePedMotionState(playerPed, 247561816, 1, 1, 0)
    ResetPedMovementClipset(playerPed, 0.5)
    ResetPedStrafeClipset(playerPed)
    ClearPedTasksImmediately(playerPed)
end

local function LaunchState()
    if playerStance == Stances.Stealth then
        SetPedStealthMovement(playerPed, true, 0)
    elseif playerStance == Stances.Crouch then
        SetPedMovementClipset(playerPed, "move_m@fire", 0.5)
        SetPedMovementClipset(playerPed, "move_ped_crouched", 0.5)
        SetPedStrafeClipset(playerPed, "move_ped_crouched_strafing")
    end
end

local function ChangeState()

    if playerStance == Stances.Idle and not GetPedStealthMovement(playerPed) then
        playerStance = Stances.Stealth
    end

    if playerStance == Stances.Idle then

        playerStance = Stances.Stealth
        LaunchState()

    elseif playerStance == Stances.Stealth then

        playerStance = Stances.Crouch
        LaunchState()

    elseif playerStance == Stances.Crouch then

        playerStance = Stances.Idle
        CancelState()

    elseif playerStance == Stances.Prone then

        playerStance = Stances.Idle
        CancelState()

    end
end

-- ## Mouvement "prone"

local function LaunchProne()

    if IsPedRunning(playerPed) or IsPedSprinting(playerPed) then
        proneFront = true
        TaskPlayAnim(playerPed, "move_jump", "dive_start_run", 8.0, -8.0, -1, 2, 0)
        Wait(1100)
    end

    local anim = "onfront_fwd"

    if not proneFront then
        anim = "onback_fwd" 
    end

    local position = GetEntityCoords(playerPed)
    local rotation = GetEntityRotation(playerPed)

    TaskPlayAnimAdvanced(playerPed, "move_crawl", anim, position.x, position.y, position.z, rotation.x, rotation.y, rotation.z, 8.0, -8.0, -1, 2, 1000.0, 2, 0)
end

local function HandleProneMovement(front)

    local anim = "onfront_"

    if not proneFront then
        anim = "onback_" 
    end

    if front then
        anim = anim .. 'fwd'
    else
        anim = anim .. 'bwd'
    end

    -- StopAnimTask(playerPed, "move_crawl", anim, 1.0)
    TaskPlayAnim(playerPed, "move_crawl", anim, 8.0, -8.0, -1, 2, 0)
    Wait((GetAnimDuration("move_crawl", anim) - 0.1) * 1000)
end

local function HandleProneRotation(left)

    local dh = -0.75

    if left then
        dh = 0.75
    end

    SetEntityHeading(playerPed, GetEntityHeading(playerPed) + dh)

end

-- --------------------------------------------
-- Fonctions
-- --------------------------------------------

Citizen.CreateThread(function()

    RequestAnimDict("move_crawl")
    RequestAnimDict("move_jump")
    RequestClipSet("move_ped_crouched")

    while true do
        Wait(1000)

        playerPed = PlayerPedId()

        Player.Cuffed = IsPedCuffed(playerPed)
        Player.Swimming = IsPedSwimming(playerPed)

    end

end)

-- --------------------------------------------
-- Fonctions
-- --------------------------------------------

Citizen.CreateThread(function()

    while true do
        Wait(0)

        -- DisableControlAction(1, Control.ChangeState, true)

        if IsControlJustPressed(1, Control.ChangeState) then
            if AbleToChangeState() then
                ChangeState()
            end
        end

        if IsControlPressed(1, Control.ChangeState) then

            local Timer = 0
            
            while IsControlPressed(1, Control.ChangeState) do
                Wait(100)
                Timer = Timer + 100
                if Timer >= 500 and AbleToChangeState() then
                    playerStance = Stances.Prone
                    LaunchProne()
                end
            end

        end

        if playerStance ~= Stances.Idle then

            DisableControlAction(1, Control.Cancel, true)

            if IsDisabledControlJustPressed(1, Control.Cancel) then
                playerStance = Stances.Idle
                CancelState()
            end
        end

        if playerStance == Stances.Prone then

            if IsControlJustPressed(1, Control.FrontToBack) then
                if GetGameTimer() - lastProneChange > 2000 then
                    proneFront = not proneFront
                    lastProneChange = GetGameTimer()
                    SetEntityHeading(playerPed, (GetEntityHeading(playerPed) + 180) % 360)
                    LaunchProne()
                end
            end

            if IsControlPressed(1, Control.MoveFront) then
                HandleProneMovement(true)
            elseif IsControlPressed(1, Control.MoveBack) then
                HandleProneMovement(false)
            end

            if IsControlPressed(1, Control.MoveLeft) then
                HandleProneRotation(true)
            elseif IsControlPressed(1, Control.MoveRight) then
                HandleProneRotation(false)
            end

        end

    end

end)