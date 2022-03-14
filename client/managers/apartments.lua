-- Variables
apartmentCam = nil
oldCam = nil
apartments = exports["qb-apartments"]:getApartments()

-- Events
RegisterNetEvent("qb-character-client:apartments:displayApartments")
AddEventHandler("qb-character-client:apartments:displayApartments", function()
  SetEntityVisible(PlayerPedId(), false)
  DoScreenFadeOut(0)
  setLoading("Updating database & setting up apartments")
  Citizen.Wait(1000)
  QBCore.Functions.GetPlayerData(function(PlayerData)
    apartmentCam = Camera.New()
    apartmentCam:SetPosition(vector3(PlayerData.position.x, PlayerData.position.y, PlayerData.position.z + 1500))
    apartmentCam:SetRotation(vector3(-85.00, 0.00, 0.00))
    apartmentCam:SetFOV(100.00)
    
    pedCamera:InterpTo(apartmentCam.Handle, 500, true, true)
    Wait(500)

    apartmentCam:SetActive(true)
    apartmentCam:Render(true, false, 1)
  end)

  clearLoading()
  DoScreenFadeIn(250)
  
  SendNUIMessage({
    event = "display_apartments",
    data = {
      displayApts = true,
      apartments = apartments
    }
  })
  SetNuiFocus(true, true)
end)

-- NUI Callbacks
RegisterNUICallback("toggleApartment", function(data, cb)
  -- print("lua apartment data", json.encode(data))
  oldCam = apartmentCam
  -- print("apartments", json.encode(apartments))
  local newPos = apartments[data.name].coords.enter
  apartmentCam = Camera.New()
  apartmentCam:SetPosition(vector3(newPos.x, newPos.y, newPos.z + 150.0))
  apartmentCam:SetRotation(vector3(300.00, 0.00, 0.00))
  apartmentCam:SetFOV(110.00)
  apartmentCam:PointAtCoords(vector3(newPos.x, newPos.y, newPos.z))
  SetFocusPosAndVel(newPos.x, newPos.y, newPos.z) -- Set lod focusing to the character selector position (prevents the issue of the world not loading on cams, when that p
  oldCam:InterpTo(apartmentCam.Handle, 1000, true, true)
  cb("ok")
end)

RegisterNUICallback("setApartment", function(data, cb)
  -- print("Set Apartment", json.encode(data))
  local ped = PlayerPedId()
  
  if IsNuiFocused() then
    SetNuiFocus(false, false)
    cb(true)
  end

  setLoading("Creating Apartment")
  DoScreenFadeOut(500)
  Wait(5000)
  SetFocusEntity(ped) -- Restore LOD's measure point, back to your ped
  TriggerServerEvent("apartments:server:CreateApartment", data)
  TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
  TriggerEvent('QBCore:Client:OnPlayerLoaded')
  FreezeEntityPosition(ped, false)
  RenderScriptCams(false, true, 500, true, true)
  clearLoading()
  Utils.DeleteCameras()
  SetEntityVisible(ped, true)
  cb("ok")
end)