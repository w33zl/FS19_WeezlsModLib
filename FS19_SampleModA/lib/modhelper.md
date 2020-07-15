# ModHelper (Weezls Mod Lib for FS19) - Simplifies the creation of script based mods for FS19

ModHelper adds a "Mods" class that acts as a wrapper and utility for Farming Simulator script based mods. 
It automatically reads the basic metadata of your mod from the modDesc.xml.
In addition to assisting with the instanziation of the mod this class also add some convienient functions to source other files, manage custom settings, debugging etc.

## Usage

First you need to make sure the ModHelper is loaded via the modDesc.xml. Basically the "modhelper.lua" must be loaded using a <sourceFile /> node in the <extraSourceFiles /> section:

    <extraSourceFiles>
      <sourceFile filename="lib/modhelper.lua"/>
    </extraSourceFiles>

Then you need to add this to the top of your custom script (where "YourMod" is the class/object with your mod):

    YourMod = Mod:init()

Basically this is all that is needed to get yuur mod up and running. Now you could add your custom code to the "loadMap" event like this:

    function YourMod:loadMap()
        print("My mod is working")
    end


## The 'Mod' Base Class

**Mod:init()**
This method initializes your mod. Remember to use the "Mod" namespace, i.e. `Mod:init()`.


## API

The following methods and properties is available in your mod.

### Utility functions 
The following methods uses your mod as "namespace", e.g. `YourMod:MethodName()`. They can also be called from within your mod via the `self` keyword, e.g. `self:MethodName()`.

**:source(filename)**
Sources any additional files. In contrast to the default global source method this will automatically add your mod's directory to the path

- filename: A relative path to the source file you want to load, e.g. `lib/additionalSourceFile.lua`

Usage:

    self:source("lib/additionalSourceFile.lua") -- No need to add g_currentModDirectory to the path

    YourMod:source("lib/additionalSourceFile.lua") -- You can also call this anywhere in your script if you use your mods full name


**:printInfo(message)**
Prints a informational message in the log with your mod's title and a timestamp as a prefix.

Usage:

    self:printInfo("This is some useful info")
    -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] This is some useful info

**:printDebug(message)**
Prints a debug message in the log with your mod's title, the text "DEBUG" and a timestamp as a prefix. Calling this method when debug mode is disabled will not print anything in the log.

    self.debugMode = false
    self:printDebug("Nothing") -- Will NOT output anything to the log

    self.debugMode = true
    self:printDebug("A debug message") -- Will not output anything to the log
    -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] DEBUG: A debug message
    

**:printDebugVar(label, variable)**
Dumps a variable to the log by printing a label, value (as a string) and the actual type name. This works the same way as printDebug and requires your mod to be in debug mode. See above for details.

Usage:

    local myVar = 11.5
    self:printDebugVar("Testing myVar", myVar)
    -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] DBGVAR: Testing myVar=11.5 [@number]

**:printWarning(message)**
Prints a warning message in the log with your mod's title, the text "Warning" and a timestamp as a prefix.

Usage:

    self:printWarning("This is a warning")
    -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] Warning: This is a warning

**:printError(message)**
Prints a error message in the log with your mod's title, the text "Error" and a timestamp as a prefix.

Usage:

    self:printError("Something is wrong")
    -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] Error: Something is wrong


### General Properties

**.name** [string] - The name of your mod
**.title** [string] - The title (from modDesc.xml)
**.author** [string] - The author info (from modDesc.xml)
**.dir** [string] - The directory of your mod
**.debugMode** [bool] - Is debug mode enabled


### The Settings Property
Your mod is instanciated with a settings property where your custom settings should go. With a few lines of code you can read settings from a XML file from within your mod (`./yourMod.xml`) as well as from the user settings (i.e. the modSettings folder where the savegames go)

**.settings**
The settings property will contain your custom settings 

**.settings:init(xmlNodeName, defaultSettingsFilename, userSettingsFilename)**
This method will initialize the settings objects. It is only need if you want to read default settings from file or write user settings to the users modSettings folder. 

- xmlNodeName: The name of the root XML node of your settings file, e.g. `mySettings`.
- defaultSettingsFilename: The relative path to your default settings (if any), e.g. `config/defaultSettings.xml`.
- userSettingsFilename (optional): The relative path to the user settings file (if any), e.g. `yourModName.xml`.

The method will return a reference back to the settings object itself for convinience. This table is also available from anywhere in your mod using `self.settings`.

Usage:

    self.settings:init("mySettings", "config/defaultSettings.xml", "yourModName.xml")


**.settings:load()**
This method will read settings from either the user settings file or the default settings file.


## Full example

This is a complete exaple of a fictional mod.

    local YourMod = Mod:init()

    function YourMod:loadMap()
        
        self:printInfo("My mod is working")

        -- Init settings and ddd default value
        local settings = settings:init("mySettings", "config/defaultSettings.xml", "yourModName.xml")
        settings.myCustomSetting = "This is a default value"

        self:printDebugVar("myCustomSetting", settings.myCustomSetting)
        -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] DBGVAR: myCustomSetting=This is a default value [@string]

        -- Load actual settings from both the default settings file and the user settings from the modsSettings-folder
        settings:load(function(xmlReader)
            settings.myCustomSetting = xmlReader:readString(nil, "myCustomSetting", settings.myCustomSetting)
        end)

        -- Print loaded value from config
        self:printDebugVar("myCustomSetting", settings.myCustomSetting) -- Assuming the defaultSettings.xml contains the following XML: <mySettings><myCustomSetting>Value from config</myCustomSetting></mySettings>
        -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] DBGVAR: myCustomSetting=Value from config [@string]

        -- Change the settings
        settings.myCustomSetting = "This is a new custom value"

        self:printDebugVar("myCustomSetting", settings.myCustomSetting)
        -- OUTPUTS: YYYY-MM-DD HH:MM:SS [YourModTitle] DBGVAR: myCustomSetting=This is a new custom value [@string]

        -- Save the current settings to the users modsSettings folder
        settings:save(function(xmlWriter)
            xmlWriter:saveString(nil, "myCustomSetting", settings.myCustomSetting)
        end)
        -- Should write a XML file named '{SAVEGAME_FOLDER}/modsSettings/yourModName.xml' with the following content: <mySettings><myCustomSetting>This is a new custom value</myCustomSetting></mySettings>

        -- Enable debug mode
        self.debugMode = true
        self:printDebug("Debug mode is now on")
    end
