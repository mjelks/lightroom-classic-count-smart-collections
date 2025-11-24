local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrBinding = import 'LrBinding'
local LrView = import 'LrView'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'

-- === Constants ===
local PUBLISH_SERVICE_NAME = "michaeljelks.smugmug.com"

-- === Helper: Find publish service by title ===
local function getPublishServiceByTitle(title)
    local catalog = LrApplication.activeCatalog()
    local services = catalog:getPublishServices()

    for _, service in ipairs(services) do
        if service:getName() == title then
            return service
        end
    end
    return nil
end

-- === Recursive: Find or create nested published collection sets ===
local function getOrCreatePublishedSet(parent, name, publishService)
    for _, set in ipairs(parent:getChildCollectionSets()) do
        if set:getName() == name then
            return set
        end
    end
    return publishService:createPublishedCollectionSet(name, parent)
end

-- === Main logic ===
local function createPublishedSmartGallery()
    local catalog = LrApplication.activeCatalog()
    local publishService = getPublishServiceByTitle(PUBLISH_SERVICE_NAME)

    if not publishService then
        LrDialogs.message(PUBLISH_SERVICE_NAME .. " publish service not found.")
        return
    end

    LrFunctionContext.callWithContext("createPublishedSmartGallery", function(context)
        local f = LrView.osFactory()
        local props = LrBinding.makePropertyTable(context)
        props.keyword = "foo"

        local contents = f:row {
            spacing = f:control_spacing(),
            f:static_text {
                title = "Keyword filter:",
                alignment = 'right',
                width = 150,
            },
            f:edit_field {
                value = LrView.bind('keyword'),
                immediate = true,
                width_in_chars = 20,
            },
        }

        local result = LrDialogs.presentModalDialog {
            title = "Create Smart " .. PUBLISH_SERVICE_NAME .. " Gallery",
            contents = contents,
            actionVerb = "Create",
        }

        if result ~= "ok" or not props.keyword or #props.keyword == 0 then
            return
        end

        catalog:withWriteAccessDo("Create Smart Published Gallery", function()
            local rootSets = publishService:getChildCollectionSets()
            local shareSet

            for _, set in ipairs(rootSets) do
                if set:getName() == "Share" then
                    shareSet = set
                    break
                end
            end

            if not shareSet then
                shareSet = publishService:createPublishedCollectionSet("Share", nil)
            end

            local currentYear = os.date("%Y")
            local yearSet = getOrCreatePublishedSet(shareSet, currentYear, publishService)

            -- Remove existing collection if it exists
            for _, pc in ipairs(yearSet:getChildCollections()) do
                if pc:getName() == "Auto Smart Export" then
                    pc:delete()
                    break
                end
            end

            local newPubCollection = publishService:createPublishedSmartCollection(
                "Auto Smart Export",
                {
                    combine = "intersect",
                    rules = {
                        {
                            criteria = "rating",
                            operation = ">=",
                            value = 2,
                        },
                        {
                            criteria = "keywords",
                            operation = "contains",
                            value = props.keyword,
                        },
                    }
                },
                yearSet
            )

            if newPubCollection then
                LrDialogs.message("Smart gallery created in " .. PUBLISH_SERVICE_NAME .. "!", "Now you can publish it to your " .. PUBLISH_SERVICE_NAME .. " account.", "info")
            else
                LrDialogs.message("Failed to create published smart collection.")
            end
        end)
    end)
end

-- Run asynchronously
LrTasks.startAsyncTask(function()
    createPublishedSmartGallery()
end)
