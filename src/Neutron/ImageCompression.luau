local ImageCompression = {}

local DEFAULT_PALETTE = {
	{ 0, 0, 0, 255 },
	{ 255, 255, 255, 255 },
	{ 34, 34, 34, 255 },
	{ 96, 96, 96, 255 },
	{ 176, 176, 176, 255 },
	{ 220, 220, 220, 255 },
	{ 171, 65, 52, 255 },
	{ 224, 123, 57, 255 },
	{ 234, 200, 77, 255 },
	{ 87, 166, 74, 255 },
	{ 53, 116, 73, 255 },
	{ 71, 132, 201, 255 },
	{ 52, 72, 136, 255 },
	{ 122, 90, 165, 255 },
	{ 191, 117, 187, 255 },
	{ 214, 160, 137, 255 },
}

local DITHER_MATRIX = {
	{ 0, 8, 2, 10 },
	{ 12, 4, 14, 6 },
	{ 3, 11, 1, 9 },
	{ 15, 7, 13, 5 },
}

local function clamp(value, minimum, maximum)
	if value < minimum then
		return minimum
	end
	if value > maximum then
		return maximum
	end
	return value
end

local function calculateTargetSize(width, height, maxWidth, maxHeight)
	if width <= 0 or height <= 0 then
		return 1, 1
	end

	local scale = math.min(maxWidth / width, maxHeight / height, 1)
	return math.max(1, math.floor(width * scale + 0.5)), math.max(1, math.floor(height * scale + 0.5))
end

local function sampleNearest(width, height, pixels, targetX, targetY, targetWidth, targetHeight)
	local sourceX = math.min(width - 1, math.floor(targetX * width / targetWidth))
	local sourceY = math.min(height - 1, math.floor(targetY * height / targetHeight))
	local pixelIndex = sourceY * width * 4 + sourceX * 4 + 1

	return pixels[pixelIndex] or 0,
		pixels[pixelIndex + 1] or 0,
		pixels[pixelIndex + 2] or 0,
		pixels[pixelIndex + 3] or 255
end

local function nearestPaletteIndex(red, green, blue, alpha, palette)
	local bestIndex = 1
	local bestDistance = math.huge

	for index, color in ipairs(palette) do
		local distance = math.abs(red - color[1])
			+ math.abs(green - color[2])
			+ math.abs(blue - color[3])
			+ math.abs(alpha - color[4]) * 2

		if distance < bestDistance then
			bestDistance = distance
			bestIndex = index
		end
	end

	return bestIndex
end

local function addFallbackColors(palette, maxColors)
	local existing = {}
	for _, color in ipairs(palette) do
		existing[string.format("%d:%d:%d:%d", color[1], color[2], color[3], color[4])] = true
	end

	for _, color in ipairs(DEFAULT_PALETTE) do
		if #palette >= maxColors then
			break
		end

		local key = string.format("%d:%d:%d:%d", color[1], color[2], color[3], color[4])
		if not existing[key] then
			existing[key] = true
			table.insert(palette, { color[1], color[2], color[3], color[4] })
		end
	end
end

local function buildAdaptivePalette(width, height, pixels, targetWidth, targetHeight, maxColors)
	local buckets = {}
	local transparentPixels = 0

	for targetY = 0, targetHeight - 1 do
		for targetX = 0, targetWidth - 1 do
			local red, green, blue, alpha = sampleNearest(width, height, pixels, targetX, targetY, targetWidth, targetHeight)
			if alpha < 32 then
				transparentPixels += 1
			else
				local redBucket = math.floor(red / 32)
				local greenBucket = math.floor(green / 32)
				local blueBucket = math.floor(blue / 32)
				local key = redBucket * 64 + greenBucket * 8 + blueBucket
				local bucket = buckets[key]
				if bucket then
					bucket.count += 1
					bucket.red += red
					bucket.green += green
					bucket.blue += blue
					bucket.alpha += alpha
				else
					buckets[key] = {
						count = 1,
						red = red,
						green = green,
						blue = blue,
						alpha = alpha,
					}
				end
			end
		end
	end

	local ranked = {}
	for _, bucket in pairs(buckets) do
		table.insert(ranked, bucket)
	end

	table.sort(ranked, function(left, right)
		return left.count > right.count
	end)

	local palette = {}
	if transparentPixels > 0 then
		table.insert(palette, { 0, 0, 0, 0 })
	end

	local limit = math.max(1, maxColors - #palette)
	for index = 1, math.min(limit, #ranked) do
		local bucket = ranked[index]
		table.insert(palette, {
			math.floor(bucket.red / bucket.count + 0.5),
			math.floor(bucket.green / bucket.count + 0.5),
			math.floor(bucket.blue / bucket.count + 0.5),
			math.floor(bucket.alpha / bucket.count + 0.5),
		})
	end

	addFallbackColors(palette, maxColors)
	return palette
end

local function buildPalette(width, height, pixels, targetWidth, targetHeight, options)
	local maxColors = clamp(options and options.maxColors or 16, 2, 16)
	local providedPalette = options and options.palette
	if providedPalette then
		local palette = {}
		for index = 1, math.min(maxColors, #providedPalette) do
			local color = providedPalette[index]
			table.insert(palette, {
				clamp(color[1] or 0, 0, 255),
				clamp(color[2] or 0, 0, 255),
				clamp(color[3] or 0, 0, 255),
				clamp(color[4] or 255, 0, 255),
			})
		end
		addFallbackColors(palette, maxColors)
		return palette
	end

	return buildAdaptivePalette(width, height, pixels, targetWidth, targetHeight, maxColors)
end

function ImageCompression.encode(width, height, pixels, options)
	options = options or {}

	local targetWidth, targetHeight = calculateTargetSize(
		width,
		height,
		options.maxWidth or 128,
		options.maxHeight or 72
	)
	local palette = buildPalette(width, height, pixels, targetWidth, targetHeight, options)
	local rows = {}
	local ditherStrength = options.ditherStrength == nil and 0.2 or options.ditherStrength

	for targetY = 0, targetHeight - 1 do
		local rowRuns = {}
		local lastIndex = nil
		local runLength = 0

		local function flush()
			if lastIndex == nil or runLength == 0 then
				return
			end

			table.insert(rowRuns, {
				color = lastIndex,
				count = runLength,
			})
		end

		for targetX = 0, targetWidth - 1 do
			local red, green, blue, alpha = sampleNearest(width, height, pixels, targetX, targetY, targetWidth, targetHeight)
			if ditherStrength > 0 and alpha >= 32 then
				local threshold = DITHER_MATRIX[targetY % 4 + 1][targetX % 4 + 1] - 7.5
				local adjustment = threshold * ditherStrength
				red = clamp(red + adjustment, 0, 255)
				green = clamp(green + adjustment, 0, 255)
				blue = clamp(blue + adjustment, 0, 255)
			end

			local paletteIndex = nearestPaletteIndex(red, green, blue, alpha, palette)
			if paletteIndex == lastIndex then
				runLength += 1
			else
				flush()
				lastIndex = paletteIndex
				runLength = 1
			end
		end

		flush()
		table.insert(rows, rowRuns)
	end

	return {
		format = "palette-rle",
		width = targetWidth,
		height = targetHeight,
		palette = palette,
		rows = rows,
	}
end

function ImageCompression.createAssetPayload(image)
	return {
		format = "asset",
		image = image,
	}
end

return ImageCompression
