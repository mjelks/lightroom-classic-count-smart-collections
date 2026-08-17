# Count Smart Collections Lightroom Classic Plugin
Simple Plugin used to count Smart Collections (film rolls) nested under a top-level collection set, broken down by process type and camera.

In my exact use case, the top level collection set is **Film Scans**. The plugin recursively walks every collection set under it, at any depth, and counts every Smart Collection it finds — regardless of how the sub-folders are organized (e.g. "Imported" vs "Processed"). Empty sets are skipped.

The top-level collection name can be changed via the constant defined in the script:

```lua
TOP_LEVEL_COLLECTION_NAME = "Film Scans"
```

## B&W vs C41

Each Smart Collection is classified as B&W or C41 based on whether its name contains the string "bw" (case-insensitive):

```lua
BLACK_AND_WHITE_STRING_MATCH = "bw"
```

## Camera breakdown

If the [Negative Lab Pro](https://negativelabpro.com/) plugin (`com.nate.photographic.negative`) has written camera make/model metadata to a photo, the counter reads it from the first few photos in each Smart Collection and tallies totals per camera. Smart Collections with no NLP camera metadata are bucketed as "Unknown", and the output lists exactly which Smart Collections are missing it so you know where to add it.

The camera breakdown is grouped by film format — **35mm**, **Medium Format**, then **Large Format** — determined by matching those strings against any segment of each Smart Collection's folder path (so a sort-order prefix like "•35mm" still matches). Within each format group, cameras are listed alphabetically. Cameras whose folder path doesn't match a known format are listed last, without a header.

## Installation

Add the plugin via the Lightroom `File -> Plug-in Manager...` dialog. Once installed, run it from `File -> Plug-in Extras -> Count Smart Collections in Film Scans`.

<img width="501" height="615" alt="screenshottty" src="https://github.com/user-attachments/assets/3f7dad41-1e7a-45db-a6ad-647360697bd4" />
