local Creator = require("../modules/Creator")

local New = Creator.New
local Tween = Creator.Tween
local RunService = game:GetService("RunService")

local Standalone = {
	Parent = nil,
	CodexUI = nil,
	Active = {},
	Index = 0,
}

local function disconnect(Connection)
	if Connection then
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

local function unregisterThemeObjects(Root)
	if not Root then
		return
	end
	for Object in pairs(Creator.Objects) do
		local IsOwned = Object == Root
		if not IsOwned then
			local Ok, Result = pcall(function()
				return Object:IsDescendantOf(Root)
			end)
			IsOwned = Ok and Result
		end
		if IsOwned then
			Creator.Objects[Object] = nil
		end
	end
end

local function normalizeProgress(Value)
	Value = tonumber(Value)
	if not Value then
		return nil
	end
	if Value > 1 then
		Value = Value / 100
	end
	return math.clamp(Value, 0, 1)
end

local function normalizeExpiry(Value)
	Value = tonumber(Value)
	if not Value then
		return nil
	end
	if Value > 100000000000 then
		Value = Value / 1000
	end
	return Value
end

local function formatTimeLeft(ExpiresAt)
	local Remaining = math.max(0, math.ceil(ExpiresAt - os.time()))
	local Days = math.floor(Remaining / 86400)
	local Hours = math.floor((Remaining % 86400) / 3600)
	local Minutes = math.floor((Remaining % 3600) / 60)
	local Seconds = Remaining % 60
	if Days > 0 then
		return string.format("%dd %dh %dm left", Days, Hours, Minutes)
	end
	if Hours > 0 then
		return string.format("%dh %dm %ds left", Hours, Minutes, Seconds)
	end
	return string.format("%dm %ds left", Minutes, Seconds)
end

local function createIcon(Icon, Size)
	if not Icon or Icon == "" then
		return nil
	end
	local Ok, IconFrame = pcall(function()
		return Creator.Image(Icon, "Standalone:" .. tostring(Icon), 0, "Standalone", "Standalone", true, true)
	end)
	if not Ok or not IconFrame then
		return nil
	end
	IconFrame.Size = UDim2.fromOffset(Size, Size)
	return IconFrame
end

local function createLabel(Text, Size, Weight, Color, Transparency)
	return New("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(Text or ""),
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = Size,
		TextTransparency = Transparency or 0,
		FontFace = Font.new(Creator.Font, Weight or Enum.FontWeight.Medium),
		ThemeTag = {
			TextColor3 = Color or "Text",
		},
	})
end

local function createButton(Config, Parent, Controller)
	Config = Config or {}
	local Button = New("TextButton", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 38),
		BackgroundTransparency = 0,
		Text = tostring(Config.Title or Config.Text or "Okay"),
		TextSize = 15,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		ThemeTag = Config.Color and {
			TextColor3 = "White",
		} or {
			BackgroundColor3 = Config.Primary == false and "ElementBackground" or "Primary",
			TextColor3 = Config.Primary == false and "Text" or "White",
		},
		Parent = Parent,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}),
	})
	if Config.Color then
		Button.BackgroundColor3 = Config.Color
		Button.TextColor3 = Config.TextColor or Color3.new(1, 1, 1)
	end
	local Connection = Button.MouseButton1Click:Connect(function()
		if Config.Close ~= false then
			Controller:Close()
		end
		Creator.SafeCallback(Config.Callback, Controller)
	end)
	Controller:_Track(Connection)
	return Button
end

local function createSurface(Config, Kind)
	Config = Config or {}
	Standalone.Index = Standalone.Index + 1
	local Id = tostring(Config.Id or (Kind == "Loading" and "loading" or "info"))
	local Existing = Standalone.Active[Id]
	if Existing and Config.Replace ~= false then
		Existing:Close(true)
	elseif Existing then
		Id = Id .. ":" .. tostring(Standalone.Index)
	end

	local Controller = {
		Id = Id,
		Kind = Kind,
		Closed = false,
		Connections = {},
		UIElements = {},
		Metrics = {},
	}

	function Controller:_Track(Connection)
		if Connection then
			table.insert(self.Connections, Connection)
		end
		return Connection
	end

	local BaseZIndex = 100 + Standalone.Index * 10
	local Overlay = New("Frame", {
		Name = "Standalone_" .. Kind .. "_" .. Id,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Active = Config.Modal ~= false,
		ZIndex = BaseZIndex,
		Parent = Standalone.Parent,
	})
	local Card = New("Frame", {
		Name = "Card",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -32, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0,
		ThemeTag = {
			BackgroundColor3 = "Background",
		},
		ZIndex = BaseZIndex + 1,
		Parent = Overlay,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 18),
		}),
		New("UIStroke", {
			Thickness = 1,
			Transparency = 0.72,
			ThemeTag = {
				Color = "Outline",
			},
		}),
		New("UISizeConstraint", {
			MinSize = Vector2.new(280, 0),
			MaxSize = Vector2.new(480, 1000),
		}),
		New("UIScale", {
			Name = "OpenScale",
			Scale = 0.94,
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 14),
		}),
	})

	Controller.UIElements.Overlay = Overlay
	Controller.UIElements.Card = Card
	Standalone.Active[Id] = Controller

	function Controller:Close(Immediate)
		if self.Closed then
			return self
		end
		self.Closed = true
		if Standalone.Active[self.Id] == self then
			Standalone.Active[self.Id] = nil
		end
		for Index = #self.Connections, 1, -1 do
			disconnect(table.remove(self.Connections, Index))
		end
		local function Destroy()
			if Overlay then
				unregisterThemeObjects(Overlay)
				Overlay:Destroy()
			end
		end
		if Immediate then
			Destroy()
		else
			Overlay.Active = false
			Tween(Overlay, 0.14, { BackgroundTransparency = 1 }):Play()
			Tween(Card.OpenScale, 0.14, { Scale = 0.94 }):Play()
			task.delay(0.15, Destroy)
		end
		Creator.SafeCallback(Config.OnClose, self)
		return self
	end

	function Controller:Destroy()
		return self:Close(true)
	end

	Tween(Overlay, 0.16, {
		BackgroundTransparency = Config.Modal == false and 1 or (Config.OverlayTransparency or 0.38),
	}):Play()
	Tween(Card.OpenScale, 0.18, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

	return Controller, Card, BaseZIndex
end

local function addHeader(Controller, Card, Config, BaseZIndex)
	local IconSize = tonumber(Config.IconSize) or 28
	local Header = New("Frame", {
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = BaseZIndex + 2,
		Parent = Card,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 12),
		}),
	})
	local Icon = createIcon(Config.Icon, IconSize)
	if Icon then
		Icon.Parent = Header
	end
	local Texts = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(
			1,
			-(Icon and IconSize + 12 or 0) - (Config.CanClose and 40 or 0),
			0,
			0
		),
		BackgroundTransparency = 1,
		Parent = Header,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 3),
		}),
	})
	local Title = createLabel(Config.Title or "CodexUI", 20, Enum.FontWeight.SemiBold, "Text")
	Title.Parent = Texts
	local Subtitle
	if Config.Subtitle and Config.Subtitle ~= "" then
		Subtitle = createLabel(Config.Subtitle, 13, Enum.FontWeight.Medium, "Placeholder")
		Subtitle.Parent = Texts
	end
	Controller.UIElements.Header = Header
	Controller.UIElements.Icon = Icon
	Controller.UIElements.Title = Title
	Controller.UIElements.Subtitle = Subtitle

	function Controller:SetTitle(Value)
		Title.Text = tostring(Value or "")
		return self
	end

	if Config.CanClose then
		local Close = New("TextButton", {
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1,
			Text = "×",
			TextSize = 24,
			ThemeTag = { TextColor3 = "Placeholder" },
			ZIndex = BaseZIndex + 4,
			Parent = Header,
		})
		Controller:_Track(Close.MouseButton1Click:Connect(function()
			Controller:Close()
		end))
		Controller.UIElements.Close = Close
	end

	return Title
end

function Standalone:Loading(Config)
	Config = Config or {}
	Config.CanClose = Config.CanClose == true
	local Controller, Card, BaseZIndex = createSurface(Config, "Loading")
	addHeader(Controller, Card, Config, BaseZIndex)

	local Status = createLabel(Config.Content or Config.Status or "Loading...", 15, Enum.FontWeight.Medium, "Placeholder")
	Status.LayoutOrder = 2
	Status.Parent = Card

	local Track = New("Frame", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 7),
		ClipsDescendants = true,
		ThemeTag = { BackgroundColor3 = "ElementBackground" },
		Parent = Card,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local Fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 0,
		ThemeTag = { BackgroundColor3 = "Primary" },
		Parent = Track,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local Detail = createLabel(Config.Detail or "", 12, Enum.FontWeight.Medium, "Placeholder", 0.15)
	Detail.LayoutOrder = 4
	Detail.Visible = Config.Detail ~= nil and Config.Detail ~= ""
	Detail.Parent = Card

	Controller.UIElements.Status = Status
	Controller.UIElements.ProgressTrack = Track
	Controller.UIElements.Progress = Fill
	Controller.UIElements.Detail = Detail
	Controller.ProgressGeneration = 0

	function Controller:SetStatus(Value, NewDetail)
		Status.Text = tostring(Value or "")
		if NewDetail ~= nil then
			self:SetDetail(NewDetail)
		end
		return self
	end

	function Controller:SetContent(Value)
		return self:SetStatus(Value)
	end

	function Controller:SetDetail(Value)
		Detail.Text = tostring(Value or "")
		Detail.Visible = Detail.Text ~= ""
		return self
	end

	function Controller:SetProgress(Value, NewStatus)
		if NewStatus ~= nil then
			self:SetStatus(NewStatus)
		end
		self.ProgressGeneration = self.ProgressGeneration + 1
		local Progress = normalizeProgress(Value)
		if Progress == nil then
			local Generation = self.ProgressGeneration
			task.spawn(function()
				while not self.Closed and Generation == self.ProgressGeneration do
					Fill.Position = UDim2.fromScale(-0.35, 0)
					Fill.Size = UDim2.fromScale(0.35, 1)
					local Motion = Tween(Fill, 0.75, {
						Position = UDim2.fromScale(1, 0),
					}, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
					Motion:Play()
					task.wait(0.78)
				end
			end)
		else
			Fill.Position = UDim2.fromScale(0, 0)
			Tween(Fill, 0.18, { Size = UDim2.fromScale(Progress, 1) }):Play()
		end
		return self
	end

	function Controller:SetStep(Current, Total, NewStatus)
		Current = tonumber(Current) or 0
		Total = math.max(1, tonumber(Total) or 1)
		self:SetProgress(Current / Total, NewStatus)
		self:SetDetail(string.format("%d / %d", Current, Total))
		return self
	end

	function Controller:Complete(Message, Delay)
		self:SetProgress(1, Message or "Complete")
		task.delay(tonumber(Delay) or 0.35, function()
			if not self.Closed then
				self:Close()
			end
		end)
		return self
	end

	Controller:SetProgress(Config.Progress)
	return Controller
end

local function clearMetrics(Controller, Container)
	for _, Child in ipairs(Container:GetChildren()) do
		if not Child:IsA("UIListLayout") then
			unregisterThemeObjects(Child)
			Child:Destroy()
		end
	end
	Controller.Metrics = {}
end

local function addMetric(Controller, Container, Metric, Index)
	Metric = Metric or {}
	local Id = tostring(Metric.Id or Metric.Label or Index)
	local Progress = normalizeProgress(Metric.Progress)
	local Row = New("Frame", {
		LayoutOrder = Index,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = Container,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 7),
		}),
	})
	local Header = New("Frame", {
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Parent = Row,
	})
	local Label = createLabel(Metric.Label or Id, 13, Enum.FontWeight.Medium, "Placeholder")
	Label.AutomaticSize = Enum.AutomaticSize.None
	Label.Size = UDim2.new(0.65, 0, 1, 0)
	Label.Parent = Header
	local Value = createLabel(Metric.Value or "", 13, Enum.FontWeight.SemiBold, "Text")
	Value.AutomaticSize = Enum.AutomaticSize.None
	Value.Size = UDim2.new(0.35, 0, 1, 0)
	Value.Position = UDim2.fromScale(0.65, 0)
	Value.TextXAlignment = Enum.TextXAlignment.Right
	Value.Parent = Header
	local Track = New("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Visible = Progress ~= nil,
		ClipsDescendants = true,
		ThemeTag = { BackgroundColor3 = "ElementBackground" },
		Parent = Row,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local Fill = New("Frame", {
		Size = UDim2.fromScale(Progress or 0, 1),
		ThemeTag = { BackgroundColor3 = "Primary" },
		Parent = Track,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	Controller.Metrics[Id] = {
		Row = Row,
		Label = Label,
		Value = Value,
		Track = Track,
		Fill = Fill,
	}
	return Controller.Metrics[Id]
end

function Standalone:Info(Config)
	Config = Config or {}
	Config.CanClose = Config.CanClose ~= false
	local Controller, Card, BaseZIndex = createSurface(Config, "Info")
	addHeader(Controller, Card, Config, BaseZIndex)

	local ContentTemplate = tostring(Config.Content or Config.Message or "")
	local Content = createLabel(ContentTemplate, 15, Enum.FontWeight.Medium, "Text", 0.12)
	Content.LayoutOrder = 2
	Content.Visible = ContentTemplate ~= ""
	Content.Parent = Card

	local Metrics = New("Frame", {
		LayoutOrder = 3,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = Card,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local Footer = createLabel(Config.Footer or "", 12, Enum.FontWeight.Medium, "Placeholder", 0.12)
	Footer.LayoutOrder = 4
	Footer.Visible = Config.Footer ~= nil and Config.Footer ~= ""
	Footer.Parent = Card

	local Buttons = New("Frame", {
		LayoutOrder = 5,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Visible = type(Config.Buttons) == "table" and #Config.Buttons > 0,
		Parent = Card,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
		}),
	})

	Controller.UIElements.Content = Content
	Controller.UIElements.Metrics = Metrics
	Controller.UIElements.Footer = Footer
	Controller.UIElements.Buttons = Buttons
	Controller.ExpiresAt = normalizeExpiry(Config.ExpiresAt)
	Controller.ContentTemplate = ContentTemplate

	function Controller:SetContent(Value)
		self.ContentTemplate = tostring(Value or "")
		Content.Visible = self.ContentTemplate ~= ""
		Content.Text = self.ContentTemplate
		return self
	end

	function Controller:SetFooter(Value)
		Footer.Text = tostring(Value or "")
		Footer.Visible = Footer.Text ~= ""
		return self
	end

	function Controller:SetMetrics(Values)
		clearMetrics(self, Metrics)
		for Index, Metric in ipairs(type(Values) == "table" and Values or {}) do
			addMetric(self, Metrics, Metric, Index)
		end
		Metrics.Visible = next(self.Metrics) ~= nil
		return self
	end

	function Controller:SetMetric(Id, Value, Progress)
		Id = tostring(Id)
		local Metric = self.Metrics[Id]
		if not Metric then
			Metric = addMetric(self, Metrics, {
				Id = Id,
				Label = Id,
				Value = Value,
				Progress = Progress,
			}, #Metrics:GetChildren())
		end
		Metric.Value.Text = tostring(Value or "")
		local Normalized = normalizeProgress(Progress)
		Metric.Track.Visible = Normalized ~= nil
		if Normalized then
			Tween(Metric.Fill, 0.18, { Size = UDim2.fromScale(Normalized, 1) }):Play()
		end
		Metrics.Visible = true
		return self
	end

	Controller:SetMetrics(Config.Metrics)
	for _, ButtonConfig in ipairs(type(Config.Buttons) == "table" and Config.Buttons or {}) do
		createButton(ButtonConfig, Buttons, Controller)
	end

	if Controller.ExpiresAt then
		local LastSecond
		local function UpdateCountdown()
			local CurrentSecond = os.time()
			if CurrentSecond == LastSecond then
				return
			end
			LastSecond = CurrentSecond
			Content.Text = string.gsub(Controller.ContentTemplate, "{TIME_LEFT}", formatTimeLeft(Controller.ExpiresAt))
		end
		UpdateCountdown()
		Controller:_Track(RunService.Heartbeat:Connect(UpdateCountdown))
	end

	return Controller
end

function Standalone:Announcement(Config)
	Config = Config or {}
	local Passed = {}
	for Key, Value in pairs(Config) do
		Passed[Key] = Value
	end
	Passed.Id = Passed.Id or "announcement"
	Passed.Title = Passed.Title or "Announcement"
	Passed.Subtitle = Passed.Subtitle or (Passed.Author and ("by " .. tostring(Passed.Author)) or nil)
	Passed.Icon = Passed.Icon or "megaphone"
	Passed.Content = Passed.Content or Passed.Message
	return self:Info(Passed)
end

local function appendLimitMetric(Metrics, Id, Label, Data)
	if type(Data) ~= "table" then
		return
	end
	local Used = tonumber(Data.Used or Data.Current or Data.Value) or 0
	local Limit = tonumber(Data.Limit or Data.Max or Data.Total)
	local Value = Data.Text or (Limit and string.format("%d / %d", Used, Limit) or tostring(Used))
	table.insert(Metrics, {
		Id = Id,
		Label = Data.Label or Label,
		Value = Value,
		Progress = Limit and Limit > 0 and Used / Limit or Data.Progress,
	})
end

function Standalone:Limit(Config)
	Config = Config or {}
	local Passed = {}
	for Key, Value in pairs(Config) do
		Passed[Key] = Value
	end
	local Metrics = {}
	for _, Metric in ipairs(type(Config.Metrics) == "table" and Config.Metrics or {}) do
		table.insert(Metrics, Metric)
	end
	appendLimitMetric(Metrics, "daily", "Daily limit", Config.Daily)
	appendLimitMetric(Metrics, "weekly", "Weekly limit", Config.Weekly)
	Passed.Id = Passed.Id or "limits"
	Passed.Title = Passed.Title or "Usage limits"
	Passed.Icon = Passed.Icon or "chart-no-axes-column-increasing"
	Passed.Metrics = Metrics
	return self:Info(Passed)
end

function Standalone:Close(Id)
	local Controller = self.Active[tostring(Id)]
	if Controller then
		Controller:Close()
	end
	return Controller
end

function Standalone:CloseAll(Immediate)
	local Controllers = {}
	for _, Controller in pairs(self.Active) do
		table.insert(Controllers, Controller)
	end
	for _, Controller in ipairs(Controllers) do
		Controller:Close(Immediate)
	end
end

function Standalone.Init(CodexUI, Parent)
	Standalone.CodexUI = CodexUI
	Standalone.Parent = Parent
	return Standalone
end

return Standalone
