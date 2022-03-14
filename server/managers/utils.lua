Utils = {}

Utils.GenerateCID = function()
  local upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local citizenid = ""

  for i = 1, 3 do -- Generate First Two Letters In Citizen ID
    local rand = math.random(#upperCase)
    citizenid = citizenid .. string.sub(upperCase, rand, rand)
  end

  citizenid = citizenid .. math.random(11111, 99999) -- Add numbers to citizen id
  return citizenid
end