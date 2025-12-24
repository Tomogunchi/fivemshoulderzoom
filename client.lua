local Z = {
    cam = nil,
    active = false,
    block = false,
    fov = 20.0
}

local function camLerp(a, b, t) return a + (b - a) * t end
local function camLerpAng(a, b, t)
    local d = ((b - a + 180) % 360) - 180
    return a + d * t
end

local function setBlock(val) Z.block = val end

local function makeCam()
    local rot, mode = GetGameplayCamRot(2), GetFollowPedCamViewMode()
    local ped = PlayerPedId()
    local pos = mode == 4 and GetEntityCoords(ped) + (GetEntityForwardVector(ped) * 1.0) or GetGameplayCamCoord()
    Z.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, mode == 4 and pos.z + 0.5 or pos.z, rot.x, rot.y, rot.z, Z.fov, true, 2)
    RenderScriptCams(true, true, 200, true, true)
end

local function killCam()
    local mode = GetFollowPedCamViewMode()
    SetCamActive(Z.cam, false)
    RenderScriptCams(false, true, mode == 4 and 0 or 200, true, true)
    DestroyCam(Z.cam, true)
    Z.active = false
    Z.cam = nil
end

local function camLoop()
    local prevPos, prevRot = GetGameplayCamCoord(), GetGameplayCamRot(2)
    CreateThread(function()
        while Z.active do
            local rot, mode = GetGameplayCamRot(2), GetFollowPedCamViewMode()
            local ped = PlayerPedId()
            local pos = mode == 4 and GetEntityCoords(ped) + (GetEntityForwardVector(ped) * 1.0) or GetGameplayCamCoord()
            local smoothPos = vector3(
                camLerp(prevPos.x, pos.x, 0.2),
                camLerp(prevPos.y, pos.y, 0.2),
                camLerp(prevPos.z, mode == 4 and pos.z + 0.5 or pos.z, 0.2)
            )
            local smoothRot = vector3(
                camLerpAng(prevRot.x, rot.x, 0.2),
                camLerpAng(prevRot.y, rot.y, 0.2),
                camLerpAng(prevRot.z, rot.z, 0.2)
            )
            SetCamCoord(Z.cam, smoothPos.x, smoothPos.y, smoothPos.z)
            SetCamRot(Z.cam, smoothRot.x, smoothRot.y, smoothRot.z, 2)
            prevPos, prevRot = smoothPos, smoothRot
            if IsPlayerFreeAiming(PlayerId()) then killCam() end
            Wait(0)
        end
    end)
end

local function startZoom()
    Z.active = true
    if not Z.cam then makeCam() end
    SetCamFov(Z.cam, Z.fov)
    SetCamActive(Z.cam, true)
    RenderScriptCams(true, true, 200, true, true)
    camLoop()
end

RegisterCommand('togglezoom', function()
    if not Z.active and not Z.block and not IsPlayerFreeAiming(PlayerId()) then
        startZoom()
    elseif Z.active then
        killCam()
    end
end, false)

RegisterKeyMapping('togglezoom', 'Toggle Perspective Zoom', 'keyboard', Config.DefaultZoomKey)