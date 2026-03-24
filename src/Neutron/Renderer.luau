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
	if family:find("serif") then
		return Enum.Font.SourceSans
	end
	if style["font-weight"] == "bold" then
		return Enum.Font.GothamBold
	end
	return Enum.Font.Gotham
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
	if type(value) == "number" then
		return value
	end

	if type(value) == "table" then
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		if value.unit == "vw" then
			return math.floor(viewport.X * value.value / 100 + 0.5)
		end
		if value.unit == "vh" then
			return math.floor(viewport.Y * value.value / 100 + 0.5)
		end
	end

	return axis == "x" and 0 or 0
end

local function createWrapper(parent, style)
	local wrapper = Instance.new("Frame")
	wrapper.Name = "Block"
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel = 0
	wrapper.Size = UDim2.new(1, 0, 0, 0)
	wrapper.AutomaticSize = Enum.AutomaticSize.Y
	wrapper.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, style["margin-left"] or 0)
	padding.PaddingRight = UDim.new(0, style["margin-right"] or 0)
	padding.PaddingTop = UDim.new(0, style["margin-top"] or 0)
	padding.PaddingBottom = UDim.new(0, style["margin-bottom"] or 0)
	padding.Parent = wrapper

	return wrapper
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

function Renderer.new(options)
	return setmetatable({
		imageResolver = options and options.imageResolver,
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
	scrollingFrame.Parent = mount
	mount.BackgroundColor3 = scrollingFrame.BackgroundColor3
	mount.BackgroundTransparency = 0

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = scrollingFrame

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

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.BackgroundColor3 = toColor3(block.style["background-color"])
	image.BackgroundTransparency = block.style["background-color"] == "transparent" and 1 or 0
	image.BorderSizePixel = 0
	image.ScaleType = Enum.ScaleType.Fit
	image.Size = UDim2.new(1, 0, 0, 240)
	image.Parent = wrapper

	local resolved = self:resolveImageSource(block.source)
	if resolved then
		image.Image = resolved
	else
		image.Visible = false
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

	local width = block.style.width
	if type(width) == "number" and width > 0 then
		container.Size = UDim2.new(0, width, 0, 0)
	else
		container.Size = UDim2.new(1, 0, 0, 0)
	end

	if block.style["margin-left"] == "auto" and block.style["margin-right"] == "auto" and type(width) == "number" and width > 0 then
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.Position = UDim2.new(0.5, 0, 0, 0)
	end

	addPadding(container, block.style)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = container

	for _, child in ipairs(block.children) do
		self:renderBlock(container, child)
	end
end

function Renderer:renderBlock(parent, block)
	if block.kind == "text" then
		self:renderText(parent, block)
	elseif block.kind == "image" then
		self:renderImage(parent, block)
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
	bodyHost.AutomaticSize = Enum.AutomaticSize.Y
	bodyHost.Parent = root

	local topMargin = resolveViewportValue(tree.style["margin-top"], "y")
	local width = tree.style.width
	if type(width) == "table" then
		width = resolveViewportValue(width, "x")
	end

	if type(width) == "number" and width > 0 then
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
		self:renderBlock(bodyHost, child)
	end

	return root
end

return Renderer
