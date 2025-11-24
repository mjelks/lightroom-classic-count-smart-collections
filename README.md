# Count Smart Collections Lightroom Classic Plugin
Simple Plugin used to count the number of images folders inside a top level collection.

In my exact use case, the top level collection can be found in **Film Scans**.
Then I would like a count of all Smart Collections under 
  **Film Scans** --> **Processed**

The string constants of "Film Scans" and "Processed" can both be changed via the constants I've defined in the script. 

```lua
TOP_LEVEL_COLLECTION_NAME = "Film Scans"
SUB_LEVEL_COLLECTION_NAME = "Processed"
```


To install, simply add the Plugin via the Lightroom `File -> Plug-in Manager...` Dialog and Add this plugin.

<img width="501" height="615" alt="screenshottty" src="https://github.com/user-attachments/assets/3f7dad41-1e7a-45db-a6ad-647360697bd4" />
