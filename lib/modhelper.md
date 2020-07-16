# ModHelper (Weezls Mod Lib for FS19) - Simplifies the creation of script based mods for FS19

ModHelper is a utility class that acts as a convenient wrapper for Farming Simulator script based mods. It hels with setting up the mod up and acting as a "bootstrapper" for the main mod class/table. 

It also adds utility functions for sourcing additonal files, manage user settings, assist debugging etc. 
The script will also automatically read the core metadata of your mod from the modDesc.xml and store it as parameters in your mod for easy access.

Author:     w33zl
GitHub:     https://github.com/w33zl/FS19_WeezlsModLib

License:    CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator.
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 


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


## The Mod Initiator

**Mod:init()**
This method initializes your mod. Remember to use the "Mod" namespace, i.e. `Mod:init()`.

Usage:

    YourMod = Mod:init()


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


### Properties

- .name         [string]    The name of your mod
- .title        [string]    The title (from modDesc.xml)
- .author       [string]    The author info (from modDesc.xml)
- .version      [string]    The version info (from modDesc.xml)
- .dir          [string]    The directory of your mod
- .debugMode    [bool]      Is debug mode enabled
- .settings     [table]     The settings property will contain your custom settings (see below for details)


### The Settings Property
Your mod is instanciated with a settings property where your custom settings should go. With a few lines of code you can read settings from a XML file from within your mod (`./yourMod.xml`) as well as from the user settings (i.e. the modSettings folder where the savegames go)

**.settings:init(xmlNodeName, defaultSettingsFilename, userSettingsFilename)**
This method will initialize the settings objects. It is only need if you want to read default settings from file or write user settings to the user's modSettings folder. 

- xmlNodeName                       The name of the root XML node of your settings file, e.g. `mySettings`.
- defaultSettingsFilename           The relative path to your default settings (if any), e.g. `config/defaultSettings.xml`.
- userSettingsFilename (optional)   The relative path to the user settings file (if any), e.g. `yourModName.xml`.

The method will return a reference back to the settings object itself for convinience. This table is also available from anywhere in your mod using `self.settings`.

Usage:

    self.settings:init("mySettings", "config/defaultSettings.xml", "yourModName.xml")


**.settings:load(callbackMethod)**
This method will read settings from the user settings file and the default settings file. For each file it finds it will execute the callback method where you can extract the actual values need. The callback could be a anonymous function.

- callbackMethod    [function]      A reference to the callback method that will be executed upon load

Signature of the callback method:

    function callbackMethod(xmlReader)
    end

For details about the xmlReader see separate section 'XML Reader' below.

Usage:

    settings:load(function(xmlReader)
        settings.myCustomSetting = xmlReader:readString(nil, "myCustomSetting", settings.myCustomSetting)
    end)

**.settings:save(callbackMethod)**
This method will save the settings to the user settings file. The callback can be a anonymous function.

- callbackMethod    [function]      A reference to the callback method that will be executed upon save

Signature of the callback method:

    function callbackMethod(xmlWriter)
    end

For details about the xmlWriter see separate section 'XML Writer' below.

Usage:

    settings:save(function(xmlWriter)
        xmlWriter:saveString(nil, "myCustomSetting", settings.myCustomSetting)
    end)


### XML Reader
The XML Reader object has the following methods:

- :readBool(sectionName, settingName, defaultValue)     Reads the value from the xml node with the name of 'settingName' and returns it as a boolean.
- :readFloat(sectionName, settingName, defaultValue)    Reads the value from the xml node with the name of 'settingName' and returns it as a float.
- :readString(sectionName, settingName, defaultValue)   Reads the value from the xml node with the name of 'settingName' and returns it as a string.

Parameters:
- sectionName               The name of the section which this setting belongs to, e.g. a section name of 'mySection' would look for `<mySection><yourCustomValue /></mySection>`. A `nil` value skips the section part and only looks for `<yourCustomValue />`
- settingName               The actual name of the setting you want to read, e.g. with a settingName of 'yourCustomValue' the script would look for a XML node like this `<yourCustomValue>My value<yourCustomValue>`
- defaultValue (optional)   A default value if no actual value was found in the settings file

Usage:

    settings:load(function(xmlReader)
        settings.enableThisFeature = xmlReader:readBool("myCustomSection", "enableThisFeature", false)
        settings.textScale = xmlReader:readFloat("myCustomSection", "textScale", 1.2)
        settings.playerName = xmlReader:readString("myCustomSection", "playerName", "")
    end)

### XML Writer
The XML Writer object has the following methods:

- :saveBool(sectionName, settingName, value)     Saves the value (formatted as a boolean) and stores it in the node 'settingName'.
- :saveFloat(sectionName, settingName, value)    Saves the value (formatted as a number) and stores it in the node 'settingName'.
- :saveString(sectionName, settingName, value)   Saves the value (formatted as a string) and stores it in the node 'settingName'.

Parameters:
- sectionName               The name of the section which this setting belongs to, e.g. a section name of 'mySection' would look for `<mySection><yourCustomValue /></mySection>`. A `nil` value skips the section part and only looks for `<yourCustomValue />`
- settingName               The name of the setting you want to save, i.e. 'yourCustomValue' will create a node like this `<yourCustomValue>My value<yourCustomValue>`
- value                     The actual value to be saved in the XML settings file

Usage:

    settings:save(function(xmlWriter)
        xmlWriter:saveBool("myCustomSection", "enableThisFeature", false)
        xmlWriter:saveFloat("myCustomSection", "textScale", 1.2)
        xmlWriter:saveString("myCustomSection", "playerName", "")
    end)

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
