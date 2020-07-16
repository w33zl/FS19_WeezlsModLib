--[[

ModHelper (Weezls Mod Lib for FS19) - Simplifies the creation of script based mods for FS19

This utility class acts as a wrapper for Farming Simulator script based mods. It hels with setting up the mod up and 
acting as a "bootstrapper" for the main mod class/table. It also add additional utility functions for sourcing additonal files, 
manage user settings, assist debugging etc.

See ModHelper.md for documentation and more details.

Author:     w33zl
Version:    1.0
Modified:   2020-07-13

GitHub:     https://github.com/w33zl/FS19_WeezlsModLib


Changelog:
v1.0        Initial public release

License:    CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/)
This license allows reusers to distribute, remix, adapt, and build upon the material in any medium or 
format for noncommercial purposes only, and only so long as attribution is given to the creator.
If you remix, adapt, or build upon the material, you must license the modified material under identical terms. 

]]


-- ModHelper = {
--     new = function()
--     end--function
-- }


-- local function printInternal(self, category, message)
--     category = category or ""
--     message = message or ""
--     print(string.format("[%s] %s: %s", self.title, tostring(category):upper(), tostring(message)))
-- end
-- local function printDebug(self, message) self:printInternal("DEBUG", message) end
-- local function printWarning(self, message) self:printInternal("WARNING", message) end
-- local function printError(self, message) self:printInternal("ERROR", message) end

-- This will create the "Mod" base class (and effectively reset any previous references to other mods) 
Mod = {

    debugMode = false,

    printInternal = function(self, category, message)
        message = message or ""
        if category ~= nil and category ~= "" then
            category = string.format(" %s:", category)
        else
            category = ""
        end
        print(string.format("[%s]%s %s", self.title, category, tostring(message)))
    end,

    printDebug = function(self, message)
        if self.debugMode == true then
            self:printInternal("DEBUG", message)
        end
    end,

    printDebugVar = function(self, name, variable)
        if self.debugMode ~= true then
            return
        end

        -- local tt1 = (val or "")
        local valType = type(variable)
    
        if valType == "string" then
            variable = string.format( "'%s'", variable )
        end
    
        local text = string.format( "%s=%s [@%s]", name, tostring(variable), valType )
        self:printInternal("DBGVAR", text)
    end,
    
    printWarning = function(self, message)
        self:printInternal("Warning", message)
    end,

    printError = function(self, message)
        self:printInternal("Error", message)
    end,


}
Mod_MT = {
}

-- Set initial values for the global Mod object/"class"
Mod.dir = g_currentModDirectory;
Mod.name = g_currentModName

local modDescXML = loadXMLFile("modDesc", Mod.dir .. "modDesc.xml");
Mod.title = getXMLString(modDescXML, "modDesc.title.en");
Mod.author = getXMLString(modDescXML, "modDesc.author");
Mod.version = getXMLString(modDescXML, "modDesc.version");
delete(modDescXML);

function Mod:printInfo(message)
    self:printInternal("", message)
end


-- Local aliases for convinience
local function printInfo(message) Mod:printInfo(message) end
local function printDebug(message) Mod:printDebug(message) end
local function printDebugVar(name, variable) Mod:printDebugVar(name, variable) end
local function printWarning(message) Mod:printWarning(message) end
local function printError(message) Mod:printError(message) end


-- Helper functions
local function validateParam(value, typeName, message)
    local failed = false
    failed = failed or (value == nil)
    failed = failed or (typeName ~= nil and type(value) ~= typeName)
    failed = failed or (type(value) == string and value == "")

    if failed then print(message) end

    return not failed
end

local ModSettings = {};
ModSettings.__index = ModSettings;

function ModSettings:new(mod)
    local newModSettings = {};
    setmetatable(newModSettings, self);
    self.__index = self;
    newModSettings.__mod = mod;
    return newModSettings;
end
function ModSettings:init(name, defaultSettingsFileName, userSettingsFileName)
    if not validateParam(name, "string", "Parameter 'name' (#1) is mandatory and must contain a non-empty string") then
        return;
    end

    -- if keys == nil or type(keys) ~= "table" then 
    --     self.__mod.printError("Parameter 'keys' (#1) is mandatory and must contain a table");
    --     return;
    -- end
    if defaultSettingsFileName == nil or type(defaultSettingsFileName) ~= "string" then 
        self.__mod.printError("Parameter 'defaultSettingsFileName' (#2) is mandatory and must contain a filename");
        return;
    end

    local modSettingsDir = getUserProfileAppPath() .. "modsSettings"
    -- local newXmlFile = modSettingsDir .. "/" .. RealClock.configFileName
    -- if not fileExists(newXmlFile) then
    --     createFolder(modSettingsDir)

    self._config = {
        xmlNodeName = name,
        modSettingsDir = modSettingsDir,
        defaultSettingsFileName = defaultSettingsFileName,
        defaultSettingsPath = self.__mod.dir .. defaultSettingsFileName,
        userSettingsFileName = userSettingsFileName,
        userSettingsPath = modSettingsDir .. "/" .. userSettingsFileName,
    }

    print("userSettingsPath: " .. self._config.userSettingsPath)
    print("defaultSettingsPath: " .. self._config.defaultSettingsPath)

    -- self.__keys = keys
    return self;
end
function ModSettings:load(callback)
    -- if self._config.xmlNodeName == nil or type(self.__keys) ~= "table" or self.defaultSettingsFileName == nil or type(self.defaultSettingsFileName) ~= "string" then 
    --     self.__mod.printError("Cannot execute load method of ModSettings, reason was: Not properly initialized, one or more required values is missing. ");
    --     return;
    -- end

    if not validateParam(callback, "function", "Parameter 'callback' (#1) is mandatory and must contain a valid callback function") then
        return;
    end

    local defaultSettingsFile = self._config.defaultSettingsPath;
    local userSettingsFile = self._config.userSettingsPath;
    local xmlNodeName = self._config.xmlNodeName or "settings"

    if defaultSettingsFile == "" or userSettingsFile == "" then
        self.__mod.printError("Cannot load settings, neither a user settings nor a default settings file was supplied. Nothing to read settings from.");
        return;
    end

    local function executeXmlReader(xmlNodeName, fileName, callback)
        local xmlFile = loadXMLFile(xmlNodeName, fileName)

        if xmlFile == nil then
            printError("Failed to open/read settings file '" .. fileName .. "'!")
            return
        end

        local xmlReader = {
            xmlFile = xmlFile,
            xmlNodeName = xmlNodeName,
            
            getKey = function(self, categoryName, valueName)
                local xmlKey = self.xmlNodeName

                
                if categoryName ~= nil and categoryName ~= "" then 
                    xmlKey = xmlKey .. "." .. categoryName
                end

                xmlKey = xmlKey .. "." .. valueName
                
                return xmlKey
            end,

            readBool = function(self, categoryName, valueName, defaultValue)
                return Utils.getNoNil(getXMLBool(self.xmlFile, self:getKey(categoryName, valueName)), defaultValue or false)
            end,
            readFloat = function(self, categoryName, valueName, defaultValue)
                return Utils.getNoNil(getXMLFloat(self.xmlFile, self:getKey(categoryName, valueName)), defaultValue or 0.0)
            end,
            readString = function(self, categoryName, valueName, defaultValue)
                return Utils.getNoNil(getXMLString(self.xmlFile, self:getKey(categoryName, valueName)), defaultValue or "")
            end,

        }
        callback(xmlReader);
        -- self.position.dynamic = Utils.getNoNil(getXMLBool(xml, "RealClock.position#isDynamic"), RealClock.d.position.dynamic)
    end

    if fileExists(defaultSettingsFile) then
        executeXmlReader(xmlNodeName, defaultSettingsFile, callback);
    end

    if fileExists(userSettingsFile) then
        executeXmlReader(xmlNodeName, userSettingsFile, callback);
    end



    -- if callback == nil or type(callback) ~= "function" then 
    --     self.__mod.printError("Parameter 'callback' (#1) is mandatory and must contain a valid callback function");
    --     return;
    -- end

    -- local xml = loadXMLFile("RealClock", fileName)
    -- self.position.dynamic = Utils.getNoNil(getXMLBool(xml, "RealClock.position#isDynamic"), RealClock.d.position.dynamic)
  

    -- for key, value in pairs(self.__keys) do
    --     print("Found key '" .. key .. "' = " .. type(value))
    -- end
    -- return self;
end


function ModSettings:save(callback)
    
    -- setXMLBool(xml, "RealClock.position#isDynamic", self.position.dynamic)
    -- setXMLFloat(xml, "RealClock.position#x", self.position.x)
    -- setXMLFloat(xml, "RealClock.position#y", self.position.y)
    -- setXMLString(xml, "RealClock.rendering#color", self.rendering.color)
    -- setXMLFloat(xml, "RealClock.rendering#fontSize", self.rendering.fontSize)
    -- setXMLString(xml, "RealClock.format#string", self.timeFormat)
    -- saveXMLFile(xml)
    -- delete(xml)    


    if not validateParam(callback, "function", "Parameter 'callback' (#1) is mandatory and must contain a valid callback function") then
        return;
    end

    local userSettingsFile = self._config.userSettingsPath;
    local xmlNodeName = self._config.xmlNodeName or "settings"

    if userSettingsFile == "" then
        printError("Missing filename for user settings, cannot save mod settings.");
        return;
    end

    if not fileExists(userSettingsFile) then
        createFolder(self._config.modSettingsDir)
    end

    local function executeXmlWriter(xmlNodeName, fileName, callback)
        -- local xmlFile = loadXMLFile(xmlNodeName, fileName)
        local xmlFile = createXMLFile(xmlNodeName, fileName, xmlNodeName)

        if xmlFile == nil then
            printError("Failed to create/write to settings file '" .. fileName .. "'!")
            return
        end

        local xmlWriter = {
            xmlFile = xmlFile,
            xmlNodeName = xmlNodeName,
            
            getKey = function(self, categoryName, valueName)
                local xmlKey = self.xmlNodeName

                
                if categoryName ~= nil and categoryName ~= "" then 
                    xmlKey = xmlKey .. "." .. categoryName
                end

                xmlKey = xmlKey .. "." .. valueName
                
                return xmlKey
            end,

            saveBool = function(self, categoryName, valueName, value)
                return setXMLBool(self.xmlFile, self:getKey(categoryName, valueName), Utils.getNoNil(value, false))
            end,

            saveFloat = function(self, categoryName, valueName, value)
                return setXMLFloat(self.xmlFile, self:getKey(categoryName, valueName), Utils.getNoNil(value, 0.0))
            end,

            saveString = function(self, categoryName, valueName, value)
                return setXMLString(self.xmlFile, self:getKey(categoryName, valueName), Utils.getNoNil(value, ""))
            end,

        }
        callback(xmlWriter);

        saveXMLFile(xmlFile)
        delete(xmlFile)
    end

    executeXmlWriter(xmlNodeName, userSettingsFile, callback);

    return self
end



function Mod:source(file)
    source(self.dir .. file);
end--function


function Mod:init()
    local newMod = self:new();

-- print("g_brandColorManager:", tostring(g_brandColorManager))
-- print("g_logManager:", tostring(g_logManager))

-- print("g_currentMission:", tostring(g_currentMission))
-- print("g_languageShort:", tostring(g_languageShort))
-- print("NetworkUtil:", tostring(NetworkUtil))
-- print("g_languageShort:", tostring(g_languageShort))

-- print("g_brandManager:", tostring(g_brandManager))
-- DebugUtil.printTableRecursively(g_brandManager,".",0,2);

-- print("g_brandManager.indexToBrand:")
-- DebugUtil.printTableRecursively(g_brandManager.indexToBrand,".",0,2);


    addModEventListener(newMod);

    print(string.format("Load mod: %s (v%s) by %s", newMod.title, newMod.version, newMod.author))

    return newMod;
end--function

function Mod:new()
    local newMod = {}

    setmetatable(newMod, self)
    self.__index = self

    newMod.dir = g_currentModDirectory;
    newMod.settings = ModSettings:new(newMod);


    local modDescXML = loadXMLFile("modDesc", newMod.dir .. "modDesc.xml");
    newMod.title = getXMLString(modDescXML, "modDesc.title.en");
    newMod.author = getXMLString(modDescXML, "modDesc.author");
    newMod.version = getXMLString(modDescXML, "modDesc.version");
    delete(modDescXML);
    
    -- print(string.format("Load mod: %s (v%s) by %s", newMod.title, newMod.version, newMod.author))

    return newMod;
end--function

-- ModSettings = {}
-- function ModSettings:new(filename)
--     if not filename then
--         print("Warning: Parameter 'filename' is required.");
--     end
-- end--if




