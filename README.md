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

<img width="540" alt="Screenshot 2025-06-11 at 2 17 31 PM" src="https://github.com/user-attachments/assets/7ce69069-08d2-4829-b06a-f46bfd26d1a0" />

