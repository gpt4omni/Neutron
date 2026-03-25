local RunService = game:GetService("RunService")

local Url = require(script.Parent.Url)
local ImageCompression = require(script.Parent.ImageCompression)

local ImagePipeline = {}
ImagePipeline.__index = ImagePipeline

local function trimCache(cacheOrder, cache, maxCacheSize)
	while #cacheOrder > maxCacheSize do
		local oldest = table.remove(cacheOrder, 1)
		cache[oldest] = nil
	end
end

local function touch(cacheOrder, key)
	for index, existing in ipairs(cacheOrder) do
		if existing == key then
			table.remove(cacheOrder, index)
			break
		end
	end

	table.insert(cacheOrder, key)
end

local function paletteColorToColor3(color)
	return Color3.fromRGB(color[1], color[2], color[3])
end

local function alphaToTransparency(color)
	return 1 - ((color[4] or 255) / 255)
end

local function encodeQueryComponent(value)
	return tostring(value)
		:gsub("\n", "\r\n")
		:gsub("([^%w%-_%.~])", function(char)
			return string.format("%%%02X", string.byte(char))
		end)
end

local function buildBridgeUrl(baseUrl, source, constraints)
	local separator = baseUrl:find("?", 1, true) and "&" or "?"
	local query = table.concat({
		"url=" .. encodeQueryComponent(source),
		"max_width=" .. encodeQueryComponent(constraints.maxWidth),
		"max_height=" .. encodeQueryComponent(constraints.maxHeight),
		"max_colors=" .. encodeQueryComponent(constraints.maxColors),
		"dither_strength=" .. encodeQueryComponent(constraints.ditherStrength),
	}, "&")

	return baseUrl .. separator .. query
end

function ImagePipeline.new(options)
	options = options or {}

	local self = setmetatable({
		cache = {},
		cacheOrder = {},
		cacheSize = options.cacheSize or 32,
		maxWidth = options.maxWidth or 128,
		maxHeight = options.maxHeight or 72,
		maxColors = options.maxColors or 16,
		ditherStrength = options.ditherStrength == nil and 0.2 or options.ditherStrength,
		maxRunsPerFrame = options.maxRunsPerFrame or 160,
		maxPixelsPerFrame = options.maxPixelsPerFrame or 10000,
		skipBelowPixels = options.skipBelowPixels or 256,
		pixelScale = options.pixelScale or 2,
		fetchPayload = options.fetchPayload,
		remoteFunction = options.remoteFunction,
		framePool = {},
		pendingJobs = {},
		renderConnection = nil,
	}, ImagePipeline)

	self:startScheduler()
	return self
end

function ImagePipeline:startScheduler()
	if self.renderConnection then
		return
	end

	self.renderConnection = RunService.Heartbeat:Connect(function()
		self:processQueue()
	end)
end

function ImagePipeline:processQueue()
	local runBudget = self.maxRunsPerFrame
	local pixelBudget = self.maxPixelsPerFrame

	while runBudget > 0 and pixelBudget > 0 and #self.pendingJobs > 0 do
		local job = self.pendingJobs[1]
		local host = job.host
		if host == nil or host.Parent == nil then
			table.remove(self.pendingJobs, 1)
			continue
		end

		local rowRuns = job.payload.rows[job.rowIndex]
		if not rowRuns then
			table.remove(self.pendingJobs, 1)
			continue
		end

		local x = 0
		for runIndex = job.runIndex, #rowRuns do
			local run = rowRuns[runIndex]
			local runPixelCost = run.count * job.pixelSize * job.pixelSize
			if runPixelCost > pixelBudget and job.runIndex == runIndex then
				return
			end

			local frame = self:acquireFrame(host)
			local paletteColor = job.payload.palette[run.color]
			frame.Size = UDim2.new(0, run.count * job.pixelSize, 0, job.pixelSize)
			frame.Position = UDim2.new(0, x * job.pixelSize, 0, (job.rowIndex - 1) * job.pixelSize)
			frame.BackgroundColor3 = paletteColorToColor3(paletteColor)
			frame.BackgroundTransparency = alphaToTransparency(paletteColor)
			frame.Visible = true

			x += run.count
			job.runIndex = runIndex + 1
			runBudget -= 1
			pixelBudget -= runPixelCost

			if runBudget <= 0 or pixelBudget <= 0 then
				return
			end
		end

		job.rowIndex += 1
		job.runIndex = 1
	end
end

function ImagePipeline:acquireFrame(parent)
	local frame = table.remove(self.framePool)
	if not frame then
		frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
	end

	frame.Parent = parent
	return frame
end

function ImagePipeline:clearHost(host)
	for _, child in ipairs(host:GetChildren()) do
		if child:IsA("Frame") and child.Name == "ImageRun" then
			child.Parent = nil
			child.Visible = false
			table.insert(self.framePool, child)
		elseif child.Name == "AssetImage" then
			child:Destroy()
		end
	end
end

function ImagePipeline:resolveSource(source, baseUrl)
	if type(source) ~= "string" or source == "" then
		return nil
	end

	if source:match("^rbxassetid://") or source:match("^rbxthumb://") or source:match("^rbxasset://") then
		return source
	end

	return Url.join(baseUrl, source)
end

function ImagePipeline:getPayload(source)
	if type(self.fetchPayload) == "function" then
		return self.fetchPayload(source, {
			maxWidth = self.maxWidth,
			maxHeight = self.maxHeight,
			maxColors = self.maxColors,
			ditherStrength = self.ditherStrength,
		})
	end

	if self.remoteFunction then
		return self.remoteFunction:InvokeServer(source, {
			maxWidth = self.maxWidth,
			maxHeight = self.maxHeight,
			maxColors = self.maxColors,
			ditherStrength = self.ditherStrength,
		})
	end

	return nil
end

function ImagePipeline:getEntry(source)
	local cached = self.cache[source]
	if cached then
		touch(self.cacheOrder, source)
		return cached
	end

	local payload = self:getPayload(source)
	if not payload then
		return nil
	end

	self.cache[source] = payload
	touch(self.cacheOrder, source)
	trimCache(self.cacheOrder, self.cache, self.cacheSize)
	return payload
end

function ImagePipeline:renderAsset(host, source)
	self:clearHost(host)

	local image = Instance.new("ImageLabel")
	image.Name = "AssetImage"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.ScaleType = Enum.ScaleType.Fit
	image.Size = UDim2.new(1, 0, 1, 0)
	image.Image = source
	image.Parent = host
	host.Visible = true
	return true
end

function ImagePipeline:renderPaletteRle(host, payload)
	self:clearHost(host)

	local pixelSize = math.max(1, self.pixelScale)
	local renderWidth = payload.width * pixelSize
	local renderHeight = payload.height * pixelSize

	if renderWidth * renderHeight < self.skipBelowPixels then
		host.Visible = false
		return false
	end

	host.Size = UDim2.new(0, renderWidth, 0, renderHeight)
	host.Visible = true

	table.insert(self.pendingJobs, {
		host = host,
		payload = payload,
		rowIndex = 1,
		runIndex = 1,
		pixelSize = pixelSize,
	})

	return true
end

function ImagePipeline:apply(host, source, baseUrl)
	local resolved = self:resolveSource(source, baseUrl)
	if not resolved then
		host.Visible = false
		return false
	end

	if resolved:match("^rbxassetid://") or resolved:match("^rbxthumb://") or resolved:match("^rbxasset://") then
		return self:renderAsset(host, resolved)
	end

	local payload = self:getEntry(resolved)
	if not payload then
		host.Visible = false
		return false
	end

	if payload.format == "asset" then
		return self:renderAsset(host, payload.image)
	end

	if payload.format == "palette-rle" then
		return self:renderPaletteRle(host, payload)
	end

	host.Visible = false
	return false
end

function ImagePipeline.createRemoteHandler(payloadProvider)
	return function(_, source, constraints)
		return payloadProvider(source, constraints)
	end
end

function ImagePipeline.bindRemoteFunction(remoteFunction, payloadProvider)
	remoteFunction.OnServerInvoke = ImagePipeline.createRemoteHandler(payloadProvider)
	return remoteFunction
end

function ImagePipeline.createBridgePayloadProvider(httpService, bridgeUrl, options)
	assert(httpService, "ImagePipeline.createBridgePayloadProvider requires HttpService")
	assert(type(bridgeUrl) == "string" and bridgeUrl ~= "", "ImagePipeline.createBridgePayloadProvider requires bridgeUrl")

	options = options or {}
	local headers = options.headers or {}
	local transformUrl = options.transformUrl

	return function(source, constraints)
		local resolvedSource = source
		if type(transformUrl) == "function" then
			resolvedSource = transformUrl(source)
		end

		local requestUrl = buildBridgeUrl(bridgeUrl, resolvedSource, constraints)
		local response = httpService:GetAsync(requestUrl, false, next(headers) ~= nil and headers or nil)
		return httpService:JSONDecode(response)
	end
end

function ImagePipeline.bindBridgeRemoteFunction(remoteFunction, httpService, bridgeUrl, options)
	local payloadProvider = ImagePipeline.createBridgePayloadProvider(httpService, bridgeUrl, options)
	return ImagePipeline.bindRemoteFunction(remoteFunction, payloadProvider)
end

ImagePipeline.ImageCompression = ImageCompression

return ImagePipeline
