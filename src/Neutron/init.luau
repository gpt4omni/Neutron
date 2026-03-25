local HtmlParser = require(script.HtmlParser)
local HtmlTokenizer = require(script.HtmlTokenizer)
local StyleResolver = require(script.StyleResolver)
local LayoutEngine = require(script.LayoutEngine)
local Renderer = require(script.Renderer)
local Fetcher = require(script.Fetcher)
local ImagePipeline = require(script.ImagePipeline)
local ImageCompression = require(script.ImageCompression)

local Neutron = {}
Neutron.__index = Neutron

local function escapeHtml(value)
	return value
		:gsub("&", "&amp;")
		:gsub("<", "&lt;")
		:gsub(">", "&gt;")
		:gsub("\"", "&quot;")
		:gsub("'", "&apos;")
end

local function containsHtmlMarkup(value)
	return value:find("<%s*[%a!/]", 1) ~= nil
end

local function wrapPlainTextAsHtml(value)
	local normalized = value:gsub("\r\n", "\n")
	local blocks = {}

	for line in normalized:gmatch("[^\n]+") do
		if line:match("%S") then
			table.insert(blocks, "<p>" .. escapeHtml(line) .. "</p>")
		end
	end

	if #blocks == 0 then
		table.insert(blocks, "<p></p>")
	end

	return "<html><body>" .. table.concat(blocks, "") .. "</body></html>"
end

local function normalizeDocumentSource(html)
	if containsHtmlMarkup(html) then
		return html
	end

	return wrapPlainTextAsHtml(html)
end

local function extractStylesheetHrefs(html)
	local hrefs = {}

	for _, token in ipairs(HtmlTokenizer.tokenize(html)) do
		if token.type ~= "openTag" or token.name ~= "link" then
			continue
		end

		local relValue = string.lower(tostring(token.attributes.rel or ""))
		local mediaValue = string.lower(tostring(token.attributes.media or "screen"))
		local href = token.attributes.href
		if type(href) ~= "string" or href == "" then
			continue
		end

		if not relValue:find("stylesheet", 1, true) then
			continue
		end

		if relValue:find("alternate", 1, true) then
			continue
		end

		if mediaValue:find("print", 1, true) then
			continue
		end

		if not (mediaValue:find("screen", 1, true) or mediaValue:find("all", 1, true)) then
			continue
		end

		if href:find("netscape4.css", 1, true) then
			continue
		end

		table.insert(hrefs, href)
	end
	return hrefs
end

local function extractImportedStylesheetHrefs(css)
	local hrefs = {}
	for href in css:gmatch("@import%s+url%([\"']?([^\"')]+)[\"']?%)") do
		table.insert(hrefs, href)
	end
	for href in css:gmatch("@import%s+[\"']([^\"']+)[\"']") do
		table.insert(hrefs, href)
	end
	return hrefs
end

local function fetchStylesheetTree(fetcher, href, visited)
	local absoluteHref = href
	if visited[absoluteHref] then
		return {}
	end

	visited[absoluteHref] = true

	local ok, css = pcall(function()
		return fetcher:fetch(absoluteHref)
	end)
	if not ok or type(css) ~= "string" or css == "" then
		return {}
	end

	local parts = {}
	for _, importedHref in ipairs(extractImportedStylesheetHrefs(css)) do
		local joined = importedHref
		if absoluteHref:match("^https?://") then
			joined = require(script.Url).join(absoluteHref, importedHref)
		end
		for _, importedCss in ipairs(fetchStylesheetTree(fetcher, joined, visited)) do
			table.insert(parts, importedCss)
		end
	end

	local strippedCss = css
		:gsub("@import%s+url%([\"']?([^\"')]+)[\"']?%)[^;]*;", "")
		:gsub("@import%s+[\"']([^\"']+)[\"'][^;]*;", "")
	table.insert(parts, strippedCss)
	return parts
end

local function fetchExternalStyles(fetcher, baseUrl, html)
	if not fetcher then
		return {}
	end

	local styles = {}
	local visited = {}
	for _, href in ipairs(extractStylesheetHrefs(html)) do
		local absoluteHref = href
		if not href:match("^https?://") then
			absoluteHref = require(script.Url).join(baseUrl, href)
		end
		for _, css in ipairs(fetchStylesheetTree(fetcher, absoluteHref, visited)) do
			table.insert(styles, css)
		end
	end
	return styles
end

local function createDefaultImagePipeline(rendererOptions)
	local remoteFunction = rendererOptions.imageRemoteFunction
	local fetchPayload = rendererOptions.imageFetchPayload

	if remoteFunction == nil and fetchPayload == nil then
		return nil
	end

	return ImagePipeline.new({
		remoteFunction = remoteFunction,
		fetchPayload = fetchPayload,
		cacheSize = rendererOptions.imageCacheSize or 32,
		maxWidth = rendererOptions.imageMaxWidth or 128,
		maxHeight = rendererOptions.imageMaxHeight or 72,
		maxColors = rendererOptions.imageMaxColors or 16,
		ditherStrength = rendererOptions.imageDitherStrength,
		maxRunsPerFrame = rendererOptions.imageMaxRunsPerFrame or 160,
		maxPixelsPerFrame = rendererOptions.imageMaxPixelsPerFrame or 10000,
		skipBelowPixels = rendererOptions.imageSkipBelowPixels or 256,
		pixelScale = rendererOptions.imagePixelScale or 2,
	})
end

function Neutron.new(options)
	local self = setmetatable({}, Neutron)
	self.fetcher = options and options.fetcher
	self.rendererOptions = options and options.rendererOptions or {}
	return self
end

function Neutron:renderHtml(html, mount, options)
	local parsed = HtmlParser.parse(normalizeDocumentSource(html))
	local computed = StyleResolver.resolve(parsed, options and options.externalStyles)
	local layoutTree = LayoutEngine.build(computed)
	local rendererOptions = {}

	for key, value in pairs(self.rendererOptions) do
		rendererOptions[key] = value
	end

	if options and options.baseUrl then
		rendererOptions.baseUrl = options.baseUrl
	end

	if rendererOptions.imagePipeline == nil then
		rendererOptions.imagePipeline = createDefaultImagePipeline(rendererOptions)
	end

	local renderer = Renderer.new(rendererOptions)
	return renderer:render(mount, layoutTree)
end

function Neutron:renderUrl(url, mount)
	assert(self.fetcher, "Neutron.renderUrl requires a fetcher")
	local html = self.fetcher:fetch(url)
	local externalStyles = fetchExternalStyles(self.fetcher, url, html)
	return self:renderHtml(html, mount, {
		baseUrl = url,
		externalStyles = externalStyles,
	})
end

Neutron.Fetcher = Fetcher
Neutron.ImagePipeline = ImagePipeline
Neutron.ImageCompression = ImageCompression
Neutron.HtmlParser = HtmlParser
Neutron.StyleResolver = StyleResolver
Neutron.LayoutEngine = LayoutEngine
Neutron.Renderer = Renderer

return Neutron
