-- Credits: Fluent - Dawid

local cloneref = (cloneref or clonereference or function(instance) return instance end)


local Acrylic = {
	AcrylicBlur = require("./Blur"),
	--CreateAcrylic = require("./"),
	AcrylicPaint = require("./Paint"),
}

function Acrylic.init()
	local baseEffect = Instance.new("DepthOfFieldEffect")
	baseEffect.FarIntensity = 0
	baseEffect.InFocusRadius = 0.1
	baseEffect.NearIntensity = 1

	local depthOfFieldDefaults = {}

	function Acrylic.Enable()
		for _, effect in pairs(depthOfFieldDefaults) do
			effect.Enabled = false
		end
		baseEffect.Parent = cloneref(game:GetService("Lighting"))
	end

	function Acrylic.Disable()
		for _, effect in pairs(depthOfFieldDefaults) do
			effect.Enabled = effect.enabled
		end
		baseEffect.Parent = nil
	end

	local function registerDefaults()
		local function register(object)
			if object:IsA("DepthOfFieldEffect") then
				depthOfFieldDefaults[object] = { enabled = object.Enabled }
			end
		end

		for _, child in pairs(cloneref(game:GetService("Lighting")):GetChildren()) do
			register(child)
		end

		if cloneref(game:GetService("Workspace")).CurrentCamera then
			for _, child in pairs(cloneref(game:GetService("Workspace")).CurrentCamera:GetChildren()) do
				register(child)
			end
		end
	end

	registerDefaults()
	Acrylic.Enable()
end

return Acrylic
