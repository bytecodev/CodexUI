local CodexUI = {
	Window = nil,
	Theme = nil,
	Creator = require("./modules/Creator"),
	LocalizationModule = require("./modules/Localization"),
	NotificationModule = require("./components/Notification"),
	StandaloneModule = require("./components/Standalone"),
	Themes = nil,
	Transparent = false,

	TransparencyValue = 0.15,

	UIScale = 1,

	ConfigManager = nil,
	Version = "0.0.0",

	Services = require("./utils/services/Init"),

	OnThemeChangeFunction = nil,

	cloneref = nil,
	UIScaleObj = nil,

	CreateWindow = nil,

	CurrentInput = nil,
}

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

CodexUI.cloneref = cloneref

local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

function CodexUI.GenerateGUID()
	return HttpService:GenerateGUID(false)
end

local CurInput = CodexUI.GenerateGUID()

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	--[[if GameProcessed then
		return
	end]]

	task.defer(function()
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			if CodexUI.CurrentInput and CodexUI.CurrentInput ~= CurInput then
				return
			end

			CodexUI.CurrentInput = CurInput
			--print(CurInput)
			--CodexUI.InputStartedOnUI = false
		end
	end)
end)
UserInputService.InputEnded:Connect(function(Input, GameProcessed)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		if CodexUI.CurrentInput and CodexUI.CurrentInput ~= CurInput then
			return
		end

		CodexUI.CurrentInput = nil
	end
end)

local LocalPlayer = Players.LocalPlayer or nil

local Package = HttpService:JSONDecode(require("../build/package"))
if Package then
	CodexUI.Version = Package.version
end

local KeySystem = require("./components/KeySystem")

local Creator = CodexUI.Creator

local New = Creator.New

--local Tween = Creator.Tween
--local ServicesModule = CodexUI.Services

local Acrylic = require("./utils/Acrylic/Init")

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local GUIParent = gethui and gethui() or (CoreGui or LocalPlayer:WaitForChild("PlayerGui"))

local UIScaleObj = New("UIScale", {
	Scale = CodexUI.UIScale,
})

CodexUI.UIScaleObj = UIScaleObj

CodexUI.ScreenGui = New("ScreenGui", {
	Name = "CodexUI",
	Parent = GUIParent,
	IgnoreGuiInset = true,
	ScreenInsets = "None",
	DisplayOrder = -99999,
}, {

	New("Folder", {
		Name = "Window",
	}),
	-- New("Folder", {
	--     Name = "Notifications"
	-- }),
	-- New("Folder", {
	--     Name = "Dropdowns"
	-- }),
	New("Folder", {
		Name = "KeySystem",
	}),
	New("Folder", {
		Name = "Popups",
	}),
	New("Folder", {
		Name = "ToolTips",
	}),
})

CodexUI.NotificationGui = New("ScreenGui", {
	Name = "CodexUI/Notifications",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
CodexUI.DropdownGui = New("ScreenGui", {
	Name = "CodexUI/Dropdowns",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
CodexUI.TooltipGui = New("ScreenGui", {
	Name = "CodexUI/Tooltips",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
CodexUI.StandaloneGui = New("ScreenGui", {
	Name = "CodexUI/Standalone",
	Parent = GUIParent,
	IgnoreGuiInset = true,
	ScreenInsets = "None",
	DisplayOrder = 999999,
})
ProtectGui(CodexUI.ScreenGui)
ProtectGui(CodexUI.NotificationGui)
ProtectGui(CodexUI.DropdownGui)
ProtectGui(CodexUI.TooltipGui)
ProtectGui(CodexUI.StandaloneGui)

Creator.Init(CodexUI)

function CodexUI:SetParent(parent)
	if CodexUI.ScreenGui then
		CodexUI.ScreenGui.Parent = parent
	end
	if CodexUI.NotificationGui then
		CodexUI.NotificationGui.Parent = parent
	end
	if CodexUI.DropdownGui then
		CodexUI.DropdownGui.Parent = parent
	end
	if CodexUI.TooltipGui then
		CodexUI.TooltipGui.Parent = parent
	end
	if CodexUI.StandaloneGui then
		CodexUI.StandaloneGui.Parent = parent
	end
end
math.clamp(CodexUI.TransparencyValue, 0, 1)

local Holder = CodexUI.NotificationModule.Init(CodexUI.NotificationGui)
local Standalone = CodexUI.StandaloneModule.Init(CodexUI, CodexUI.StandaloneGui)

function CodexUI:Notify(Config)
	Config.Holder = Holder.Frame
	Config.Window = CodexUI.Window
	--Config.CodexUI = CodexUI
	return CodexUI.NotificationModule.New(Config)
end

function CodexUI:SetNotificationLower(Val)
	Holder.SetLower(Val)
end

function CodexUI:Loading(Config)
	return Standalone:Loading(Config)
end

function CodexUI:Info(Config)
	return Standalone:Info(Config)
end

function CodexUI:Announcement(Config)
	return Standalone:Announcement(Config)
end

function CodexUI:Limit(Config)
	return Standalone:Limit(Config)
end

function CodexUI:CloseStandalone(Id)
	return Standalone:Close(Id)
end

function CodexUI:CloseAllStandalone(Immediate)
	return Standalone:CloseAll(Immediate)
end

function CodexUI:SetFont(FontId)
	Creator.UpdateFont(FontId)
end

function CodexUI:OnThemeChange(func)
	CodexUI.OnThemeChangeFunction = func
end

function CodexUI:AddTheme(LTheme)
	CodexUI.Themes[LTheme.Name] = LTheme
	return LTheme
end

function CodexUI:EditTheme(Name, Changes)
	if typeof(Name) == "table" and Changes == nil then
		Changes = Name
		Name = CodexUI.Theme and CodexUI.Theme.Name
	end
	if typeof(Name) ~= "string" or typeof(Changes) ~= "table" then
		return nil
	end
	local Theme = CodexUI.Themes and CodexUI.Themes[Name]
	if not Theme then
		return nil
	end
	for Key, Value in pairs(Changes) do
		if Key ~= "Name" then
			Theme[Key] = Value
		end
	end
	if CodexUI.Theme == Theme or (CodexUI.Theme and CodexUI.Theme.Name == Name) then
		CodexUI.Theme = Theme
		Creator.SetTheme(Theme)
		if CodexUI.OnThemeChangeFunction then
			CodexUI.OnThemeChangeFunction(Name)
		end
	end
	return Theme
end

function CodexUI:SetTheme(Value)
	if CodexUI.Themes[Value] then
		CodexUI.Theme = CodexUI.Themes[Value]
		Creator.SetTheme(CodexUI.Themes[Value])

		if CodexUI.OnThemeChangeFunction then
			CodexUI.OnThemeChangeFunction(Value)
		end

		return CodexUI.Themes[Value]
	end
	return nil
end

function CodexUI:GetThemes()
	return CodexUI.Themes
end
function CodexUI:GetCurrentTheme()
	return CodexUI.Theme.Name
end
function CodexUI:GetTransparency()
	return CodexUI.Transparent or false
end
function CodexUI:GetWindowSize()
	return CodexUI.Window.UIElements.Main.Size
end
function CodexUI:Localization(LocalizationConfig)
	return CodexUI.LocalizationModule:New(LocalizationConfig, Creator)
end

function CodexUI:SetLanguage(Value)
	if Creator.Localization then
		return Creator.SetLanguage(Value)
	end
	return false
end

function CodexUI:ToggleAcrylic(Value)
	if CodexUI.Window and CodexUI.Window.AcrylicPaint and CodexUI.Window.AcrylicPaint.Model then
		CodexUI.Window.Acrylic = Value
		CodexUI.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable()
		else
			Acrylic.Disable()
		end
	end
end

function CodexUI:Gradient(stops, props)
	local colorSequence = {}
	local transparencySequence = {}

	for posStr, stop in next, stops do
		local position = tonumber(posStr)
		if position then
			position = math.clamp(position / 100, 0, 1)

			local color = stop.Color
			if typeof(color) == "string" and string.sub(color, 1, 1) == "#" then
				color = Color3.fromHex(color)
			end

			local transparency = stop.Transparency or 0

			table.insert(colorSequence, ColorSequenceKeypoint.new(position, color))
			table.insert(transparencySequence, NumberSequenceKeypoint.new(position, transparency))
		end
	end

	table.sort(colorSequence, function(a, b)
		return a.Time < b.Time
	end)
	table.sort(transparencySequence, function(a, b)
		return a.Time < b.Time
	end)

	if #colorSequence < 2 then
		table.insert(colorSequence, ColorSequenceKeypoint.new(1, colorSequence[1].Value))
		table.insert(transparencySequence, NumberSequenceKeypoint.new(1, transparencySequence[1].Value))
	end

	local gradientData = {
		Color = ColorSequence.new(colorSequence),
		Transparency = NumberSequence.new(transparencySequence),
	}

	if props then
		for k, v in pairs(props) do
			gradientData[k] = v
		end
	end

	return gradientData
end

function CodexUI:Popup(PopupConfig)
	PopupConfig.CodexUI = CodexUI
	return require("./components/popup/Init").new(PopupConfig, CodexUI.ScreenGui.Popups)
end

CodexUI.Themes = require("./themes/Init")(CodexUI, Creator)

Creator.Themes = CodexUI.Themes

CodexUI:SetTheme("Dark")
CodexUI:SetLanguage(Creator.Language)

function CodexUI:CreateWindow(Config)
	local CreateWindow = require("./components/window/Init")

	if not RunService:IsStudio() and writefile then
		if not isfolder("CodexUI") then
			makefolder("CodexUI")
		end
		if Config.Folder then
			makefolder(Config.Folder)
		else
			makefolder(Config.Title)
		end
	end

	Config.CodexUI = CodexUI
	Config.Window = CodexUI.Window
	Config.Parent = CodexUI.ScreenGui.Window

	if CodexUI.Window then
		warn("You cannot create more than one window")
		return
	end

	local CanLoadWindow = true

	local Theme = CodexUI.Themes[Config.Theme or "Dark"]

	--CodexUI.Theme = Theme
	Creator.SetTheme(Theme)

	local hwid = gethwid or function()
		return Players.LocalPlayer.UserId
	end

	local Filename = hwid()

	if Config.KeySystem then
		CanLoadWindow = false

		local function loadKeysystem()
			KeySystem.new(Config, Filename, function(c)
				CanLoadWindow = c
			end)
		end

		local keyPath = (Config.Folder or "Temp") .. "/" .. Filename .. ".key"

		if Config.KeySystem.KeyValidator then
			if Config.KeySystem.SaveKey and isfile(keyPath) then
				local savedKey = readfile(keyPath)
				local isValid = Config.KeySystem.KeyValidator(savedKey)

				if isValid then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		elseif not Config.KeySystem.API then
			if Config.KeySystem.SaveKey and isfile(keyPath) then
				local savedKey = readfile(keyPath)
				local isKey = (type(Config.KeySystem.Key) == "table") and table.find(Config.KeySystem.Key, savedKey)
					or tostring(Config.KeySystem.Key) == tostring(savedKey)

				if isKey then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		else
			if isfile(keyPath) then
				local fileKey = readfile(keyPath)
				local isSuccess = false

				for _, i in next, Config.KeySystem.API do
					local serviceData = CodexUI.Services[i.Type]
					if serviceData then
						local args = {}
						for _, argName in next, serviceData.Args do
							table.insert(args, i[argName])
						end

						local service = serviceData.New(table.unpack(args))
						local success = service.Verify(fileKey)
						if success then
							isSuccess = true
							break
						end
					end
				end

				CanLoadWindow = isSuccess
				if not isSuccess then
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		end

		repeat
			task.wait()
		until CanLoadWindow
	end

	local Window = CreateWindow(Config)

	CodexUI.Transparent = Config.Transparent
	CodexUI.Window = Window

	if Config.Acrylic then
		Acrylic.init()
	end

	-- function Window:ToggleTransparency(Value)
	--     CodexUI.Transparent = Value
	--     CodexUI.Window.Transparent = Value

	--     Window.UIElements.Main.Background.BackgroundTransparency = Value and CodexUI.TransparencyValue or 0
	--     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and CodexUI.TransparencyValue or 0
	--     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
	--         NumberSequenceKeypoint.new(0, 1),
	--         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
	--     }
	-- end

	return Window
end

return CodexUI
