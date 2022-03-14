-- Variables
QBCore = exports["qb-core"]:GetCoreObject()
config = json.decode(LoadResourceFile(GetCurrentResourceName(), "configs/client.json"))


-- Ped Data
local myCharacters = {}

local spawnPoints = config.spawnPositions or {}
-- local spawnPoints = {
--   -- Left Side
--   {position = vector3(-1246.84, -3395.7, 13.94), heading = 55.37},
--   {position = vector3(-1248.05, -3397.27, 13.94), heading = 55.37},
--   {position = vector3(-1249.21, -3398.97, 13.94), heading = 55.37},
--   {position = vector3(-1250.41, -3400.84, 13.94), heading = 55.37},
--   {position = vector3(-1251.8, -3402.8, 13.94), heading = 55.37},

--   -- Middle
--   {position = vector3(-1277.2, -3397.63, 13.94), heading = 328.22},
--   {position = vector3(-1278.93, -3396.61, 13.94), heading = 328.22},
--   {position = vector3(-1280.66, -3395.59, 13.94), heading = 328.22},
--   {position = vector3(-1282.39, -3394.57, 13.94), heading = 328.22},
--   {position = vector3(-1284.12, -3393.55, 13.94), heading = 328.22},

--   -- Right Side
--   {position = vector3(-1299.9, -3373.98, 13.94), heading = 245.87},
--   {position = vector3(-1299.11, -3372.43, 13.94), heading = 245.87},
--   {position = vector3(-1297.93, -3370.37, 13.94), heading = 245.87},
--   {position = vector3(-1296.88, -3367.89, 13.94), heading = 245.87},
--   {position = vector3(-1295.63, -3365.35, 13.94), heading = 245.87},
-- }

-- Camera Data
skyCamera = nil
createdCamera = false
pedCamera = nil
local cameraIndex = -1
local cameraPositions = config.cameraPositions or {}
-- local cameraPositions = {
--   {location = vector3(-1254.11, -3396.04, 13.94), rotation = vector3(0.0, 0.0, 234.0)},
--   {location = vector3(-1277.99, -3390.58, 13.94), rotation = vector3(0.0, 0.0, 150.0)},
--   {location = vector3(-1292.39, -3372.79, 13.94), rotation = vector3(0.0, 0.0, 60.0)}
-- }

createdPeds = {}

-- UI Interaction
markerIndex = -1
charMarker = nil

-- Tick Handles
characterTick = nil

-- Events
RegisterNetEvent("lx_characters-client:characters:setLoadingState")
RegisterNetEvent("lx_characters-client:characters:setLoadingStat", setLoading)

RegisterNetEvent("lx_characters-client:characters:setupStart")
AddEventHandler("lx_characters-client:characters:setupStart", function()
  if #createdPeds > 0 then
    print("delete peds here", json.encode(createdPeds)) 
    Utils.DeletePeds()
    print("selection peds", json.encode(createdPeds))
  end
  
  setLoading("Processing")
  local ped = PlayerPedId()
  DisplayRadar(false)
  SetEntityVisible(ped, false, false)
  FreezeEntityPosition(ped, true)
  SetTimecycleModifier('hud_def_blur')
  skyCamera = Camera.New()
  skyCamera:SetPosition(vector3(-1355.93, -1487.78, 520.75))
  skyCamera:SetRotation(vector3(300.00, 0.00, 0.00))
  skyCamera:SetFOV(100.00)
  skyCamera:SetActive(true)
  skyCamera:Render(true, true, 1)
  Wait(1500)
  setLoading("Getting Characters")

  QBCore.Functions.TriggerCallback("lx_characters-server:characters:getCharacters", function(characters)
    Wait(1500)
    setLoading("Processing Characters")
    myCharacters = characters
    -- print("my characters", #myCharacters, json.encode(myCharacters))
    if not HasModelLoaded(GetHashKey("mp_m_freemode_01")) then
      RequestModel(GetHashKey("mp_m_freemode_01"))
      while not HasModelLoaded(GetHashKey("mp_m_freemode_01")) do
        Wait(0)
      end
    end

    setLoading("Spawning Characters")
    Wait(1000)
    for i = 1, #spawnPoints do
      local charExists = myCharacters[i]
      local randomInt = math.random(1, 10)
      local characterPed = nil
      if charExists then
        local model = tonumber(myCharacters[i].skin.model)
        local clothing = myCharacters[i].skin.clothing
        
        if not HasModelLoaded(model) then
          RequestModel(model)
          while not HasModelLoaded(model) do
              Citizen.Wait(0)
          end
        end

        characterPed = CreatePed(2, model, spawnPoints[i].position.x, spawnPoints[i].position.y, spawnPoints[i].position.z, spawnPoints[i].heading, false, true)
        DecorSetInt(characterPed, "CHAR_KEY", #createdPeds + 1)
        FreezeEntityPosition(characterPed, false)
        SetEntityInvincible(characterPed, true)
        PlaceObjectOnGroundProperly(characterPed)
        SetBlockingOfNonTemporaryEvents(characterPed, true)
        TriggerEvent("qb-clothing:client:loadPlayerClothing", clothing, characterPed)
      else
        characterPed = CreatePed(4, GetHashKey("mp_m_freemode_01"), spawnPoints[i].position.x, spawnPoints[i].position.y, spawnPoints[i].position.z, spawnPoints[i].heading, false, false)
        SetPedDefaultComponentVariation(characterPed)
      end

      createdPeds[i] = characterPed
    end

    if not createdCamera then
      if not pedCamera then
        cameraIndex = 1
        pedCamera = Camera.New()
        ped = PlayerPedId() -- Redefine our ped
        SetFocusPosAndVel(-1269.89, -3374.54, 13.94) -- Set lod focusing to the character selector position (prevents the issue of the world not loading on cams, when that position is out of your render distance)=
        pedCamera:SetPosition(cameraPositions[cameraIndex].location)
        pedCamera:SetRotation(vector3(cameraPositions[cameraIndex].rotation.x, cameraPositions[cameraIndex].rotation.y, cameraPositions[cameraIndex].rotation.z))
        skyCamera:InterpTo(pedCamera.Handle, 3000, true, true)
      
        Wait(2800)
        
        ClearTimecycleModifier()
        pedCamera:SetActive(true)
        pedCamera:Render(true, true, 1000)
        markerIndex = 1
        charMarker = GetEntityCoords(createdPeds[markerIndex], false)
        SetNuiFocus(true, true)
        SendNUIMessage({
          event = "sendCharacters",
          data = {
            characters = myCharacters
          }
        })
        clearLoading()
        characterTick = Thread(ProcessCharacters, true, 1000)
      end
    
      createdCamera = true
    end
  end)
end)

AddEventHandler("onResourceStop", function(resourceName)
  if GetCurrentResourceName() == resourceName then
    if IsNuiFocused() then
      SetNuiFocus(false, false)
    end

    if pedCamera ~= nil then
      pedCamera:Delete()
    end

    if #createdPeds > 0 then
      for k, v in pairs(createdPeds) do
        DeleteEntity(v)
        
        if next(createdPeds, k) == nil then
          createdPeds = {}
        end
      end
    end
  end
end)

AddEventHandler("onResourceStart", function(resourceName)
  if GetCurrentResourceName() == resourceName then
    DecorRegister("CHAR_KEY", 2)
    if NetworkIsSessionStarted() then
      -- print("RESOURCE STARTED WHILST IN GAME!")
      TriggerEvent("lx_characters-client:characters:setupStart")
      TriggerEvent("lx_characters-client:spawner:setupMap")
		end
  end
end)

-- NUI Callbacks
RegisterNUICallback("cycle_character", function(data, cb)
  -- print("cycle data", json.encode(data))
  -- print("before", markerIndex, cameraIndex)
  if data.direction == "right" then
    if markerIndex + 1 > #createdPeds then
      markerIndex = 1
    else
      markerIndex = markerIndex + 1
    end

    if markerIndex == 1 or markerIndex == 6 or markerIndex == 11 then
      -- print("cam ting", cameraIndex, cameraIndex + 1, #cameraPositions)
      if cameraIndex + 1 > #cameraPositions then
        cameraIndex = 1
      else
        cameraIndex = cameraIndex + 1
      end

      changeCamPos(cameraPositions[cameraIndex])
    end
  elseif data.direction == "left" then
    if markerIndex - 1 <= 0 then
      markerIndex = #createdPeds
    else
      markerIndex = markerIndex - 1
    end

    if markerIndex == 5 or markerIndex == 10 or markerIndex == 15 then
      if cameraIndex - 1 <= 0 then
        cameraIndex = #cameraPositions
      else
        cameraIndex = cameraIndex - 1
      end

      changeCamPos(cameraPositions[cameraIndex])
    end
  end

  -- print("after", markerIndex, cameraIndex)

  charMarker = GetEntityCoords(createdPeds[markerIndex], false)
  cb("ok")
end)

RegisterNUICallback("createCharacter", function(data, cb)
  -- DoScreenFadeOut(500)
  QBCore.Functions.TriggerCallback("lx_characters-server:characters:createCharacter", function(finished)
    if finished then
      if IsNuiFocused() then
        SetNuiFocus(false, false)
      end
    end
    
    cb(finished)
  end, data)
end)

RegisterNUICallback("play_character", function(data, cb)
  TriggerServerEvent("lx_characters-server:characters:playCharacter", data)
  cb("ok")
end)

RegisterNUICallback("edit_character", function(data, cb)
  QBCore.Functions.TriggerCallback("lx_characters-server:characters:editCharacter", function(state)
    if state == "UPDATED" then
      QBCore.Functions.Notify("You have edited your character", "success", 3000)
    end

    cb(state)
  end, data)
end)

RegisterNUICallback("delete_character", function(data, cb)
  -- print("delete char nui", json.encode(data))
  
  QBCore.Functions.TriggerCallback("lx_characters-server:characters:deleteCharacter", function(callbackState)
    if callbackState == "DELETED" then
      QBCore.Functions.TriggerCallback("lx_characters-server:characters:getCharacters", function(characters)
        myCharacters = characters
        if not HasModelLoaded(GetHashKey("mp_m_freemode_01")) then
          RequestModel(GetHashKey("mp_m_freemode_01"))
          while not HasModelLoaded(GetHashKey("mp_m_freemode_01")) do
            Wait(0)
          end
        end

        setLoading("Refreshing Characters")
        
        if #createdPeds > 0 then
          for k, v in pairs(createdPeds) do
            DeleteEntity(v)
            
            if next(createdPeds, k) == nil then
              createdPeds = {}
            end
          end
        end

        cb(callbackState)
        
        for i = 1, #spawnPoints do
          local charExists = myCharacters[i]
          local randomInt = math.random(1, 10)
          local characterPed = nil
          if charExists then
            local model = tonumber(myCharacters[i].skin.model)
            local clothing = myCharacters[i].skin.clothing
                
            if not HasModelLoaded(model) then
              RequestModel(model)
              while not HasModelLoaded(model) do
                Citizen.Wait(0)
              end
            end
        
            characterPed = CreatePed(2, model, spawnPoints[i].position.x, spawnPoints[i].position.y, spawnPoints[i].position.z, spawnPoints[i].heading, false, true)
            DecorSetInt(characterPed, "CHAR_KEY", #createdPeds + 1)
            FreezeEntityPosition(characterPed, false)
            SetEntityInvincible(characterPed, true)
            PlaceObjectOnGroundProperly(characterPed)
            SetBlockingOfNonTemporaryEvents(characterPed, true)
            TriggerEvent("qb-clothing:client:loadPlayerClothing", clothing, characterPed)
          else
            characterPed = CreatePed(4, GetHashKey("mp_m_freemode_01"), spawnPoints[i].position.x, spawnPoints[i].position.y, spawnPoints[i].position.z, spawnPoints[i].heading, false, false)
            SetPedDefaultComponentVariation(characterPed)
          end
        
          createdPeds[i] = characterPed
        end

        -- Clear marker as otherwise our peds in game & on the UI doesn't match up
        markerIndex = 1
        charMarker = GetEntityCoords(createdPeds[markerIndex], false)
        
        clearLoading()
        Wait(0)
        SendNUIMessage({
          event = "sendCharacters",
          data = {
            characters = myCharacters
          }
        })
      end)
    else
      print("error deleting character")
    end
  end, data)
end)

RegisterNUICallback("disconnect", function(data, cb)
  TriggerServerEvent("lx_characters-server:characters:disconnect")
  cb("ok")
end)

RegisterCommand("close", function(source, args, raw)
  local ped = PlayerPedId()
  if pedCamera then pedCamera:Delete() end
  if skyCamera then skyCamera:Delete() end
  ClearTimecycleModifier()
  FreezeEntityPosition(ped, false)
  SetEntityVisible(ped, true, false)
  SetFocusEntity(ped) -- Restore LOD's measure point, back to your ped
  if IsNuiFocused() then
    SetNuiFocus(false, false)
  end
end)

-- Tick Tasks
ProcessCharacters = function()
  if charMarker then

    if characterTick.delay > 0 then
      characterTick:ChangeDelay(0)
    end

    local width, height = GetActiveScreenResolution(0, 0)
    
    if height >= 1000 then
      DrawMarker(0, charMarker.x, charMarker.y, charMarker.z + 1.3, vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0), vector3(0.3, 0.3, 0.3), 212, 39, 39, 150, true, true)
    else
      DrawMarker(1, charMarker.x, charMarker.y, charMarker.z - 0.95, vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0), vector3(1.2, 1.2, 1.2), 212, 39, 39, 150, false, true)
    end
  end
end

-- Functions
setLoading = function(newState)
  SendNUIMessage({
    event = "setLoadingState",
    data = {
      state = newState,
      setter = true
    }
  })
end

clearLoading = function()
  SendNUIMessage({
    event = "setLoadingState",
    data = {
      setter = false
    }
  })
end

changeCamPos = function(camData)
  local camRot = pedCamera:GetRotation()
  pedCamera:SetPosition(camData.location)
  pedCamera:SetRotation(vector3(camData.rotation.x, camData.rotation.y, camData.rotation.z))
end