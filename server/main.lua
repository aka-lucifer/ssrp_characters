-- Variables
QBCore = exports["qb-core"]:GetCoreObject()

-- Events
AddEventHandler("playerJoining", function()
  local src = source
  TriggerClientEvent("lx_characters-client:characters:setupStart", src)
end)

RegisterNetEvent("lx_characters-server:characters:playCharacter")
AddEventHandler("lx_characters-server:characters:playCharacter", function(charData)
  local src = source
  if QBCore.Player.Login(src, charData.cid) then
    print('^2[qb-core]^7 '..GetPlayerName(src)..' (Citizen ID: ' .. charData.cid .. ') has succesfully loaded!')
    QBCore.Commands.Refresh(src)
    loadHouseData()
    print("display map spawner UI!")
    TriggerClientEvent("lx_characters-client:spawner:displayMap", src, true)
    -- setup map spawner data here
    TriggerEvent("qb-log:server:CreateLog", "joinleave", "Loaded", "green", "**".. GetPlayerName(src) .. "** (" .. charData.cid .. " | "..src..") loaded..")
  end
end)

RegisterNetEvent("lx_characters-server:characters:logOut")
AddEventHandler("lx_characters-server:characters:logOut", function()
  local src = source
  QBCore.Player.Logout(src)
  TriggerClientEvent("lx_characters-client:characters:setupStart", src)
end)

RegisterNetEvent("lx_characters-server:characters:disconnect")
AddEventHandler("lx_characters-server:characters:disconnect", function()
  local src = source
  DropPlayer(src, "[Sunstone RP]: Thank you for playing, we hope to see you again soon!")
end)

-- Commands
QBCore.Commands.Add("logout", "Logout of Character (Admin Only)", {}, false, function(source)
  local src = source
  QBCore.Player.Logout(src)
  TriggerClientEvent("lx_characters-client:characters:setupStart", src)
end, "admin")

-- Functions
local function GiveStarterItems(source)
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  print("give (" .. src .. ") starter items!")

  for k, v in pairs(QBCore.Shared.StarterItems) do
      local info = {}
      if v.item == "id_card" then
          info.citizenid = Player.PlayerData.citizenid
          info.firstname = Player.PlayerData.charinfo.firstname
          info.lastname = Player.PlayerData.charinfo.lastname
          info.birthdate = Player.PlayerData.charinfo.birthdate
          info.gender = Player.PlayerData.charinfo.gender
          info.nationality = Player.PlayerData.charinfo.nationality
      elseif v.item == "driver_license" then
          info.firstname = Player.PlayerData.charinfo.firstname
          info.lastname = Player.PlayerData.charinfo.lastname
          info.birthdate = Player.PlayerData.charinfo.birthdate
          info.type = "Class C Driver License"
      end
      print("give (" .. src .. ") x" .. v.amount .. " of " .. v.item .. " | Item Info: " .. json.encode(info) .. "!")
      Player.Functions.AddItem(v.item, v.amount, false, info)
  end
end

function loadHouseData()
  local HouseGarages = {}
  local Houses = {}
  local result = MySQL.query.await('SELECT * from houselocations', {})
  if result[1] ~= nil then
      for k, v in pairs(result) do
          local owned = false
          if tonumber(v.owned) == 1 then
              owned = true
          end
          local garage = v.garage ~= nil and json.decode(v.garage) or {}
          Houses[v.name] = {
              coords = json.decode(v.coords),
              owned = v.owned,
              price = v.price,
              locked = true,
              adress = v.label, 
              tier = v.tier,
              garage = garage,
              decorations = {},
          }
          HouseGarages[v.name] = {
              label = v.label,
              takeVehicle = garage,
          }
      end
  end
  TriggerClientEvent("qb-garages:client:houseGarageConfig", -1, HouseGarages)
  TriggerClientEvent("qb-houses:client:setHouseConfig", -1, Houses)
end

-- Callbacks
QBCore.Functions.CreateCallback("lx_characters-server:characters:getCharacters", function(source, cb)
  local license = QBCore.Functions.GetIdentifier(source, 'license')
  local characters = {}

  MySQL.Async.fetchAll('SELECT * from players WHERE license = ?', {license}, function(result)
    local finished = false

    for k, v in pairs(result) do
      local charInfo = json.decode(v.charinfo)
      local jobInfo = json.decode(v.job)
      local moneyInfo = json.decode(v.money)
      local tableInfo = {}

      -- Char Data
      tableInfo.cid = v.citizenid
      tableInfo.firstname = charInfo.firstname
      tableInfo.lastname = charInfo.lastname
      tableInfo.nationality = charInfo.nationality
      tableInfo.dob = charInfo.birthdate
      tableInfo.gender = charInfo.gender
      tableInfo.phone = charInfo.phone
      tableInfo.account = charInfo.account

      -- Job Data
      tableInfo.jobName = jobInfo.label
      tableInfo.jobRank = jobInfo.grade.name

      -- Money Data
      tableInfo.cash = moneyInfo.cash
      tableInfo.bank = moneyInfo.bank
      table.insert(characters, tableInfo)
    end

    if #characters > 0 then
      for k, v in pairs(characters) do
        MySQL.Async.fetchAll('SELECT * FROM playerskins WHERE citizenid = ? AND active = 1', {v.cid}, function(result2)
          if result2[1] then
            v.skin = {
              model = result2[1].model,
              clothing = json.decode(result2[1].skin)
            }
          end

          if next(characters, k) == nil then
            finished = true
          end
        end)
      end
    else
      finished = true
    end

    while not finished do
      Wait(0)
    end

    cb(characters)
  end)
end)

QBCore.Functions.CreateCallback("lx_characters-server:characters:createCharacter", function(source, cb, charData)
  local src = source
  local newData = {}

  newData.citizenid = Utils.GenerateCID()
  if charData.gender then
    charData.gender = 1
  else
    charData.gender = 0
  end

  newData.charinfo = charData
  print("char data", json.encode(newData))

  if QBCore.Player.Login(src, false, newData) then
    print("NEW CHAR CREATED!")
    local randbucket = (GetPlayerPed(src) .. math.random(1,999))
    SetPlayerRoutingBucket(src, randbucket)
    QBCore.Commands.Refresh(src)
    loadHouseData()
    cb(true)
    TriggerClientEvent("qb-character-client:apartments:displayApartments", src, newData)
    GiveStarterItems(src)
  else
    cb(false)
  end
end)

QBCore.Functions.CreateCallback("lx_characters-server:characters:editCharacter", function(source, cb, charData)
  local src = source

  if charData.gender == true then
    charData.gender = 1
  else
    charData.gender = 0
  end

  print("char data", json.encode(charData))

  local result = MySQL.Sync.fetchSingle('SELECT charinfo FROM players WHERE citizenid = ?', {charData.cid})
  local charInfo = json.decode(result)
  print("old char info", json.encode(charInfo))

  charInfo.firstname = charData.firstname
  charInfo.lastname = charData.lastname
  charInfo.nationality = charData.nationality
  charInfo.backstory = charData.backstory
  charInfo.birthdate = charData.dob
  charInfo.gender = charData.gender

  print("new char info", json.encode(charInfo))
  charInfo = json.encode(charInfo)

  local update = MySQL.Sync.execute('UPDATE players SET charinfo = ? WHERE citizenid = ? ', {charInfo, charData.cid})
  if update then
    cb("UPDATED")
  else
    cb("ERROR")
  end
end)

QBCore.Functions.CreateCallback("lx_characters-server:characters:deleteCharacter", function(source, cb, charData)
  local src = source
  QBCore.Player.DeleteCharacter(src, charData.cid)
  cb("DELETED")
end)