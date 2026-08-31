-- Credits: Fluent - Dawid


local cloneref = (cloneref or clonereference or function(instance) return instance end)


local function map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function viewportPointToWorld(location, distance)
	local unitRay = cloneref(game:GetService("Workspace")).CurrentCamera:ScreenPointToRay(location.X, location.Y)
	return unitRay.Origin + unitRay.Direction * distance
end

local function getOffset()
	local viewportSizeY = cloneref(game:GetService("Workspace")).CurrentCamera.ViewportSize.Y
	return map(viewportSizeY, 0, 2560, 8, 56)
end

return { viewportPointToWorld, getOffset }
