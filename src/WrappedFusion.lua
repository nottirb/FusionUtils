--!nonstrict

--[[
	Wraps Fusion to create custom keys and event patterns
]]

local Packages = script.Parent.Parent
local Fusion = require(Packages.Fusion)

local FusionOnEvent = Fusion.OnEvent
local FusionNew = Fusion.New

local WrappedFusion = {}

local function getInstance(instanceTable)
	return instanceTable[1]
end

local events = {
	PressDown = function(defaultPropsTable, func, instanceTable)
		defaultPropsTable[FusionOnEvent("InputBegan")] = function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				local instance = getInstance(instanceTable)
				local absoluteSize = instance.AbsoluteSize
				local relativePosition = UDim2.new(0, math.floor(absoluteSize.X / 2), 0, math.floor(absoluteSize.Y / 2))

				func(relativePosition)
			elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonA then
				local instance = getInstance(instanceTable)
				local absolutePosition = instance.AbsolutePosition
				local absoluteSize = instance.AbsoluteSize
				local relativePosition = UDim2.new(
					0,
					absolutePosition.X + math.floor(absoluteSize.X / 2),
					0,
					absolutePosition.Y + math.floor(absoluteSize.Y / 2)
				)

				func(relativePosition)
			end
		end
	end,

	PressUp = function(defaultPropsTable, func, instanceTable)
		defaultPropsTable[FusionOnEvent("InputEnded")] = function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				local instance = getInstance(instanceTable)
				local absoluteSize = instance.AbsoluteSize
				local relativePosition = UDim2.new(0, math.floor(absoluteSize.X / 2), 0, math.floor(absoluteSize.Y / 2))

				func(relativePosition)
			elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonA then
				local instance = getInstance(instanceTable)
				local absolutePosition = instance.AbsolutePosition
				local absoluteSize = instance.AbsoluteSize
				local relativePosition = UDim2.new(
					0,
					absolutePosition.X + math.floor(absoluteSize.X / 2),
					0,
					absolutePosition.Y + math.floor(absoluteSize.Y / 2)
				)

				func(relativePosition)
			end
		end
	end,

	Hover = function(defaultPropsTable, func)
		defaultPropsTable[FusionOnEvent("SelectionGained")] = func
		defaultPropsTable[FusionOnEvent("MouseEnter")] = func
	end,

	UnHover = function(defaultPropsTable, func)
		defaultPropsTable[FusionOnEvent("SelectionLost")] = func
		defaultPropsTable[FusionOnEvent("MouseLeave")] = func
	end,
}

function WrappedFusion.OnEvent(eventName): {
	type: string,
	name: string,
	key: string,
}
	if events[eventName] ~= nil then
		return {
			type = "Symbol",
			name = "CompatOnEvent",
			key = eventName,
		}
	else
		return FusionOnEvent(eventName)
	end
end

function WrappedFusion.Statify(stateOrValue)
	if type(stateOrValue) == "table" then
		if stateOrValue.type == "State" then
			return stateOrValue
		end
	end

	return Fusion.Computed(function()
		return stateOrValue
	end)

	--[[{
		type = "State",
		kind = "Constant",
		get = function()
			return stateOrValue
		end,
		update = function()
			return false
		end,
	}]]
end

function WrappedFusion.New(className: string): (propertyTable: { [any]: any }) -> (Instance)
	local propFunc = FusionNew(className)

	return function(props): Instance
		local newProps = {}
		local instanceTable = table.create(1)

		-- map props
		for index, value in next, props do
			if type(index) == "table" and index.type == "Symbol" and index.name == "CompatOnEvent" then
				local eventName = index.key
				local mapFunc = eventName ~= nil and events[eventName]

				if mapFunc ~= nil then
					mapFunc(newProps, value, instanceTable)
				else
					warn(("[WrappedFusion]: Could not map event to function '%s'"):format(tostring(eventName)))
				end
			else
				newProps[index] = value
			end
		end

		local instance = propFunc(newProps)
		instanceTable[1] = instance

		return instance
	end
end

return setmetatable({}, {
	__index = function(_self, index)
		if WrappedFusion[index] then
			return WrappedFusion[index]
		elseif Fusion[index] then
			return Fusion[index]
		end
	end,
})
