local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local Players = game:GetService("Players")

local UserInputService = cloneref(game:GetService("UserInputService"))
local Mouse = Players.LocalPlayer:GetMouse()

local Creator = require("../../modules/Creator")
local New = Creator.New

local CreateToolTip = require("../ui/Tooltip").New
local CreateScrollSlider = require("../ui/ScrollSlider").New

local Window, CodexUI, UIScale

local function CleanupResource(Resource, CustomCleanup)
	if Resource == nil then
		return
	end

	local ok, err = pcall(function()
		if typeof(CustomCleanup) == "function" then
			CustomCleanup(Resource)
		elseif typeof(Resource) == "RBXScriptConnection" then
			Resource:Disconnect()
		elseif typeof(Resource) == "Instance" then
			Resource:Destroy()
		elseif type(Resource) == "thread" then
			task.cancel(Resource)
		elseif typeof(Resource) == "function" then
			Resource()
		elseif typeof(Resource) == "table" then
			if typeof(Resource.Destroy) == "function" then
				Resource:Destroy()
			elseif typeof(Resource.Disconnect) == "function" then
				Resource:Disconnect()
			elseif typeof(Resource.Cancel) == "function" then
				Resource:Cancel()
			elseif typeof(Resource.Close) == "function" then
				Resource:Close()
			end
		end
	end)

	if not ok then
		warn("[ CodexUI ] Tab cleanup failed: " .. tostring(err))
	end
end

local TabModule = {
	--Window = nil,
	--CodexUI = nil,
	Tabs = {},
	Containers = {},
	SelectedTab = nil,
	TabCount = 0,
	ToolTipParent = nil,
	TabHighlight = nil,

	OnChangeFunc = function(v) end,
}

function TabModule.Init(WindowTable, CodexUITable, ToolTipParent, TabHighlight)
	Window = WindowTable
	CodexUI = CodexUITable
	TabModule.ToolTipParent = ToolTipParent
	TabModule.TabHighlight = TabHighlight
	return TabModule
end

function TabModule.New(Config, UIScale)
	local Tab = {
		__type = "Tab",
		Title = Config.Title or "Tab",
		Desc = Config.Desc,
		Icon = Config.Icon,
		IconColor = Config.IconColor,
		IconShape = Config.IconShape,
		IconThemed = Config.IconThemed,
		Locked = Config.Locked,
		ShowTabTitle = Config.ShowTabTitle,
		TabTitleAlign = Config.TabTitleAlign or "Left",
		CustomEmptyPage = (Config.CustomEmptyPage and next(Config.CustomEmptyPage) ~= nil) and Config.CustomEmptyPage
			or { Icon = "lucide:frown", IconSize = 48, Title = "This tab is Empty", Desc = nil },
		Border = Config.Border,
		Selected = false,
		Index = nil,
		Parent = Config.Parent,
		UIElements = {},
		Elements = {},
		TrackedResources = {},
		ContainerFrame = nil,
		BuildFunction = typeof(Config.Build) == "function" and Config.Build or nil,
		Lazy = Config.Lazy == true and typeof(Config.Build) == "function",
		Built = typeof(Config.Build) ~= "function",
		Building = false,
		UICorner = Window.UICorner - (Window.UIPadding / 2),

		Gap = Window.NewElements and 1 or 6,

		TabPaddingX = 4 + (Window.UIPadding / 2),
		TabPaddingY = 3 + (Window.UIPadding / 2),
		TitlePaddingY = 0,
	}

	if Config.Lazy == true and not Tab.BuildFunction and Window.Debug then
		warn("[ CodexUI ] Lazy tab '" .. Tab.Title .. "' has no Build callback; falling back to eager API usage.")
	end

	-- if Tab.TabTitleAlign == "Left" then
	-- 	Tab.TabTitleAlign = "Top"
	-- elseif Tab.TabTitleAlign == "Right" then
	-- 	Tab.TabTitleAlign = "Bottom"
	-- elseif Tab.TabTitleAlign == "Center" then
	-- 	Tab.TabTitleAlign = "Center"
	-- end

	if Tab.IconShape then
		Tab.TabPaddingX = 2 + (Window.UIPadding / 4)
		Tab.TabPaddingY = 2 + (Window.UIPadding / 4)
		Tab.TitlePaddingY = 2 + (Window.UIPadding / 4)
	end

	TabModule.TabCount = TabModule.TabCount + 1

	local TabIndex = TabModule.TabCount
	Tab.Index = TabIndex

	Tab.UIElements.Main = Creator.NewRoundFrame(Tab.UICorner, "Squircle", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -7, 0, 0),
		AutomaticSize = "Y",
		Parent = Config.Parent,
		ThemeTag = {
			ImageColor3 = "TabBackground",
		},
		ImageTransparency = 1,
	}, {
		Creator.NewRoundFrame(Tab.UICorner - 1, "Glass-1.4", {
			Size = UDim2.new(1, 1, 1, 1),
			ThemeTag = {
				ImageColor3 = "TabBorder",
			},
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			ImageTransparency = 1, -- .7
			Name = "Outline",
		}, {
			-- New("UIGradient", {
			--     Rotation = 80,
			--     Color = ColorSequence.new({
			--         ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
			--         ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			--         ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
			--     }),
			--     Transparency = NumberSequence.new({
			--         NumberSequenceKeypoint.new(0.0, 0.1),
			--         NumberSequenceKeypoint.new(0.5, 1),
			--         NumberSequenceKeypoint.new(1.0, 0.1),
			--     })
			-- }),
		}),
		Creator.NewRoundFrame(Tab.UICorner, "Squircle", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = "Y",
			ThemeTag = {
				ImageColor3 = "Text",
			},
			ImageTransparency = 1, -- .95
			Name = "Frame",
		}, {
			New("UIListLayout", {
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, 2 + (Window.UIPadding / 2)),
				FillDirection = "Horizontal",
				VerticalAlignment = "Center",
			}),
			New("TextLabel", {
				Text = Tab.Title,
				ThemeTag = {
					TextColor3 = "TabTitle",
				},
				TextTransparency = not Tab.Locked and 0.4 or 0.7,
				TextSize = 15,
				Size = UDim2.new(1, 0, 0, 0),
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
				TextWrapped = true,
				RichText = true,
				AutomaticSize = "Y",
				LayoutOrder = 2,
				TextXAlignment = "Left",
				BackgroundTransparency = 1,
			}, {
				New("UIPadding", {
					PaddingTop = UDim.new(0, Tab.TitlePaddingY),
					--PaddingLeft = UDim.new(0,2+(Window.UIPadding/2)),
					--PaddingRight = UDim.new(0,2+(Window.UIPadding/2)),
					PaddingBottom = UDim.new(0, Tab.TitlePaddingY),
				}),
			}),
			New("UIPadding", {
				PaddingTop = UDim.new(0, Tab.TabPaddingY),
				PaddingLeft = UDim.new(0, Tab.TabPaddingX),
				PaddingRight = UDim.new(0, Tab.TabPaddingX),
				PaddingBottom = UDim.new(0, Tab.TabPaddingY),
			}),
		}),
	}, true)

	local TextOffset = 0
	local Icon
	local Icon2

	if Tab.Icon then
		Icon = Creator.Image(
			Tab.Icon,
			Tab.Icon .. ":" .. Tab.Title,
			0,
			Window.Folder,
			Tab.__type,
			Tab.IconColor and false or true,
			Tab.IconThemed,
			"TabIcon"
		)
		Icon.Size = UDim2.new(0, 16, 0, 16)
		if Tab.IconColor then
			Icon.ImageLabel.ImageColor3 = Tab.IconColor
		end
		if not Tab.IconShape then
			Icon.Parent = Tab.UIElements.Main.Frame
			Tab.UIElements.Icon = Icon
			Icon.ImageLabel.ImageTransparency = not Tab.Locked and 0 or 0.7
			TextOffset = -16 - 2 - (Window.UIPadding / 2)
			Tab.UIElements.Main.Frame.TextLabel.Size = UDim2.new(1, TextOffset, 0, 0)
		elseif Tab.IconColor then
			local _IconBG = Creator.NewRoundFrame(
				Tab.IconShape ~= "Circle" and (Tab.UICorner + 5 - (2 + (Window.UIPadding / 4))) or 9999,
				"Squircle",
				{
					Size = UDim2.new(0, 26, 0, 26),
					ImageColor3 = Tab.IconColor,
					Parent = Tab.UIElements.Main.Frame,
				},
				{
					Icon,
					Creator.NewRoundFrame(
						Tab.IconShape ~= "Circle" and (Tab.UICorner + 5 - (2 + (Window.UIPadding / 4))) or 9999,
						"Glass-1.4",
						{
							Size = UDim2.new(1, 0, 1, 0),
							ThemeTag = {
								ImageColor3 = "White",
							},
							ImageTransparency = 0,
							Name = "Outline",
						},
						{
							-- New("UIGradient", {
							--     Rotation = 45,
							--     Color = ColorSequence.new({
							--         ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
							--         ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
							--         ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
							--     }),
							--     Transparency = NumberSequence.new({
							--         NumberSequenceKeypoint.new(0.0, 0.1),
							--         NumberSequenceKeypoint.new(0.5, 1),
							--         NumberSequenceKeypoint.new(1.0, 0.1),
							--     })
							-- }),
						}
					),
				}
			)
			Icon.AnchorPoint = Vector2.new(0.5, 0.5)
			Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
			Icon.ImageLabel.ImageTransparency = 0
			Icon.ImageLabel.ImageColor3 = Creator.GetTextColorForHSB(Tab.IconColor, 0.68)
			TextOffset = -26 - 2 - (Window.UIPadding / 2)
			Tab.UIElements.Main.Frame.TextLabel.Size = UDim2.new(1, TextOffset, 0, 0)
		end

		Icon2 =
			Creator.Image(Tab.Icon, Tab.Icon .. ":" .. Tab.Title, 0, Window.Folder, Tab.__type, true, Tab.IconThemed)
		Icon2.Size = UDim2.new(0, 16, 0, 16)
		Icon2.ImageLabel.ImageTransparency = not Tab.Locked and 0 or 0.7
		TextOffset = -30

		--Icon2.Parent = Tab.UIElements.Main.Frame
		--Tab.UIElements.Main.Frame.TextLabel.Size = UDim2.new(1,-30,0,0)
		--Tab.UIElements.Icon = Icon
	end

	Tab.UIElements.ContainerFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, Tab.ShowTabTitle and -((Window.UIPadding * 2.4) + 12) or 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ElasticBehavior = "Never",
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		AutomaticCanvasSize = "Y",
		--Visible = false,
		ScrollingDirection = "Y",
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, not Window.HidePanelBackground and 20 or 10),
			PaddingLeft = UDim.new(0, not Window.HidePanelBackground and 20 or 10),
			PaddingRight = UDim.new(0, not Window.HidePanelBackground and 20 or 10),
			PaddingBottom = UDim.new(0, not Window.HidePanelBackground and 20 or 10),
		}),
		New("UIListLayout", {
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, Tab.Gap),
			HorizontalAlignment = "Center",
		}),
	})

	-- Tab.UIElements.ContainerFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	--     Tab.UIElements.ContainerFrame.CanvasSize = UDim2.new(0,0,0,Tab.UIElements.ContainerFrame.UIListLayout.AbsoluteContentSize.Y+Window.UIPadding*2)
	-- end)

	Tab.UIElements.ContainerFrameCanvas = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = Window.UIElements.MainBar,
		ZIndex = 5,
	}, {
		Tab.UIElements.ContainerFrame,
		New("Frame", {
			Size = UDim2.new(1, -14, 1, -14),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Name = "ScrollSliderHolder",
		}),
		New("Frame", {
			Size = UDim2.new(1, 0, 0, ((Window.UIPadding * 2.4) + 12)),
			BackgroundTransparency = 1,
			Visible = Tab.ShowTabTitle or false,
			Name = "TabTitle",
		}, {
			Icon2,
			New("TextLabel", {
				Text = Tab.Title,
				ThemeTag = {
					TextColor3 = "Text",
				},
				TextSize = 20,
				TextTransparency = 0.1,
				Size = UDim2.new(0, 0, 1, 0),
				FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
				--TextTruncate = "AtEnd",
				RichText = true,
				LayoutOrder = 2,
				TextXAlignment = "Left",
				BackgroundTransparency = 1,
				AutomaticSize = "X",
			}),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 20),
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingBottom = UDim.new(0, 20),
			}),
			New("UIListLayout", {
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, 10),
				FillDirection = "Horizontal",
				VerticalAlignment = "Center",
				HorizontalAlignment = Tab.TabTitleAlign,
			}),
		}),
		New("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 0.9,
			ThemeTag = {
				BackgroundColor3 = "Text",
			},
			Position = UDim2.new(0, 0, 0, ((Window.UIPadding * 2.4) + 12)),
			Visible = Tab.ShowTabTitle or false,
		}),
	})

	TabModule.Containers[TabIndex] = Tab.UIElements.ContainerFrameCanvas
	TabModule.Tabs[TabIndex] = Tab

	Tab.ContainerFrame = Tab.UIElements.ContainerFrameCanvas

	Creator.AddSignal(Tab.UIElements.Main.MouseButton1Click, function()
		if not Tab.Locked then
			TabModule:SelectTab(TabIndex)
		end
	end)

	if Window.ScrollBarEnabled then
		CreateScrollSlider(
			Tab.UIElements.ContainerFrame,
			Tab.UIElements.ContainerFrameCanvas.ScrollSliderHolder,
			Window,
			4,
			CodexUI
		)
	end

	local ToolTip
	local hoverTimer
	local MouseConn
	local IsHovering = false

	-- ToolTip
	if Tab.Desc then
		Creator.AddSignal(Tab.UIElements.Main.InputBegan, function()
			IsHovering = true
			hoverTimer = task.spawn(function()
				task.wait(0.35)
				if IsHovering and not ToolTip then
					ToolTip = CreateToolTip(Tab.Desc, TabModule.ToolTipParent, true)
					ToolTip.Container.AnchorPoint = Vector2.new(0.5, 0.5)

					local function updatePosition()
						if ToolTip then
							ToolTip.Container.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y - 4)
						end
					end

					updatePosition()
					MouseConn = Mouse.Move:Connect(updatePosition)
					ToolTip:Open()
				end
			end)
		end)
	end

	Creator.AddSignal(Tab.UIElements.Main.MouseEnter, function()
		if not Tab.Locked then
			Creator.SetThemeTag(Tab.UIElements.Main.Frame, {
				ImageTransparency = "TabBackgroundHoverTransparency",
				ImageColor3 = "TabBackgroundHover",
			}, 0.1)
		end
	end)
	Creator.AddSignal(Tab.UIElements.Main.InputEnded, function()
		if Tab.Desc then
			IsHovering = false
			if hoverTimer then
				task.cancel(hoverTimer)
				hoverTimer = nil
			end
			if MouseConn then
				MouseConn:Disconnect()
				MouseConn = nil
			end
			if ToolTip then
				ToolTip:Close()
				ToolTip = nil
			end
		end

		if not Tab.Locked then
			Creator.SetThemeTag(Tab.UIElements.Main.Frame, {
				ImageTransparency = "TabBorderTransparency",
			}, 0.1)
		end
	end)

	function Tab:ScrollToTheElement(elemindex)
		Tab.UIElements.ContainerFrame.ScrollingEnabled = false

		Creator.Tween(Tab.UIElements.ContainerFrame, 0.45, {
			CanvasPosition = Vector2.new(
				0,
				Tab.Elements[elemindex].ElementFrame.AbsolutePosition.Y
					- Tab.UIElements.ContainerFrame.AbsolutePosition.Y
					- Tab.UIElements.ContainerFrame.UIPadding.PaddingTop.Offset
			),
		}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

		task.spawn(function()
			task.wait(0.48)

			if Tab.Elements[elemindex].Highlight then
				Tab.Elements[elemindex]:Highlight()
			end
			Tab.UIElements.ContainerFrame.ScrollingEnabled = true
		end)

		return Tab
	end

	-- yo

	local ElementsModule = require("../../elements/Init")

	ElementsModule.Load(
		Tab,
		Tab.UIElements.ContainerFrame,
		ElementsModule.Elements,
		Window,
		CodexUI,
		nil,
		ElementsModule,
		UIScale,
		Tab
	)

	function Tab:_EnsureBuilt()
		if Tab.Built or Tab.Building or not Tab.BuildFunction then
			return Tab
		end

		Tab.Building = true
		local ok, err = pcall(Tab.BuildFunction, Tab)
		Tab.Building = false

		if not ok then
			warn("[ CodexUI ] Failed to build lazy tab '" .. Tab.Title .. "': " .. tostring(err))
			return Tab
		end

		Tab.Built = true
		return Tab
	end

	function Tab:Build()
		return Tab:_EnsureBuilt()
	end

	function Tab:Track(Resource, Cleanup)
		if Resource == nil then
			return nil
		end

		table.insert(Tab.TrackedResources, {
			Resource = Resource,
			Cleanup = Cleanup,
		})
		return Resource
	end

	function Tab:OnCleanup(Callback)
		return Tab:Track(Callback)
	end

	function Tab:Cleanup()
		for Index = #Tab.TrackedResources, 1, -1 do
			local Entry = table.remove(Tab.TrackedResources, Index)
			if Entry then
				CleanupResource(Entry.Resource, Entry.Cleanup)
			end
		end
		return Tab
	end

	function Tab:GetElement(Id)
		local Element = Window:GetElement(Id)
		if Element and Element.Tab == Tab then
			return Element
		end
		return nil
	end

	if Tab.BuildFunction and not Tab.Lazy then
		Tab:_EnsureBuilt()
	end

	-- Native centered state container for tabs. This is useful for gated/empty
	-- pages (for example, a Chat tab that should only show a Connect button
	-- until a session is ready) without scripts manually parenting Instances
	-- into CodexUI internals. The returned object exposes the normal CodexUI
	-- element API: state:Button(), state:Paragraph(), state:Input(), etc.
	function Tab:EmptyState(StateConfig)
		StateConfig = StateConfig or {}

		local State = {
			__type = "EmptyState",
			Visible = false,
			Elements = {},
			UIElements = {},
			Tab = Tab,
		}

		local StateFrame = New("Frame", {
			Name = StateConfig.Name or "EmptyState",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = StateConfig.ZIndex or 20,
			Parent = Tab.UIElements.ContainerFrameCanvas,
		})

		local Content = New("Frame", {
			Name = "Content",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -(StateConfig.Padding or 40) * 2, 0, 0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = (StateConfig.ZIndex or 20) + 1,
			Parent = StateFrame,
		}, {
			New("UISizeConstraint", {
				MaxSize = Vector2.new(StateConfig.MaxWidth or 320, 1000000),
			}),
			New("UIListLayout", {
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, StateConfig.Gap or Tab.Gap),
				HorizontalAlignment = "Center",
				VerticalAlignment = "Center",
			}),
		})

		State.UIElements.Main = StateFrame
		State.UIElements.Content = Content

		ElementsModule.Load(
			State,
			Content,
			ElementsModule.Elements,
			Window,
			CodexUI,
			nil,
			ElementsModule,
			UIScale,
			Tab
		)

		local function ApplyVisibility(Visible)
			Visible = Visible == true

			if Visible and Tab._ActiveEmptyState and Tab._ActiveEmptyState ~= State then
				Tab._ActiveEmptyState:SetVisible(false)
			end

			State.Visible = Visible
			StateFrame.Visible = Visible
			Tab.UIElements.ContainerFrame.Visible = not Visible

			local ScrollHolder = Tab.UIElements.ContainerFrameCanvas:FindFirstChild("ScrollSliderHolder")
			if ScrollHolder then
				ScrollHolder.Visible = not Visible
			end

			if Visible then
				Tab._ActiveEmptyState = State
			elseif Tab._ActiveEmptyState == State then
				Tab._ActiveEmptyState = nil
			end

			return State
		end

		function State:SetVisible(Visible)
			return ApplyVisibility(Visible)
		end

		function State:Show()
			return ApplyVisibility(true)
		end

		function State:Hide()
			return ApplyVisibility(false)
		end

		function State:Destroy()
			if State._Destroyed then
				return
			end
			State._Destroyed = true

			if Tab._ActiveEmptyState == State then
				Tab._ActiveEmptyState = nil
				Tab.UIElements.ContainerFrame.Visible = true
				local ScrollHolder = Tab.UIElements.ContainerFrameCanvas:FindFirstChild("ScrollSliderHolder")
				if ScrollHolder then
					ScrollHolder.Visible = true
				end
			end

			for Index = #State.Elements, 1, -1 do
				local Element = State.Elements[Index]
				if Element and Element.Destroy then
					Element:Destroy()
				end
			end

			StateFrame:Destroy()
		end

		ApplyVisibility(StateConfig.Visible == true)

		return State
	end

	function Tab:LockAll()
		--print("LockAll called, number of elements: " .. #self.Elements)
		for _, element in next, Window.AllElements do
			if element.Tab and element.Tab.Index and element.Tab.Index == Tab.Index and element.Lock then
				element:Lock()
			end
		end
	end
	function Tab:UnlockAll()
		for _, element in next, Window.AllElements do
			if element.Tab and element.Tab.Index and element.Tab.Index == Tab.Index and element.Unlock then
				element:Unlock()
			end
		end
	end
	function Tab:GetLocked()
		local LockedElements = {}

		for _, element in next, Window.AllElements do
			if element.Tab and element.Tab.Index and element.Tab.Index == Tab.Index and element.Locked == true then
				table.insert(LockedElements, element)
			end
		end

		return LockedElements
	end
	function Tab:GetUnlocked()
		local UnlockedElements = {}

		for _, element in next, Window.AllElements do
			if element.Tab and element.Tab.Index and element.Tab.Index == Tab.Index and element.Locked == false then
				table.insert(UnlockedElements, element)
			end
		end

		return UnlockedElements
	end

	function Tab:Destroy()
		if Tab.Destroyed then
			return
		end
		Tab.Destroyed = true
		Tab:Cleanup()

		for Index = #Tab.Elements, 1, -1 do
			local Element = Tab.Elements[Index]
			if Element and Element.Destroy then
				pcall(function()
					Element:Destroy()
				end)
			end
		end

		if Tab.UIElements.ContainerFrameCanvas then
			Tab.UIElements.ContainerFrameCanvas:Destroy()
		end
		if Tab.UIElements.Main then
			Tab.UIElements.Main:Destroy()
		end

		TabModule.Tabs[Tab.Index] = nil
		TabModule.Containers[Tab.Index] = nil

		if TabModule.SelectedTab == Tab.Index then
			TabModule.SelectedTab = nil
			for Index, Candidate in next, TabModule.Tabs do
				if Candidate and not Candidate.Locked then
					TabModule:SelectTab(Index)
					break
				end
			end
		end
	end

	function Tab:Select()
		return TabModule:SelectTab(Tab.Index)
	end

	task.spawn(function()
		local EmptyPageIcon
		if Tab.CustomEmptyPage.Icon then
			EmptyPageIcon =
				Creator.Image(Tab.CustomEmptyPage.Icon, Tab.CustomEmptyPage.Icon, 0, "Temp", "EmptyPage", true)
			EmptyPageIcon.Size =
				UDim2.fromOffset(Tab.CustomEmptyPage.IconSize or 48, Tab.CustomEmptyPage.IconSize or 48)
		end

		local Empty = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, -Window.UIElements.Main.Main.Topbar.AbsoluteSize.Y),
			Parent = Tab.UIElements.ContainerFrame,
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = "LayoutOrder",
				VerticalAlignment = "Center",
				HorizontalAlignment = "Center",
				FillDirection = "Vertical",
			}),
			-- New("ImageLabel", {
			-- 	Size = UDim2.new(0, 48, 0, 48),
			-- 	Image = Creator.Icon("frown")[1],
			-- 	ImageRectOffset = Creator.Icon("frown")[2].ImageRectPosition,
			-- 	ImageRectSize = Creator.Icon("frown")[2].ImageRectSize,
			-- 	ThemeTag = {
			-- 		ImageColor3 = "Icon",
			-- 	},
			-- 	BackgroundTransparency = 1,
			-- 	ImageTransparency = 0.6,
			-- }),
			EmptyPageIcon,
			Tab.CustomEmptyPage.Title and New("TextLabel", { -- Title
				AutomaticSize = "XY",
				Text = Tab.CustomEmptyPage.Title,
				ThemeTag = {
					TextColor3 = "Text",
				},
				TextSize = 18,
				TextTransparency = 0.5,
				BackgroundTransparency = 1,
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			}) or nil,
			Tab.CustomEmptyPage.Desc and New("TextLabel", { -- Desc
				AutomaticSize = "XY",
				Text = Tab.CustomEmptyPage.Desc,
				ThemeTag = {
					TextColor3 = "Text",
				},
				TextSize = 15,
				TextTransparency = 0.65,
				BackgroundTransparency = 1,
				FontFace = Font.new(Creator.Font, Enum.FontWeight.Regular),
			}) or nil,
		})

		-- Empty.TextLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
		--     Empty.TextLabel.Size = UDim2.new(0,Empty.TextLabel.TextBounds.X,0,Empty.TextLabel.TextBounds.Y)
		-- end)

		local CreationConn
		CreationConn = Creator.AddSignal(Tab.UIElements.ContainerFrame.ChildAdded, function()
			Empty.Visible = false
			CreationConn:Disconnect()
		end)
	end)

	return Tab
end

function TabModule:OnChange(func)
	TabModule.OnChangeFunc = func
end

function TabModule:SelectTab(TabIndex)
	local SelectedTab = TabModule.Tabs[TabIndex]
	if not SelectedTab then
		return nil
	end

	if not SelectedTab.Locked then
		SelectedTab:_EnsureBuilt()
		TabModule.SelectedTab = TabIndex

		for _, TabObject in next, TabModule.Tabs do
			if not TabObject.Locked then
				Creator.SetThemeTag(TabObject.UIElements.Main, {
					ImageTransparency = "TabBorderTransparency",
				}, 0.15)
				if TabObject.Border then
					Creator.SetThemeTag(TabObject.UIElements.Main.Outline, {
						ImageTransparency = "TabBorderTransparency",
					}, 0.15)
				end
				Creator.SetThemeTag(TabObject.UIElements.Main.Frame.TextLabel, {
					TextTransparency = "TabTextTransparency",
				}, 0.15)
				if TabObject.UIElements.Icon and not TabObject.IconColor then
					Creator.SetThemeTag(TabObject.UIElements.Icon.ImageLabel, {
						ImageTransparency = "TabIconTransparency",
					}, 0.15)
				end
				TabObject.Selected = false
			end
		end
		Creator.SetThemeTag(TabModule.Tabs[TabIndex].UIElements.Main, {
			ImageColor3 = "TabBackgroundActive",
			ImageTransparency = "TabBackgroundActiveTransparency",
		}, 0.15)
		if TabModule.Tabs[TabIndex].Border then
			Creator.SetThemeTag(TabModule.Tabs[TabIndex].UIElements.Main.Outline, {
				ImageTransparency = "TabBorderTransparencyActive",
			}, 0.15)
		end
		Creator.SetThemeTag(TabModule.Tabs[TabIndex].UIElements.Main.Frame.TextLabel, {
			TextTransparency = "TabTextTransparencyActive",
		}, 0.15)
		if TabModule.Tabs[TabIndex].UIElements.Icon and not TabModule.Tabs[TabIndex].IconColor then
			Creator.SetThemeTag(TabModule.Tabs[TabIndex].UIElements.Icon.ImageLabel, {
				ImageTransparency = "TabIconTransparencyActive",
			}, 0.15)
		end
		TabModule.Tabs[TabIndex].Selected = true

		task.spawn(function()
			for _, ContainerObject in next, TabModule.Containers do
				ContainerObject.AnchorPoint = Vector2.new(0, 0.05)
				ContainerObject.Visible = false
			end
			TabModule.Containers[TabIndex].Visible = true
			local TweenService = game:GetService("TweenService")

			local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			local tween = TweenService:Create(TabModule.Containers[TabIndex], tweenInfo, {
				AnchorPoint = Vector2.new(0, 0),
			})
			tween:Play()
		end)

		TabModule.OnChangeFunc(TabIndex)
	end
end

return TabModule
