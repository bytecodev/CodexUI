local function RemoveFromList(List, Value)
	for Index = #List, 1, -1 do
		if List[Index] == Value then
			table.remove(List, Index)
			return Index
		end
	end

	return nil
end

return {
	Elements = {
		Paragraph = require("./Paragraph"),
		Button = require("./Button"),
		Toggle = require("./Toggle"),
		Slider = require("./Slider"),
		ProgressBar = require("./ProgressBar"),
		Keybind = require("./Keybind"),
		Input = require("./Input"),
		Dropdown = require("./Dropdown"),
		Code = require("./Code"),
		Colorpicker = require("./Colorpicker"),
		Section = require("./Section"),
		Divider = require("./Divider"),
		Space = require("./Space"),
		Image = require("./Image"),
		Group = require("./Group"),
		HStack = require("./HStack"),
		VStack = require("./VStack"),
		Viewport = require("./Viewport"),
		--Video       = require("./Video"),
	},
	Load = function(tbl, Container, Elements, Window, CodexUI, OnElementCreateFunction, ElementsModule, UIScale, Tab)
		for name, module in next, Elements do
			tbl[name] = function(self, config)
				config = config or {}
				config.Tab = Tab or tbl
				config.ParentType = tbl.__type
				config.ParentTable = tbl
				config.Index = #tbl.Elements + 1
				config.GlobalIndex = #Window.AllElements + 1
				config.Parent = Container
				config.Window = Window
				config.CodexUI = CodexUI
				config.UIScale = UIScale
				config.ElementsModule = ElementsModule

				local _elementInstance, content = module:New(config)

				local elementId = config.Id or config.ID or config.Flag
				content.Id = elementId
				content.Flag = config.Flag

				Window.ElementRegistry = Window.ElementRegistry or {}
				local function RegisterElementKey(Key)
					if Key ~= nil then
						Key = tostring(Key)
					end
					if typeof(Key) == "string" and Key ~= "" then
						if Window.ElementRegistry[Key] and Window.ElementRegistry[Key] ~= content and Window.Debug then
							warn("[ CodexUI ] Element id/flag '" .. Key .. "' was replaced in the registry.")
						end
						Window.ElementRegistry[Key] = content
					end
				end

				RegisterElementKey(elementId)
				if config.Flag ~= elementId then
					RegisterElementKey(config.Flag)
				end

				if config.Flag and typeof(config.Flag) == "string" then
					if Window.CurrentConfig then
						Window.CurrentConfig:Register(config.Flag, content)

						if Window.PendingConfigData and Window.PendingConfigData[config.Flag] then
							local data = Window.PendingConfigData[config.Flag]

							local ConfigManager = Window.ConfigManager
							if ConfigManager.Parser[data.__type] then
								task.defer(function()
									local success, err = pcall(function()
										ConfigManager.Parser[data.__type].Load(content, data)
									end)

									if success then
										Window.PendingConfigData[config.Flag] = nil
									else
										warn(
											"[ CodexUI ] Failed to apply pending config for '"
												.. config.Flag
												.. "': "
												.. tostring(err)
										)
									end
								end)
							end
						end
					else
						Window.PendingFlags = Window.PendingFlags or {}
						Window.PendingFlags[config.Flag] = content
					end
				end

				local frame
				for key, value in next, content do
					if typeof(value) == "table" and key ~= "ElementFrame" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if frame then
					content.ElementFrame = frame.UIElements.Main
					function content:SetTitle(title)
						return frame.SetTitle and frame:SetTitle(title)
					end
					function content:SetDesc(desc)
						return frame.SetDesc and frame:SetDesc(desc)
					end
					function content:SetImage(image, size)
						return frame.SetImage and frame:SetImage(image, size)
					end
					function content:SetThumbnail(image, size)
						return frame.SetThumbnail and frame:SetThumbnail(image, size)
					end
					function content:Highlight()
						frame:Highlight()
					end
					function content:Destroy()
						frame:Destroy()

						if Window.ElementRegistry then
							local elementKey = elementId ~= nil and tostring(elementId) or nil
							local flagKey = config.Flag ~= nil and tostring(config.Flag) or nil
							if elementKey and Window.ElementRegistry[elementKey] == content then
								Window.ElementRegistry[elementKey] = nil
							end
							if flagKey and Window.ElementRegistry[flagKey] == content then
								Window.ElementRegistry[flagKey] = nil
							end
						end

						if config.Flag and Window.CurrentConfig and Window.CurrentConfig.Unregister then
							Window.CurrentConfig:Unregister(config.Flag, content)
						end
						if config.Flag and Window.PendingFlags and Window.PendingFlags[config.Flag] == content then
							Window.PendingFlags[config.Flag] = nil
						end

						RemoveFromList(Window.AllElements, content)
						local RemovedIndex = RemoveFromList(tbl.Elements, content)

						if Window.NewElements and RemovedIndex then
							tbl:UpdateAllElementShapes(tbl)
						end
					end
				end

				-- Each container owns its own Elements array. Nested Group/HStack/VStack/Section
				-- children must not overwrite the parent Tab.Elements indexes.
				table.insert(Window.AllElements, content)
				config.GlobalIndex = #Window.AllElements
				table.insert(tbl.Elements, content)
				config.Index = #tbl.Elements

				if Window.NewElements then
					tbl:UpdateAllElementShapes(tbl)
				end

				if OnElementCreateFunction then
					OnElementCreateFunction(content, tbl.Elements)
				end
				return content
			end
		end
		function tbl:UpdateAllElementShapes(bbb)
			for i, element in next, bbb.Elements do
				local frame
				for key, value in pairs(element) do
					if typeof(value) == "table" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if not frame and element.UpdateShape then
					frame = element
				end

				if frame then
					--print("idx changed : " .. i .. " " .. (element.Title or "not found"))
					frame.Index = i
					if frame.UpdateShape then
						--print(" .changed: " .. i)
						frame.UpdateShape(bbb)
					end
				end
			end
		end
	end,
}
