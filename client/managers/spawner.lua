RegisterNetEvent("lx_characters-client:spawner:displayMap")
AddEventHandler("lx_characters-client:spawner:displayMap", function(bool)
  if bool then
    setLoading("Loading Spawner Data")
    DoScreenFadeOut(500)

    local player = QBCore.Functions.GetPlayerData()
    QBCore.Functions.TriggerCallback('apartments:GetOwnedApartment', function(ownedApartment)
      -- print("apartments", json.encode(ownedApartment))
      if ownedApartment then
        local apartments = exports["qb-apartments"]:getApartments()
        
        SendNUIMessage({
          event = "setup_map",
          data = {
            job = player.job,
            position = player.position,
            apartment = {
              name = ownedApartment.name,
              label = ownedApartment.label,
              information = apartments[ownedApartment.type].information,
              position = vector4(apartments[ownedApartment.type].coords.enter.x, apartments[ownedApartment.type].coords.enter.y, apartments[ownedApartment.type].coords.enter.z, apartments[ownedApartment.type].coords.enter.w),
              apartmentType = ownedApartment.type,
              type = "apartment"
            }
          }
        })
      else
        SendNUIMessage({
          event = "setup_map",
          data = {
            job = player.job,
            position = player.position
          }
        })
      end
    end)

    Wait(2000)
    clearLoading()
  end
  
  SendNUIMessage({
    event = "show_map",
    data = {
      show = bool
    }
  })
  Wait(500)
  DoScreenFadeIn(250)
end)

-- NUI Callbacks
RegisterNUICallback("spawn_player", function(data, cb)
  print("spawn player at", json.encode(data))
  DoScreenFadeOut(0) -- Fade out instantly, so we don't see ourselves before we're put into our apartment.
  local ped = PlayerPedId()
  local PlayerData = QBCore.Functions.GetPlayerData()
  local insideMeta = PlayerData.metadata["inside"]
  Utils.DeleteCameras()

  print("spawn_player", json.encode(data))

  if data.type == "last_location" then
    print("is last location")
    if IsNuiFocused() then
      SetNuiFocus(false, false)
    end
    cb("SPAWNING")

    setLoading("Getting Last Location")
    Wait(2000)
    QBCore.Functions.GetPlayerData(function(PlayerData)
      SetEntityCoords(PlayerPedId(), PlayerData.position.x, PlayerData.position.y, PlayerData.position.z)
      SetEntityHeading(PlayerPedId(), PlayerData.position.a)

      RequestCollisionAtCoord(PlayerData.position.x, PlayerData.position.y, PlayerData.position.z)
      while not HasCollisionLoadedAroundEntity(PlayerPedId()) do
        RequestCollisionAtCoord(PlayerData.position.x, PlayerData.position.y, PlayerData.position.z)
        Citizen.Wait(0)
      end
      
      SetEntityCoords(PlayerPedId(), PlayerData.position.x, PlayerData.position.y, PlayerData.position.z)
      SetEntityHeading(PlayerPedId(), PlayerData.position.a)
    end)

    if insideMeta.apartment.apartmentType ~= nil or insideMeta.apartment.apartmentId ~= nil then
      local apartmentType = insideMeta.apartment.apartmentType
      local apartmentId = insideMeta.apartment.apartmentId
      TriggerEvent('qb-apartments:client:LastLocationHouse', apartmentType, apartmentId)
    end
  elseif data.type == "apartment" then
    print("is apt")
    if IsNuiFocused() then
      SetNuiFocus(false, false)
    end
    cb("SPAWNING")

    setLoading("Getting Apartment Data")
    Wait(2000)
    TriggerEvent("qb-interior:client:SetNewState", false)
    TriggerEvent("apartments:client:SpawnInApartment", data.location.name, data.location.apartmentType, false)
    TriggerEvent("apartments:client:SetHomeBlip", data.location.apartmentType)
  elseif data.type == "location" then
    local position = data.location.spawn
    print("normal position 1", json.encode(position))
    position = vector4(position[1], position[2], position[3], position[4])
    print("normal position 2", json.encode(position))
    print("is last location")
    if IsNuiFocused() then
      SetNuiFocus(false, false)
    end
    cb("SPAWNING")

    setLoading("Getting Location Data")
    Wait(2000)

    SetEntityCoords(PlayerPedId(), position.x, position.y, position.z)
    SetEntityHeading(PlayerPedId(), position.w)

    RequestCollisionAtCoord(position.x, position.y, position.z)
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) do
      RequestCollisionAtCoord(position.x, position.y, position.z)
      Citizen.Wait(0)
    end
    
    SetEntityCoords(PlayerPedId(), position.x, position.y, position.z)
    SetEntityHeading(PlayerPedId(), position.w)

    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
  end

  FreezeEntityPosition(ped, false)
  SetEntityVisible(ped, true)
  Wait(500)
  FreezeEntityPosition(ped, false)
  SetEntityVisible(ped, true)
  Wait(1000)
  TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
  TriggerEvent('QBCore:Client:OnPlayerLoaded')
  clearLoading()
  DoScreenFadeIn(500)
  SetFocusEntity(ped) -- Restore LOD's measure point, back to your ped
end)