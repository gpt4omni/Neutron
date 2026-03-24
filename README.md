# Neutron

Neutron is a modular Luau static-site renderer for Roblox. It parses HTML, resolves a small CSS subset, builds a simple layout tree, and renders the result into Roblox GUI objects.

## Structure

- `src/Neutron/init.luau`: public API
- `src/Neutron/Fetcher.luau`: HTTP and proxy integration
- `src/Neutron/HtmlTokenizer.luau`: tokenization
- `src/Neutron/HtmlParser.luau`: DOM building
- `src/Neutron/CssParser.luau`: CSS parsing
- `src/Neutron/StyleResolver.luau`: computed styles
- `src/Neutron/LayoutEngine.luau`: block tree generation
- `src/Neutron/Renderer.luau`: Roblox GUI rendering

## Usage

```lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Neutron = require(ReplicatedStorage.Neutron)

local fetcher = Neutron.Fetcher.new(HttpService, {
	proxyTemplate = "https://r.jina.ai/http://{url}",
})

local renderer = Neutron.new({
	fetcher = fetcher,
})

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mount = Instance.new("Frame")
mount.Size = UDim2.fromScale(1, 1)
mount.Parent = screenGui

renderer:renderUrl("https://example.com", mount)
```

## Supported Features

- HTML text nodes and common structural tags
- Basic inline and embedded CSS
- Tag, class, and id selectors
- Block layout with margins and padding
- Text styling with Roblox RichText
- Optional proxy-based fetching for public websites

## Fetch Options

- `proxyTemplate` supports both `{url}` and `{url_encoded}`
- `transformUrl` lets you provide your own URL rewrite logic

## Limits

- This is a static renderer, not a browser engine
- JavaScript execution is not supported
- CSS coverage is intentionally small
- Arbitrary web pages may still need a proxy or a content adapter before Roblox can fetch them cleanly
