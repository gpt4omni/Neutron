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
- `release/Neutron.module.lua`: single-file Studio distribution
- `examples/Example.server.luau`: server HTTP bridge setup
- `examples/Example.client.luau`: client rendering example

## Usage

```lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Neutron = require(ReplicatedStorage.Neutron)
local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "NeutronFetch"
remoteFunction.Parent = ReplicatedStorage

Neutron.Fetcher.bindRemoteFunction(remoteFunction, HttpService, {
	transformUrl = function(url)
		return "https://r.jina.ai/http://" .. url:gsub("^https?://", "")
	end,
})

local renderer = Neutron.new({ fetcher = Neutron.Fetcher.fromRemoteFunction(remoteFunction) })

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mount = Instance.new("Frame")
mount.Size = UDim2.fromScale(1, 1)
mount.Parent = screenGui

renderer:renderUrl("https://example.com", mount)
```

## Client And Server

- `renderHtml()` works on both client and server because it only parses and renders text you already have
- `renderUrl()` requires a fetcher
- Roblox HTTP requests only run on the server, so a `LocalScript` should use `Fetcher.fromRemoteFunction()`
- `Fetcher.bindRemoteFunction()` wires a server `RemoteFunction` to a normal HTTP fetcher

## Studio Release

Use `release/Neutron.module.lua` as the importable file. Create a `ModuleScript` named `Neutron` in Studio, paste the contents of that file into it, and require it directly.

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
- `Fetcher.new(HttpService, options)` is for server-side HTTP
- `Fetcher.fromRemoteFunction(remoteFunction, options)` is for client-side fetching through a server bridge

## Limits

- This is a static renderer, not a browser engine
- JavaScript execution is not supported
- CSS coverage is intentionally small
- Arbitrary web pages may still need a proxy or a content adapter before Roblox can fetch them cleanly
