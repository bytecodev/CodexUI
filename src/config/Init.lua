local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))

local ConfigManager = {}

ConfigManager.Parser = {
	Colorpicker = {
		Save = function(obj)
			return {
				__type = obj.__type,
				value = obj.Default:ToHex(),
				transparency = obj.Transparency or nil,
			}
		end,
		Load = function(element, data)
			if element and element.Update then
				element:Update(Color3.fromHex(data.value), data.transparency or nil)
			end
		end,
	},
	Dropdown = {
		Save = function(obj)
			return {
				__type = obj.__type,
				value = obj.Value,
			}
		end,
		Load = function(element, data)
			if element and element.Select then
				element:Select(data.value)
			end
		end,
	},
	Input = {
		Save = function(obj)
			return {
				__type = obj.__type,
				value = obj.Value,
			}
		end,
		Load = function(element, data)
			if element and element.Set then
				element:Set(data.value)
			end
		end,
	},
	Keybind = {
		Save = function(obj)
			return {
				__type = obj.__type,
				value = obj.Value,
			}
		end,
		Load = function(element, data)
			if element and element.Set then
				element:Set(data.value)
			end
		end,
	},
	Slider = {
		Save = function(obj)
			return {
				__type = obj.__type,
				value = obj.Value.Default,
			}
		end,
		Load = function(element, data)
			if element and element.Set then
				element:Set(tonumber(data.value))
			end
		end,
	},
	Toggle = {
		Save = function(obj)
			return {
				__type = obj.__type,
				value = obj.Value,
			}
		end,
		Load = function(element, data)
			if element and element.Set then
				element:Set(data.value)
			end
		end,
	},
}

local function ensureFolder(path)
	if not isfolder or not makefolder then
		return false
	end

	if not isfolder(path) then
		makefolder(path)
	end

	return true
end

local function cleanConfigName(value)
	value = tostring(value or "")
	value = value:gsub("[%c/:*?\"<>|]", " "):gsub("%s+", " ")
	value = value:match("^%s*(.-)%s*$") or ""
	return value ~= "" and value:sub(1, 96) or nil
end

function ConfigManager:Init(WindowTable)
	if not WindowTable.Folder then
		warn("[ CodexUI.ConfigManager ] Window.Folder is not specified.")
		return false
	end

	if RunService:IsStudio() or not writefile then
		warn("[ CodexUI.ConfigManager ] The config system doesn't work in the studio.")
		return false
	end

	local Manager = setmetatable({
		Window = WindowTable,
		Folder = tostring(WindowTable.Folder),
		Path = "CodexUI/" .. tostring(WindowTable.Folder) .. "/config/",
		Configs = {},
		Parser = ConfigManager.Parser,
	}, { __index = ConfigManager })

	ensureFolder("CodexUI")
	ensureFolder("CodexUI/" .. Manager.Folder)
	ensureFolder(Manager.Path)

	return Manager
end

function ConfigManager:SetPath(customPath)
	if not customPath then
		warn("[ CodexUI.ConfigManager ] Custom path is not specified.")
		return false
	end

	self.Path = tostring(customPath)
	if not self.Path:match("/$") then
		self.Path = self.Path .. "/"
	end

	ensureFolder(self.Path)
	return true
end

function ConfigManager:CreateConfig(configFilename, autoload)
	local Manager = self
	local Window = Manager.Window
	local ConfigName = cleanConfigName(configFilename)

	if not ConfigName then
		return false, "No config file is selected"
	end

	local ConfigModule = {
		Name = ConfigName,
		Path = Manager.Path .. ConfigName .. ".json",
		Elements = {},
		CustomData = {},
		AutoLoad = autoload == true,
		Version = 2,
		Manager = Manager,
	}

	function ConfigModule:SetAsCurrent()
		Window:SetCurrentConfig(ConfigModule)
		return ConfigModule
	end

	function ConfigModule:Register(Name, Element)
		if typeof(Name) == "string" and Name ~= "" and Element then
			ConfigModule.Elements[Name] = Element
		end
		return Element
	end

	function ConfigModule:Unregister(Name, Element)
		if ConfigModule.Elements[Name] == Element or Element == nil then
			ConfigModule.Elements[Name] = nil
		end
	end

	function ConfigModule:Set(key, value)
		ConfigModule.CustomData[key] = value
		return ConfigModule
	end

	function ConfigModule:Get(key)
		return ConfigModule.CustomData[key]
	end

	function ConfigModule:SetAutoLoad(Value)
		ConfigModule.AutoLoad = Value == true
		return ConfigModule
	end

	function ConfigModule:Save()
		if Window.PendingFlags then
			for flag, element in next, Window.PendingFlags do
				ConfigModule:Register(flag, element)
			end
		end

		local saveData = {
			__version = ConfigModule.Version,
			__elements = {},
			__autoload = ConfigModule.AutoLoad,
			__custom = ConfigModule.CustomData,
		}

		-- Preserve values for lazy/unbuilt flagged elements. Live elements overwrite
		-- these entries below so the newest runtime value always wins.
		if Window.PendingConfigData then
			for flag, data in next, Window.PendingConfigData do
				saveData.__elements[tostring(flag)] = data
			end
		end

		for name, element in next, ConfigModule.Elements do
			local parser = Manager.Parser[element.__type]
			if parser then
				saveData.__elements[tostring(name)] = parser.Save(element)
			end
		end

		local success, result = pcall(function()
			writefile(ConfigModule.Path, HttpService:JSONEncode(saveData))
		end)

		if not success then
			return false, tostring(result)
		end

		return saveData
	end

	function ConfigModule:Load()
		if isfile and not isfile(ConfigModule.Path) then
			return false, "Config file does not exist"
		end

		if not readfile then
			return false, "readfile function is not available"
		end

		local success, loadData = pcall(function()
			return HttpService:JSONDecode(readfile(ConfigModule.Path))
		end)

		if not success or typeof(loadData) ~= "table" then
			return false, "Failed to parse config file"
		end

		if not loadData.__version then
			loadData = {
				__version = ConfigModule.Version,
				__elements = loadData,
				__custom = {},
			}
		end

		ConfigModule.AutoLoad = loadData.__autoload == true or ConfigModule.AutoLoad
		ConfigModule.CustomData = loadData.__custom or {}
		Window.PendingConfigData = Window.PendingConfigData or {}

		if Window.PendingFlags then
			for flag, element in next, Window.PendingFlags do
				ConfigModule:Register(flag, element)
			end
		end

		for name, data in next, (loadData.__elements or {}) do
			local element = ConfigModule.Elements[name]
			local parser = data and Manager.Parser[data.__type]

			if element and parser then
				local ok, err = pcall(function()
					parser.Load(element, data)
				end)
				if ok then
					Window.PendingConfigData[name] = nil
				else
					warn("[ CodexUI.ConfigManager ] Failed to load flag '" .. tostring(name) .. "': " .. tostring(err))
				end
			elseif parser then
				-- Lazy tabs can register this flag later. Keep the serialized value
				-- until the actual element is constructed.
				Window.PendingConfigData[name] = data
			end
		end

		return ConfigModule.CustomData
	end

	function ConfigModule:Delete()
		if not delfile then
			return false, "delfile function is not available"
		end

		if isfile and not isfile(ConfigModule.Path) then
			return false, "Config file does not exist"
		end

		local success, err = pcall(function()
			delfile(ConfigModule.Path)
		end)

		if not success then
			return false, "Failed to delete config file: " .. tostring(err)
		end

		Manager.Configs[ConfigName] = nil
		if Window.CurrentConfig == ConfigModule then
			Window.CurrentConfig = nil
		end

		return true, "Config deleted successfully"
	end

	function ConfigModule:GetData()
		return {
			elements = ConfigModule.Elements,
			custom = ConfigModule.CustomData,
			autoload = ConfigModule.AutoLoad,
			name = ConfigModule.Name,
			path = ConfigModule.Path,
		}
	end

	Manager.Configs[ConfigName] = ConfigModule
	ConfigModule:SetAsCurrent()

	local shouldLoad = ConfigModule.AutoLoad
	if isfile and isfile(ConfigModule.Path) and readfile then
		local ok, stored = pcall(function()
			return HttpService:JSONDecode(readfile(ConfigModule.Path))
		end)
		if ok and stored and stored.__autoload then
			ConfigModule.AutoLoad = true
			shouldLoad = true
		end
	end

	if shouldLoad and isfile and isfile(ConfigModule.Path) then
		task.defer(function()
			local ok, result = pcall(function()
				return ConfigModule:Load()
			end)
			if not ok then
				warn("[ CodexUI.ConfigManager ] Failed to AutoLoad config: " .. ConfigName .. " - " .. tostring(result))
			elseif Window.Debug then
				print("[ CodexUI.ConfigManager ] AutoLoaded config: " .. ConfigName)
			end
		end)
	end

	return ConfigModule
end

function ConfigManager:Config(configFilename, autoload)
	return self:CreateConfig(configFilename, autoload)
end

function ConfigManager:GetAutoLoadConfigs()
	local autoloadConfigs = {}
	for configName, configModule in pairs(self.Configs) do
		if configModule.AutoLoad then
			table.insert(autoloadConfigs, configName)
		end
	end
	return autoloadConfigs
end

function ConfigManager:DeleteConfig(configName)
	local existing = self.Configs[configName]
	if existing and existing.Delete then
		return existing:Delete()
	end

	if not delfile then
		return false, "delfile function is not available"
	end

	local cleanName = cleanConfigName(configName)
	if not cleanName then
		return false, "No config file is selected"
	end

	local configPath = self.Path .. cleanName .. ".json"
	if isfile and not isfile(configPath) then
		return false, "Config file does not exist"
	end

	local success, err = pcall(function()
		delfile(configPath)
	end)
	if not success then
		return false, "Failed to delete config file: " .. tostring(err)
	end

	self.Configs[cleanName] = nil
	if self.Window.CurrentConfig and self.Window.CurrentConfig.Path == configPath then
		self.Window.CurrentConfig = nil
	end
	return true, "Config deleted successfully"
end

function ConfigManager:AllConfigs()
	if not listfiles then
		return {}
	end

	local files = {}
	ensureFolder(self.Path)
	for _, file in next, listfiles(self.Path) do
		local name = file:match("([^\\/]+)%.json$")
		if name then
			table.insert(files, name)
		end
	end
	table.sort(files, function(a, b)
		return a:lower() < b:lower()
	end)
	return files
end

function ConfigManager:GetConfig(configName)
	return self.Configs[configName]
end

return ConfigManager
