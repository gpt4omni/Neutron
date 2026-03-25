local Url = require(script.Parent.Url)

local Renderer = {}
Renderer.__index = Renderer

local function firstFontFamily(value)
	if type(value) ~= "string" then
		return ""
	end

	local family = value:match("^[^,]+") or value
	return family:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^['\"]", ""):gsub("['\"]$", "")
end

local function pickFont(style)
	local family = string.lower(firstFontFamily(style["font-family"]))
	if family:find("mono") then
		return Enum.Font.Code
	end
	if family:find("georgia") or family:find("palatino") or family:find("serif") then
		return Enum.Font.Garamond
	end

	if style["font-weight"] == "bold" then
		return Enum.Font.SourceSansBold
	end

	return Enum.Font.SourceSans
end

local function parseHexChannel(hex)
	return tonumber(hex, 16) or 0
end

local function toColor3(value)
	if type(value) ~= "string" then
		return Color3.fromRGB(17, 17, 17)
	end

	if value == "transparent" then
		return Color3.fromRGB(255, 255, 255)
	end

	local shortRed, shortGreen, shortBlue = value:match("^#(%x)(%x)(%x)$")
	if shortRed and shortGreen and shortBlue then
		return Color3.fromRGB(
			parseHexChannel(shortRed .. shortRed),
			parseHexChannel(shortGreen .. shortGreen),
			parseHexChannel(shortBlue .. shortBlue)
		)
	end

	local red, green, blue = value:match("^#(%x%x)(%x%x)(%x%x)$")
	if red and green and blue then
		return Color3.fromRGB(parseHexChannel(red), parseHexChannel(green), parseHexChannel(blue))
	end

	return Color3.fromRGB(17, 17, 17)
end

local function alignmentFor(style)
	local alignment = style["text-align"]
	if alignment == "center" then
		return Enum.TextXAlignment.Center
	end
	if alignment == "right" then
		return Enum.TextXAlignment.Right
	end
	return Enum.TextXAlignment.Left
end

local function addPadding(instance, style)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, style["padding-left"] or 0)
	padding.PaddingRight = UDim.new(0, style["padding-right"] or 0)
	padding.PaddingTop = UDim.new(0, style["padding-top"] or 0)
	padding.PaddingBottom = UDim.new(0, style["padding-bottom"] or 0)
	padding.Parent = instance
	return padding
end

local function resolveViewportValue(value, axis)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

	if type(value) == "number" then
		return value
	end

	if type(value) == "table" then
		if value.unit == "vw" then
			return math.floor(viewport.X * value.value / 100 + 0.5)
		end
		if value.unit == "vh" then
			return math.floor(viewport.Y * value.value / 100 + 0.5)
		end
		if value.unit == "%" then
			local base = axis == "x" and viewport.X or viewport.Y
			return math.floor(base * value.value / 100 + 0.5)
		end
	end

	return axis == "x" and 0 or 0
end

local function resolveSizeValue(value, axis, fallbackScale)
	if value == "auto" or value == nil then
		return nil
	end

	if type(value) == "number" then
		return UDim2.new(0, value, 0, 0)
	end

	if type(value) == "table" then
		if value.unit == "%" then
			if axis == "x" then
				return UDim2.new(value.value / 100, 0, 0, 0)
			end
			return UDim2.new(0, 0, value.value / 100, 0)
		end

		local resolved = resolveViewportValue(value, axis)
		return UDim2.new(0, resolved, 0, 0)
	end

	return fallbackScale
end

local function resolveOffsetValue(value, axis)
	if type(value) == "number" then
		return UDim.new(0, value)
	end

	if type(value) == "table" and value.unit == "%" then
		return UDim.new(value.value / 100, 0)
	end

	if type(value) == "table" then
		return UDim.new(0, resolveViewportValue(value, axis))
	end

	return UDim.new(0, 0)
end

local function createWrapper(parent, style)
	local wrapper = Instance.new("Frame")
	wrapper.Name = "Block"
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel = 0
	wrapper.AutomaticSize = Enum.AutomaticSize.Y
	wrapper.Parent = parent

	if style.position == "absolute" then
		local widthValue = style.width
		local heightValue = style.height
		local left = resolveOffsetValue(style.left, "x")
		local right = resolveOffsetValue(style.right, "x")
		local top = resolveOffsetValue(style.top, "y")
		local marginLeft = style["margin-left"] == "auto" and UDim.new(0, 0) or resolveOffsetValue(style["margin-left"], "x")
		local marginTop = style["margin-top"] == "auto" and UDim.new(0, 0) or resolveOffsetValue(style["margin-top"], "y")
		local marginRight = style["margin-right"] == "auto" and UDim.new(0, 0) or resolveOffsetValue(style["margin-right"], "x")
		local widthScale = type(widthValue) == "table" and widthValue.unit == "%" and widthValue.value / 100 or 0
		local widthOffset = type(widthValue) == "number" and widthValue or (type(widthValue) == "table" and widthValue.unit ~= "%" and resolveViewportValue(widthValue, "x") or 0)
		local heightScale = type(heightValue) == "table" and heightValue.unit == "%" and heightValue.value / 100 or 0
		local heightOffset = type(heightValue) == "number" and heightValue or (type(heightValue) == "table" and heightValue.unit ~= "%" and resolveViewportValue(heightValue, "y") or 0)
		local widthAuto = widthValue == nil or widthValue == "auto"
		local heightAuto = heightValue == nil or heightValue == "auto"

		wrapper.AutomaticSize = Enum.AutomaticSize.None
		wrapper.Size = UDim2.new(widthScale, widthOffset, heightScale, heightOffset)
		if widthAuto and heightAuto then
			wrapper.Size = UDim2.new(0, 0, 0, 0)
			wrapper.AutomaticSize = Enum.AutomaticSize.XY
		elseif widthAuto then
			wrapper.Size = UDim2.new(0, 0, heightScale, heightOffset)
			wrapper.AutomaticSize = Enum.AutomaticSize.X
		elseif heightAuto then
			wrapper.Size = UDim2.new(widthScale, widthOffset, 0, 0)
			wrapper.AutomaticSize = Enum.AutomaticSize.Y
		end
		local positionXScale = left.Scale + marginLeft.Scale
		local positionXOffset = left.Offset + marginLeft.Offset
		if (style.left == nil or style.left == 0)
			and (
				type(style.right) == "table"
				or (type(style.right) == "number" and style.right > 0)
			)
		then
			positionXScale = 1 - right.Scale - marginRight.Scale - widthScale
			positionXOffset = -(right.Offset + marginRight.Offset + widthOffset)
		end
		wrapper.Position = UDim2.new(positionXScale, positionXOffset, top.Scale + marginTop.Scale, top.Offset + marginTop.Offset)
	else
		local widthValue = style.width
		if type(widthValue) == "table" and widthValue.unit == "%" then
			wrapper.Size = UDim2.new(widthValue.value / 100, 0, 0, 0)
		elseif type(widthValue) == "number" and widthValue > 0 then
			wrapper.Size = UDim2.new(0, widthValue, 0, 0)
		else
			wrapper.Size = UDim2.new(1, 0, 0, 0)
		end
	end

	if style.position ~= "absolute" then
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = resolveOffsetValue(style["margin-left"], "x")
		padding.PaddingRight = resolveOffsetValue(style["margin-right"], "x")
		padding.PaddingTop = resolveOffsetValue(style["margin-top"], "y")
		padding.PaddingBottom = resolveOffsetValue(style["margin-bottom"], "y")
		padding.Parent = wrapper
	end

	return wrapper
end

local function renderControlShell(parent, style, defaultWidth, defaultHeight)
	local wrapper = createWrapper(parent, style)

	local shell = Instance.new("Frame")
	shell.Name = "Control"
	shell.BackgroundColor3 = toColor3(style["background-color"] == "transparent" and "#ffffff" or style["background-color"])
	shell.BackgroundTransparency = style["background-color"] == "transparent" and 0 or 0
	shell.BorderSizePixel = 0
	shell.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)

	if type(style.width) == "number" and style.width > 0 then
		shell.Size = UDim2.new(0, style.width, 0, defaultHeight)
	elseif type(style.width) == "table" and style.width.unit == "%" then
		shell.Size = UDim2.new(style.width.value / 100, 0, 0, defaultHeight)
	end

	if type(style.height) == "number" and style.height > 0 then
		shell.Size = UDim2.new(shell.Size.X.Scale, shell.Size.X.Offset, 0, style.height)
	end

	shell.Parent = wrapper
	addPadding(shell, style)
	addBorders(shell, style)
	return wrapper, shell
end

local function addCorner(instance, style)
	local radius = style["border-radius"] or 0
	if radius <= 0 then
		return nil
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

local function addBorderSegment(parent, name, size, position, color)
	local border = Instance.new("Frame")
	border.Name = name
	border.BorderSizePixel = 0
	border.BackgroundColor3 = toColor3(color)
	border.Size = size
	border.Position = position
	border.ZIndex = parent.ZIndex + 1
	border.Parent = parent
	return border
end

local function addBorders(instance, style)
	local topWidth = style["border-top-width"] or 0
	local rightWidth = style["border-right-width"] or 0
	local bottomWidth = style["border-bottom-width"] or 0
	local leftWidth = style["border-left-width"] or 0

	if topWidth > 0 then
		addBorderSegment(
			instance,
			"BorderTop",
			UDim2.new(1, 0, 0, topWidth),
			UDim2.new(0, 0, 0, 0),
			style["border-top-color"]
		)
	end

	if rightWidth > 0 then
		addBorderSegment(
			instance,
			"BorderRight",
			UDim2.new(0, rightWidth, 1, 0),
			UDim2.new(1, -rightWidth, 0, 0),
			style["border-right-color"]
		)
	end

	if bottomWidth > 0 then
		addBorderSegment(
			instance,
			"BorderBottom",
			UDim2.new(1, 0, 0, bottomWidth),
			UDim2.new(0, 0, 1, -bottomWidth),
			style["border-bottom-color"]
		)
	end

	if leftWidth > 0 then
		addBorderSegment(
			instance,
			"BorderLeft",
			UDim2.new(0, leftWidth, 1, 0),
			UDim2.new(0, 0, 0, 0),
			style["border-left-color"]
		)
	end
end

function Renderer.new(options)
	return setmetatable({
		imageResolver = options and options.imageResolver,
		imagePipeline = options and options.imagePipeline,
		baseUrl = options and options.baseUrl or "",
	}, Renderer)
end

function Renderer:createRoot(mount)
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "StaticSite"
	scrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.Size = UDim2.fromScale(1, 1)
	scrollingFrame.CanvasSize = UDim2.new()
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.ScrollBarThickness = 8
	scrollingFrame.ClipsDescendants = true
	scrollingFrame.Parent = mount
	mount.BackgroundColor3 = scrollingFrame.BackgroundColor3
	mount.BackgroundTransparency = 0

	return scrollingFrame
end

function Renderer:renderText(parent, block)
	local wrapper = createWrapper(parent, block.style)

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundColor3 = toColor3(block.style["background-color"])
	label.BackgroundTransparency = block.style["background-color"] == "transparent" and 1 or 0
	label.BorderSizePixel = 0
	label.RichText = true
	label.TextWrapped = true
	label.Text = block.text
	label.TextColor3 = toColor3(block.style.color)
	label.TextXAlignment = alignmentFor(block.style)
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = pickFont(block.style)
	label.TextSize = block.style["font-size"]
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, 0, 0, 0)
	label.Parent = wrapper

	addPadding(label, block.style)
	addBorders(label, block.style)
end

function Renderer:resolveImageSource(source)
	if type(self.imageResolver) == "function" then
		return self.imageResolver(source, self.baseUrl)
	end
	if not source then
		return nil
	end
	return Url.join(self.baseUrl, source)
end

function Renderer:renderImage(parent, block)
	local wrapper = createWrapper(parent, block.style)

	local host = Instance.new("Frame")
	host.Name = "Image"
	host.BackgroundColor3 = toColor3(block.style["background-color"])
	host.BackgroundTransparency = block.style["background-color"] == "transparent" and 1 or 0
	host.BorderSizePixel = 0
	local width = block.style.width
	local height = block.style.height
	if type(width) == "number" and type(height) == "number" and width > 0 and height > 0 then
		host.Size = UDim2.new(0, width, 0, height)
	else
		host.Size = UDim2.new(0, 140, 0, 140)
	end
	host.Parent = wrapper
	addBorders(host, block.style)

	if self.imagePipeline then
		if self.imagePipeline:apply(host, block.source, self.baseUrl) then
			return
		end
	end

	local resolved = self:resolveImageSource(block.source)
	if resolved and resolved:match("^rbx") then
		local image = Instance.new("ImageLabel")
		image.Name = "AssetImage"
		image.BackgroundTransparency = 1
		image.BorderSizePixel = 0
		image.ScaleType = Enum.ScaleType.Fit
		image.Size = UDim2.new(1, 0, 1, 0)
		image.Image = resolved
		image.Parent = host
	else
		host.Visible = false
	end
end

function Renderer:renderContainer(parent, block)
	local wrapper = createWrapper(parent, block.style)

	local container = Instance.new("Frame")
	container.Name = block.tag
	container.BackgroundColor3 = toColor3(block.style["background-color"])
	container.BackgroundTransparency = block.style["background-color"] == "transparent" and 1 or 0
	container.BorderSizePixel = 0
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Parent = wrapper
	addCorner(container, block.style)
	addBorders(container, block.style)

	local width = block.style.width
	if type(width) == "table" and width.unit == "%" then
		container.Size = UDim2.new(width.value / 100, 0, 0, 0)
	elseif type(width) == "number" and width > 0 then
		container.Size = UDim2.new(0, width, 0, 0)
	else
		container.Size = UDim2.new(1, 0, 0, 0)
	end

	if block.style["margin-left"] == "auto" and block.style["margin-right"] == "auto" and type(width) == "number" and width > 0 then
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.Position = UDim2.new(0.5, 0, 0, 0)
	end

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Parent = container

	addPadding(content, block.style)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = content

	for _, child in ipairs(block.children) do
		self:renderBlock(content, child)
	end
end

function Renderer:renderControl(parent, block)
	local controlType = block.controlType
	if controlType == "submit" or controlType == "button" then
		local _, shell = renderControlShell(parent, block.style, 72, 24)
		local label = Instance.new("TextLabel")
		label.Name = "ButtonLabel"
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Font = pickFont(block.style)
		label.TextSize = block.style["font-size"]
		label.TextColor3 = toColor3(block.style.color)
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = block.text ~= "" and block.text or "Submit"
		label.Parent = shell
		return
	end

	local _, shell = renderControlShell(parent, block.style, 176, 24)
	local label = Instance.new("TextLabel")
	label.Name = "InputValue"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.new(0, 4, 0, 0)
	label.Font = pickFont(block.style)
	label.TextSize = block.style["font-size"]
	label.TextColor3 = toColor3(block.style.color)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = block.text
	label.Parent = shell
end

function Renderer:renderBlock(parent, block)
	if block.kind == "text" then
		self:renderText(parent, block)
	elseif block.kind == "image" then
		self:renderImage(parent, block)
	elseif block.kind == "control" then
		self:renderControl(parent, block)
	elseif block.kind == "container" then
		self:renderContainer(parent, block)
	end
end

function Renderer:render(mount, tree)
	local root = self:createRoot(mount)
	root.BackgroundColor3 = toColor3(tree.style["background-color"])
	root.BackgroundTransparency = tree.style["background-color"] == "transparent" and 1 or 0

	local bodyHost = Instance.new("Frame")
	bodyHost.Name = "Body"
	bodyHost.BackgroundTransparency = 1
	bodyHost.BorderSizePixel = 0
	bodyHost.Position = UDim2.new(0, 0, 0, 0)
	bodyHost.AutomaticSize = Enum.AutomaticSize.Y
	bodyHost.Parent = root

	local absoluteHost = Instance.new("Frame")
	absoluteHost.Name = "AbsoluteBody"
	absoluteHost.BackgroundTransparency = 1
	absoluteHost.BorderSizePixel = 0
	absoluteHost.Position = UDim2.new(0, 0, 0, 0)
	absoluteHost.Size = UDim2.new(1, 0, 0, 0)
	absoluteHost.AutomaticSize = Enum.AutomaticSize.Y
	absoluteHost.Parent = root

	local topMargin = resolveViewportValue(tree.style["margin-top"], "y")
	local width = tree.style.width
	if type(width) == "table" then
		width = resolveViewportValue(width, "x")
	end

	if type(width) == "table" and width.unit == "%" then
		bodyHost.Size = UDim2.new(width.value / 100, 0, 0, 0)
	elseif type(width) == "number" and width > 0 then
		bodyHost.Size = UDim2.new(0, width, 0, 0)
	else
		bodyHost.Size = UDim2.new(1, 0, 0, 0)
	end

	local bodyPadding = Instance.new("UIPadding")
	bodyPadding.PaddingTop = UDim.new(0, topMargin)
	bodyPadding.PaddingLeft = UDim.new(0, tree.style["padding-left"] or 0)
	bodyPadding.PaddingRight = UDim.new(0, tree.style["padding-right"] or 0)
	bodyPadding.PaddingBottom = UDim.new(0, tree.style["padding-bottom"] or 0)
	bodyPadding.Parent = bodyHost

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bodyHost

	for _, child in ipairs(tree.children) do
		if child.style.position == "absolute" then
			self:renderBlock(absoluteHost, child)
		else
			self:renderBlock(bodyHost, child)
		end
	end

	task.defer(function()
		local maxBottom = root.AbsoluteWindowSize.Y
		for _, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("GuiObject") and descendant.Visible then
				local relativeY = descendant.AbsolutePosition.Y - root.AbsolutePosition.Y
				local bottom = relativeY + descendant.AbsoluteSize.Y
				if bottom > maxBottom then
					maxBottom = bottom
				end
			end
		end
		root.CanvasSize = UDim2.new(0, 0, 0, math.floor(maxBottom + 16))
	end)

	return root
end

return Renderer
