local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'

TOP_LEVEL_COLLECTION_NAME = "Film Scans"
SUB_LEVEL_COLLECTION_NAME = "Processed"

-- Recursively search for 'Processed' collection sets
local function findProcessedSetsUnder(parentSet)
  local processedSets = {}
  for _, childSet in ipairs(parentSet:getChildCollectionSets()) do
    if childSet:getName() == SUB_LEVEL_COLLECTION_NAME then
      table.insert(processedSets, childSet)
    end
    -- Recurse into nested sets
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

  -- Find "Film Scans"
  for _, set in ipairs(topLevelSets) do
    if set:getName() == TOP_LEVEL_COLLECTION_NAME then
      filmScansSet = set
      break
    end
  end

  if not filmScansSet then
    LrDialogs.message("Error", "'Film Scans' collection set not found.", "critical")
    return
  end

  -- Find 'Processed' sets under Film Scans
  local processedSets = findProcessedSetsUnder(filmScansSet)
  local results = {}
  local grandTotal = 0

  for _, processedSet in ipairs(processedSets) do
    local namePath = processedSet:getName()
    local parent = processedSet:getParent()
    while parent and parent ~= filmScansSet do
      namePath = parent:getName() .. " > " .. namePath
      parent = parent:getParent()
    end

    local count = 0
    for _, coll in ipairs(processedSet:getChildCollections()) do
      if coll:isSmartCollection() then
        count = count + 1
      end
    end

    table.insert(results, namePath .. ": " .. count)
    grandTotal = grandTotal + count
  end

  -- Display results
  local message = table.concat(results, "\n")
  message = message .. "\n\nTotal Smart Collections: " .. grandTotal

  LrDialogs.message("Smart Collections in " .. TOP_LEVEL_COLLECTION_NAME .. " > Processed", message, "info")
end)
