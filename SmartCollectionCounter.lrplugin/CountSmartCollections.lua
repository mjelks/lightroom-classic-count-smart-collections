local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'

TOP_LEVEL_COLLECTION_NAME = "Film Scans"
SUB_LEVEL_COLLECTION_NAME = "Processed"
BLACK_AND_WHITE_STRING_MATCH = "bw" -- case-insensitive

-- Recursively search for 'Processed' collection sets
local function findProcessedSetsUnder(parentSet)
  local processedSets = {}
  for _, childSet in ipairs(parentSet:getChildCollectionSets()) do
    if childSet:getName() == SUB_LEVEL_COLLECTION_NAME then
      table.insert(processedSets, childSet)
    end
    local nested = findProcessedSetsUnder(childSet)
    for _, n in ipairs(nested) do
      table.insert(processedSets, n)
    end
  end
  return processedSets
end

-- Debug flag - set to true to see all metadata fields
local DEBUG_METADATA = false
local debugOutputDone = false

-- Helper function to debug all metadata fields
local function debugAllMetadata(photo)
  if debugOutputDone then return end
  debugOutputDone = true
  
  local debugInfo = "=== DEBUG: NLP Plugin Properties ===\n\n"
  debugInfo = debugInfo .. "Photo: " .. photo:getFormattedMetadata("fileName") .. "\n\n"
  
  -- Try to access NLP plugin properties (actual property names from NLPMetadataTagsetV3.lua)
  debugInfo = debugInfo .. "--- Testing NLP Plugin Properties ---\n"
  local nlpFields = {
    "nlpOriginalCameraMake",
    "nlpOriginalCameraModel",
    "nlpOriginalLensMake",
    "nlpOriginalLens",
    "nlpFilmStock",
    "nlpSource",
    "rollName",
    "rollID",
  }
  
  for _, fieldName in ipairs(nlpFields) do
    local status, value = LrTasks.pcall(function()
      return photo:getPropertyForPlugin("com.nate.photographic.negative", fieldName)
    end)
    if status and value and value ~= "" then
      debugInfo = debugInfo .. string.format("  %s = %s\n", fieldName, tostring(value))
    else
      debugInfo = debugInfo .. string.format("  %s = (empty)\n", fieldName)
    end
  end
  
  -- Also show camera-related raw metadata for comparison
  debugInfo = debugInfo .. "\n--- Camera/Make/Model in Raw Metadata ---\n"
  local rawMeta = photo:getRawMetadata()
  if rawMeta then
    for key, value in pairs(rawMeta) do
      local lowerKey = string.lower(tostring(key))
      if string.find(lowerKey, "camera") or string.find(lowerKey, "make") or string.find(lowerKey, "model") then
        debugInfo = debugInfo .. string.format("  %s = %s\n", tostring(key), tostring(value))
      end
    end
  end
  
  LrDialogs.message("NLP Metadata Debug", debugInfo, "info")
end

-- Helper function to safely get NLP metadata
local function getNLPMetadata(photo, fieldName)
  -- NLP uses searchable custom metadata fields in the catalog
  -- Plugin ID: com.nate.photographic.negative
  -- Property names: nlpOriginalCameraMake, nlpOriginalCameraModel
  local nlpFieldName = "nlpOriginal" .. fieldName:gsub("^%l", string.upper) -- CameraMake -> nlpOriginalCameraMake
  
  local status, value = LrTasks.pcall(function()
    return photo:getPropertyForPlugin("com.nate.photographic.negative", nlpFieldName)
  end)
  
  if status and value and value ~= "" then
    return value
  end
  
  return ""
end

-- Background task
LrTasks.startAsyncTask(function()
  local catalog = LrApplication.activeCatalog()
  local topLevelSets = catalog:getChildCollectionSets()
  local filmScansSet = nil

  -- Find top-level 'Film Scans'
  for _, set in ipairs(topLevelSets) do
    if set:getName() == TOP_LEVEL_COLLECTION_NAME then
      filmScansSet = set
      break
    end
  end

  if not filmScansSet then
    LrDialogs.message("Error", "'" .. TOP_LEVEL_COLLECTION_NAME .. "' collection set not found.", "critical")
    return
  end

  -- Find all 'Processed' sets under Film Scans
  local processedSets = findProcessedSetsUnder(filmScansSet)
  local results = {}

  local totalSmart = 0
  local totalBW = 0
  local totalC41 = 0
  local cameraBreakdown = {}

  for _, processedSet in ipairs(processedSets) do
    -- Build name path
    local namePath = processedSet:getName()
    local parent = processedSet:getParent()
    while parent and parent ~= filmScansSet do
      namePath = parent:getName() .. " > " .. namePath
      parent = parent:getParent()
    end

    -- Count smart collections and gather camera data
    local bwCount = 0
    local c41Count = 0
    for _, coll in ipairs(processedSet:getChildCollections()) do
      if coll:isSmartCollection() then
        local name = string.lower(coll:getName())
        local isBW = string.find(name, BLACK_AND_WHITE_STRING_MATCH)
        if isBW then
          bwCount = bwCount + 1
        else
          c41Count = c41Count + 1
        end
        
        -- Get camera make and model from first photo in collection
        local photos = coll:getPhotos()
        if #photos > 0 then
          local cameraMake = ""
          local cameraModel = ""
          
          -- Try to find a photo with NLP metadata (check up to 5 photos)
          for i = 1, math.min(5, #photos) do
            local photo = photos[i]
            
            -- Debug metadata on first photo found
            if DEBUG_METADATA and i == 1 then
              debugAllMetadata(photo)
            end
            
            local make = getNLPMetadata(photo, 'CameraMake')
            local model = getNLPMetadata(photo, 'CameraModel')
            
            if make ~= "" or model ~= "" then
              cameraMake = make
              cameraModel = model
              break
            end
          end
          
          local cameraKey
          if cameraMake == "" and cameraModel == "" then
            cameraKey = "Unknown"
          else
            cameraKey = cameraMake .. " " .. cameraModel
            cameraKey = cameraKey:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
          end
          
          -- Initialize camera entry if needed
          if not cameraBreakdown[cameraKey] then
            cameraBreakdown[cameraKey] = {total = 0, bw = 0, c41 = 0}
          end
          
          -- Update counts
          cameraBreakdown[cameraKey].total = cameraBreakdown[cameraKey].total + 1
          if isBW then
            cameraBreakdown[cameraKey].bw = cameraBreakdown[cameraKey].bw + 1
          else
            cameraBreakdown[cameraKey].c41 = cameraBreakdown[cameraKey].c41 + 1
          end
        end
      end
    end

    local subtotal = bwCount + c41Count
    totalBW = totalBW + bwCount
    totalC41 = totalC41 + c41Count
    totalSmart = totalSmart + subtotal

    table.insert(results,
      string.format("%s:\n  B&W: %d\n  C41: %d\n  Total: %d\n", namePath, bwCount, c41Count, subtotal)
    )
  end

  -- Sort camera breakdown by count (descending)
  local sortedCameras = {}
  for camera, counts in pairs(cameraBreakdown) do
    table.insert(sortedCameras, {camera = camera, total = counts.total, bw = counts.bw, c41 = counts.c41})
  end
  table.sort(sortedCameras, function(a, b) return a.total > b.total end)

  -- Build camera breakdown string
  local cameraResults = {}
  if #sortedCameras > 0 then
    -- Add header
    table.insert(cameraResults, "Camera | Total (C41|B&W)")
    
    -- Add camera rows
    for _, item in ipairs(sortedCameras) do
      table.insert(cameraResults, string.format("%s: %d (%d|%d)", 
        item.camera, item.total, item.c41, item.bw))
    end
  end

  -- Final output
  local message = table.concat(results, "\n")
  message = message .. string.format(
    "\nGrand Total:\n  B&W: %d\n  C41: %d\n  Total Smart Collections (i.e. Total Rolls Developed): %d",
    totalBW, totalC41, totalSmart
  )
  
  if #cameraResults > 0 then
    message = message .. "\n\nCamera Breakdown:\n" .. table.concat(cameraResults, "\n")
  else
    message = message .. "\n\nCamera Breakdown: No camera metadata found"
  end

  LrDialogs.message("Smart Collections Breakdown", message, "info")
end)