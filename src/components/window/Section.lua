local Section = {}


local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local TabModule = require("./Tab")

function Section.New(SectionConfig, Parent, Folder, UIScale, Window)
    local SectionModule = {
        Title = SectionConfig.Title or "Section",
        Icon = SectionConfig.Icon,
        IconColor = SectionConfig.IconColor,
        IconThemed = SectionConfig.IconThemed,
        Opened = SectionConfig.Opened or false,
        
        HeaderSize = 42,
        IconSize = SectionConfig.IconSize or 14,
        ChevronSize = 18,
        
        Expandable = false,
        Tabs = {},
    }
    
    local IconFrame
    if SectionModule.Icon then
        IconFrame = Creator.Image(
            SectionModule.Icon,
            SectionModule.Icon,
            0,
            Folder,
            "Section",
            SectionModule.IconColor and false or true,
            SectionModule.IconThemed,
            "TabSectionIcon"
        )
        
        IconFrame.Size = UDim2.new(0,SectionModule.IconSize,0,SectionModule.IconSize)
        IconFrame.ImageLabel.ImageTransparency = .25
        if SectionModule.IconColor then
            IconFrame.ImageLabel.ImageColor3 = SectionModule.IconColor
        end
    end
    
    local ChevronIconFrame = New("Frame", {
        Size = UDim2.new(0,SectionModule.ChevronSize,0,SectionModule.ChevronSize),
        BackgroundTransparency = 1,
        Visible = false
    }, {
        New("ImageLabel", {
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Image = Creator.Icon("chevron-down")[1],
            ImageRectSize = Creator.Icon("chevron-down")[2].ImageRectSize,
            ImageRectOffset = Creator.Icon("chevron-down")[2].ImageRectPosition,
            ThemeTag = {
                ImageColor3 = "Icon",
            },
            ImageTransparency = .7,
        })
    })
    
    local SectionFrame = New("Frame", {
        Size = UDim2.new(1,0,0,SectionModule.HeaderSize),
        BackgroundTransparency = 1,
        Parent = Parent,
        ClipsDescendants = true,
    }, {
        New("TextButton", {
            Size = UDim2.new(1,0,0,SectionModule.HeaderSize),
            BackgroundTransparency = 1,
            Text = "",
        }, {
            IconFrame,
            New("TextLabel", {
                Text = SectionModule.Title,
                TextXAlignment = "Left",
                Size = UDim2.new(
                    1,
                    -(SectionModule.ChevronSize + 10)
                        - (IconFrame and (SectionModule.IconSize + 10) or 0),
                    1,
                    0
                ),
                ThemeTag = {
                    TextColor3 = "Text",
                },
                FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
                TextSize = 14,
                BackgroundTransparency = 1,
                TextTransparency = .7,
                --TextTruncate = "AtEnd",
                TextWrapped = true
            }),
            New("UIListLayout", {
                FillDirection = "Horizontal",
                VerticalAlignment = "Center",
                Padding = UDim.new(0,10)
            }),
            ChevronIconFrame,
            New("UIPadding", {
                PaddingLeft = UDim.new(0,11),
                PaddingRight = UDim.new(0,11),
            })
        }),
        New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,0),
            AutomaticSize = "Y",
            Name = "Content",
            Visible = true,
            Position = UDim2.new(0,0,0,SectionModule.HeaderSize)
        }, {
            New("UIListLayout", {
                FillDirection = "Vertical",
                Padding = UDim.new(0,Window.Gap),
                VerticalAlignment = "Bottom",
            }),
        })
    })
    
    
    function SectionModule:Tab(TabConfig)
        if not SectionModule.Expandable then
            SectionModule.Expandable = true
            ChevronIconFrame.Visible = true
        end
        TabConfig.Parent = SectionFrame.Content
        local Tab = TabModule.New(TabConfig, UIScale)
        table.insert(SectionModule.Tabs, Tab)
        return Tab
    end

    function SectionModule:GetElement(Id)
        local Element = Window:GetElement(Id)
        if not Element or not Element.Tab then
            return nil
        end

        for _, Tab in next, SectionModule.Tabs do
            if Element.Tab == Tab then
                return Element
            end
        end
        return nil
    end
    
    function SectionModule:Open()
        if SectionModule.Expandable then
            SectionModule.Opened = true
            Tween(SectionFrame, 0.33, {
                Size = UDim2.new(1,0,0, SectionModule.HeaderSize + (SectionFrame.Content.AbsoluteSize.Y/UIScale))
            }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            
            Tween(ChevronIconFrame.ImageLabel, 0.1, {Rotation = 180}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
        end
    end
    function SectionModule:Close()
        if SectionModule.Expandable then
            SectionModule.Opened = false
            Tween(SectionFrame, 0.26, {
                Size = UDim2.new(1,0,0, SectionModule.HeaderSize)
            }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
            Tween(ChevronIconFrame.ImageLabel, 0.1, {Rotation = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
        end
    end
    
    Creator.AddSignal(SectionFrame.TextButton.MouseButton1Click, function()
        if SectionModule.Expandable then
            if SectionModule.Opened then
                SectionModule:Close()
            else
                SectionModule:Open()
            end
        end
    end)
    
    Creator.AddSignal(SectionFrame.Content.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        if SectionModule.Opened then
            SectionModule:Open()
        end
    end)
    
    if SectionModule.Opened then
        task.spawn(function()
            task.wait()
            SectionModule:Open()
        end)
    end

    
    
    return SectionModule
end


return Section