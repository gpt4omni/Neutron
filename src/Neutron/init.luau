local HtmlParser = require(script.HtmlParser)
local StyleResolver = require(script.StyleResolver)
local LayoutEngine = require(script.LayoutEngine)
local Renderer = require(script.Renderer)
local Fetcher = require(script.Fetcher)

local Neutron = {}
Neutron.__index = Neutron

function Neutron.new(options)
	local self = setmetatable({}, Neutron)
	self.fetcher = options and options.fetcher
	self.rendererOptions = options and options.rendererOptions or {}
	return self
end

function Neutron:renderHtml(html, mount, options)
	local parsed = HtmlParser.parse(html)
	local computed = StyleResolver.resolve(parsed)
	local layoutTree = LayoutEngine.build(computed)
	local rendererOptions = {}

	for key, value in pairs(self.rendererOptions) do
		rendererOptions[key] = value
	end

	if options and options.baseUrl then
		rendererOptions.baseUrl = options.baseUrl
	end

	local renderer = Renderer.new(rendererOptions)
	return renderer:render(mount, layoutTree)
end

function Neutron:renderUrl(url, mount)
	assert(self.fetcher, "Neutron.renderUrl requires a fetcher")
	local html = self.fetcher:fetch(url)
	return self:renderHtml(html, mount, {
		baseUrl = url,
	})
end

Neutron.Fetcher = Fetcher
Neutron.HtmlParser = HtmlParser
Neutron.StyleResolver = StyleResolver
Neutron.LayoutEngine = LayoutEngine
Neutron.Renderer = Renderer

return Neutron
