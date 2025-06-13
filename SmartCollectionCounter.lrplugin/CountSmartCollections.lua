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

  for _, processedSet in ipairs(processedSets) do
    -- Build name path
    local namePath = processedSet:getName()
    local parent = processedSet:getParent()
    while parent and parent ~= filmScansSet do
      namePath = parent:getName() .. " > " .. namePath
      parent = parent:getParent()
    end

    -- Count smart collections
    local bwCount = 0
    local c41Count = 0
    for _, coll in ipairs(processedSet:getChildCollections()) do
      if coll:isSmartCollection() then
        local name = string.lower(coll:getName())
        if string.find(name, BLACK_AND_WHITE_STRING_MATCH) then
          bwCount = bwCount + 1
        else
          c41Count = c41Count + 1
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

  -- Final output
  local message = table.concat(results, "\n")
  message = message .. string.format(
    "\nGrand Total:\n  B&W: %d\n  C41: %d\n  Total Smart Collections (i.e. Total Rolls Developed): %d",
    totalBW, totalC41, totalSmart
  )

  LrDialogs.message("Smart Collections Breakdown", message, "info")
end)
