Utils = {}

Utils.DeleteCameras = function()
  if createdCamera then createdCamera = false end
  if skyCamera then
    skyCamera:SetActive(false)
    skyCamera:Delete()
    skyCamera = nil
  end

  if pedCamera then
    pedCamera:SetActive(false)
    pedCamera:Delete()
    pedCamera = nil
  end

  if apartmentCam then
    apartmentCam:SetActive(false)
    apartmentCam:Delete()
    apartmentCam = nil
  end

  if oldCam then
    oldCam:SetActive(false)
    oldCam:Delete()
    oldCam = nil
  end
end

Utils.DeletePeds = function()
  characterTick:Kill()
  markerIndex = -1
  charMarker = nil

  if #createdPeds > 0 then
    for k, v in pairs(createdPeds) do
      DeleteEntity(v)
      
      if next(createdPeds, k) == nil then
        createdPeds = {}
      end
    end
  end
end