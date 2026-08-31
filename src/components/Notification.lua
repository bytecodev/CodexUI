local Creator = require("../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local NotificationModule = {
	Size = UDim2.new(0, 300, 1, -100 - 56),
	SizeLower = UDim2.new(0, 300, 1, -56),
	UICorner = 18,
	UIPadding = 14,
	Holder = nil,
	NotificationIndex = 0,
	Notifications = {},
	ById = {},
	Queue = {},
	QueueActive = nil,
}

local StartNextQueued

function NotificationModule.Init(Parent)
	local NotModule = {
		Lower = false,
	}

	function NotModule.SetLower(val)
		NotModule.Lower = val
		NotModule.Frame.Size = val and NotificationModule.SizeLower or NotificationModule.Size
	end

	NotModule.Frame = New("Frame", {
		Position = UDim2.new(1, -116 / 4, 0, 56),
		AnchorPoint = Vector2.new(1, 0),
		Size = NotificationModule.Size,
		Parent = Parent,
		BackgroundTransparency = 1,
	}, {
		New("UIListLayout", {
			HorizontalAlignment = "Center",
			SortOrder = "LayoutOrder",
			VerticalAlignment = "Bottom",
			Padding = UDim.new(0, 8),
		}),
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 116 / 4),
		}),
	})
	return NotModule
end

function NotificationModule.New(Config, QueueStarted)
	Config = Config or {}

	local Id = Config.Id and tostring(Config.Id) or nil
	if Id and Config.Replace then
		local Existing = NotificationModule.ById[Id]
		if Existing and not Existing.Closed and Existing.Update then
			Existing:Update(Config)
			return Existing
		end
	end

	if Config.Queue == true and not QueueStarted then
		if NotificationModule.QueueActive and not NotificationModule.QueueActive.Closed then
			local QueueEntry = {
				Config = Config,
				Cancelled = false,
				Queued = true,
				Id = Id,
			}

			function QueueEntry:Close()
				QueueEntry.Cancelled = true
			end

			table.insert(NotificationModule.Queue, QueueEntry)
			return QueueEntry
		end

	end

	local Notification = {
		Id = Id,
		Title = Config.Title or "Notification",
		Content = Config.Content or nil,
		Icon = Config.Icon or nil,
		IconThemed = Config.IconThemed,
		Background = Config.Background,
		BackgroundImageTransparency = Config.BackgroundImageTransparency,
		Duration = Config.Duration == nil and 5 or Config.Duration,
		Buttons = Config.Buttons or {},
		CanClose = Config.CanClose ~= false,
		Queued = Config.Queue == true,
		UIElements = {},
		Closed = false,
		TimerGeneration = 0,
	}

	NotificationModule.NotificationIndex = NotificationModule.NotificationIndex + 1
	Notification.Index = NotificationModule.NotificationIndex
	NotificationModule.Notifications[Notification.Index] = Notification

	if Notification.Id then
		NotificationModule.ById[Notification.Id] = Notification
	end
	if Notification.Queued then
		NotificationModule.QueueActive = Notification
	end

	local Icon
	if Notification.Icon then
		Icon = Creator.Image(
			Notification.Icon,
			Notification.Title .. ":" .. Notification.Icon,
			0,
			Config.Window,
			"Notification",
			Notification.IconThemed
		)
		Icon.Size = UDim2.new(0, 26, 0, 26)
		Icon.Position = UDim2.new(0, NotificationModule.UIPadding, 0, NotificationModule.UIPadding)
	end

	local CloseButton
	if Notification.CanClose then
		CloseButton = New("ImageButton", {
			Image = Creator.Icon("x")[1],
			ImageRectSize = Creator.Icon("x")[2].ImageRectSize,
			ImageRectOffset = Creator.Icon("x")[2].ImageRectPosition,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(1, -NotificationModule.UIPadding, 0, NotificationModule.UIPadding),
			AnchorPoint = Vector2.new(1, 0),
			ThemeTag = {
				ImageColor3 = "Text",
			},
			ImageTransparency = 0.4,
		}, {
			New("TextButton", {
				Size = UDim2.new(1, 8, 1, 8),
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Text = "",
			}),
		})
	end

	local Duration = Creator.NewRoundFrame(NotificationModule.UICorner, "Squircle", {
		Size = UDim2.new(0, 0, 1, 0),
		ThemeTag = {
			ImageTransparency = "NotificationDurationTransparency",
			ImageColor3 = "NotificationDuration",
		},
	})

	local TitleLabel = New("TextLabel", {
		AutomaticSize = "Y",
		Size = UDim2.new(1, -30 - NotificationModule.UIPadding, 0, 0),
		TextWrapped = true,
		TextXAlignment = "Left",
		RichText = true,
		BackgroundTransparency = 1,
		TextSize = 18,
		ThemeTag = {
			TextColor3 = "NotificationTitle",
			TextTransparency = "NotificationTitleTransparency",
		},
		Text = Notification.Title,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
	})

	local TextContainer = New("Frame", {
		Size = UDim2.new(1, Notification.Icon and -28 - NotificationModule.UIPadding or 0, 1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		AutomaticSize = "Y",
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, NotificationModule.UIPadding),
			PaddingLeft = UDim.new(0, NotificationModule.UIPadding),
			PaddingRight = UDim.new(0, NotificationModule.UIPadding),
			PaddingBottom = UDim.new(0, NotificationModule.UIPadding),
		}),
		TitleLabel,
		New("UIListLayout", {
			Padding = UDim.new(0, NotificationModule.UIPadding / 3),
		}),
	})

	local ContentLabel
	local function SetContent(Content)
		Notification.Content = Content
		if Content == nil or tostring(Content) == "" then
			if ContentLabel then
				ContentLabel:Destroy()
				ContentLabel = nil
			end
			Notification.UIElements.Content = nil
			return
		end

		if not ContentLabel then
			ContentLabel = New("TextLabel", {
				AutomaticSize = "Y",
				Size = UDim2.new(1, 0, 0, 0),
				TextWrapped = true,
				TextXAlignment = "Left",
				RichText = true,
				BackgroundTransparency = 1,
				TextSize = 15,
				ThemeTag = {
					TextColor3 = "NotificationContent",
					TextTransparency = "NotificationContentTransparency",
				},
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				Parent = TextContainer,
			})
		end
		ContentLabel.Text = tostring(Content)
		Notification.UIElements.Content = ContentLabel
	end

	SetContent(Notification.Content)

	local Main = Creator.NewRoundFrame(NotificationModule.UICorner, "Squircle", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(2, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		AutomaticSize = "Y",
		ImageTransparency = 0.05,
		ThemeTag = {
			ImageColor3 = "Notification",
		},
	}, {
		Creator.NewRoundFrame(NotificationModule.UICorner, "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			ThemeTag = {
				ImageColor3 = "Notification2",
				ImageTransparency = "Notification2Transparency",
			},
		}),
		New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Name = "DurationFrame",
		}, {
			New("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
			}, {
				Duration,
			}),
		}),
		New("ImageLabel", {
			Name = "Background",
			Image = Notification.Background,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ScaleType = "Crop",
			ImageTransparency = Notification.BackgroundImageTransparency,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, NotificationModule.UICorner),
			}),
		}),
		TextContainer,
		Icon,
		CloseButton,
	})

	local MainContainer = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = Config.Holder,
	}, {
		Main,
	})

	Notification.UIElements.Main = Main
	Notification.UIElements.Container = MainContainer
	Notification.UIElements.Title = TitleLabel
	Notification.UIElements.Content = ContentLabel

	function Notification:_StartDurationTimer()
		Notification.TimerGeneration = Notification.TimerGeneration + 1
		local Generation = Notification.TimerGeneration

		if not Notification.Duration or tonumber(Notification.Duration) == nil or Notification.Duration <= 0 then
			return
		end

		task.spawn(function()
			task.wait()
			if Notification.Closed or Generation ~= Notification.TimerGeneration then
				return
			end

			Main.DurationFrame.Frame.Size = UDim2.new(1, 0, 1, 0)
			Duration.Size = UDim2.new(0, Main.DurationFrame.AbsoluteSize.X, 1, 0)
			Tween(
				Main.DurationFrame.Frame,
				Notification.Duration,
				{ Size = UDim2.new(0, 0, 1, 0) },
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.InOut
			):Play()

			task.wait(Notification.Duration)
			if not Notification.Closed and Generation == Notification.TimerGeneration then
				Notification:Close()
			end
		end)
	end

	function Notification:Update(NewConfig)
		if Notification.Closed then
			return Notification
		end

		if NewConfig.Title ~= nil then
			Notification.Title = tostring(NewConfig.Title)
			TitleLabel.Text = Notification.Title
		end
		if NewConfig.Content ~= nil then
			SetContent(NewConfig.Content)
		end
		if NewConfig.Duration ~= nil then
			Notification.Duration = NewConfig.Duration
		end

		task.defer(function()
			if not Notification.Closed then
				MainContainer.Size = UDim2.new(1, 0, 0, Main.AbsoluteSize.Y)
			end
		end)

		Notification:_StartDurationTimer()
		return Notification
	end

	function Notification:Close()
		if Notification.Closed then
			return
		end

		Notification.Closed = true
		Notification.TimerGeneration = Notification.TimerGeneration + 1

		if Notification.Id and NotificationModule.ById[Notification.Id] == Notification then
			NotificationModule.ById[Notification.Id] = nil
		end
		NotificationModule.Notifications[Notification.Index] = nil

		Tween(
			MainContainer,
			0.45,
			{ Size = UDim2.new(1, 0, 0, -8) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		):Play()
		Tween(Main, 0.55, { Position = UDim2.new(2, 0, 1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

		task.delay(0.45, function()
			if MainContainer then
				MainContainer:Destroy()
			end
			if Notification.Queued and NotificationModule.QueueActive == Notification then
				NotificationModule.QueueActive = nil
				task.defer(StartNextQueued)
			end
		end)
	end

	task.spawn(function()
		task.wait()
		if Notification.Closed then
			return
		end
		Tween(
			MainContainer,
			0.45,
			{ Size = UDim2.new(1, 0, 0, Main.AbsoluteSize.Y) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		):Play()
		Tween(Main, 0.45, { Position = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		Notification:_StartDurationTimer()
	end)

	if CloseButton then
		Creator.AddSignal(CloseButton.TextButton.MouseButton1Click, function()
			Notification:Close()
		end)
	end

	return Notification
end

StartNextQueued = function()
	if NotificationModule.QueueActive and not NotificationModule.QueueActive.Closed then
		return
	end

	while #NotificationModule.Queue > 0 do
		local Entry = table.remove(NotificationModule.Queue, 1)
		if Entry and not Entry.Cancelled then
			local Config = Entry.Config
			local Notification = NotificationModule.New(Config, true)
			NotificationModule.QueueActive = Notification
			return Notification
		end
	end
end

return NotificationModule
