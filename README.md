<div align="center">

# ⚛️ Neutron

A modular Luau static-site renderer for Roblox. Parse HTML, resolve CSS, and render the result straight into Roblox GUI objects.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Lua](https://img.shields.io/badge/Lua-47.8%25-blue?logo=lua)
![Luau](https://img.shields.io/badge/Luau-45.5%25-orange)
![Python](https://img.shields.io/badge/Python-6.7%25-yellow?logo=python)

</div>

> ⚠️ We're not responsible for any action Roblox takes against you for using this. Use it at your own risk.

---

## Quick Start

```lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Neutron = require(ReplicatedStorage.Neutron)

-- Server: set up the fetch bridge
local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "NeutronFetch"
remoteFunction.Parent = ReplicatedStorage

Neutron.Fetcher.bindRemoteFunction(remoteFunction, HttpService, {
    transformUrl = function(url)
        return "https://r.jina.ai/http://" .. url:gsub("^https?://", "")
    end,
})

-- Client: render a page into a frame
local renderer = Neutron.new({
    fetcher = Neutron.Fetcher.fromRemoteFunction(remoteFunction)
})

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mount = Instance.new("Frame")
mount.Size = UDim2.fromScale(1, 1)
mount.Parent = screenGui

renderer:renderUrl("https://example.com", mount)
```

> For full setup, image options, fetch config, and architecture docs — see **[Info.md](Info.md)**.

---

## Studio Setup

No package manager needed.

1. Open `release/Neutron.module.lua`
2. Create a `ModuleScript` named `Neutron` in Studio
3. Paste the contents in and `require()` it

---

## What's Supported

- Common HTML tags and text nodes
- Inline and embedded CSS — tag, class, and ID selectors
- Block layout with margins and padding
- Roblox RichText text styling
- Proxy-based fetching for public websites
- Low-res image rendering without `EditableImage`
- Palette-quantized images with frame-budgeted rendering

---

## Known Limitations

- No JavaScript — this is a static renderer, not a browser
- CSS support is intentionally minimal
- Some pages may need a proxy or content adapter to be fetchable from Roblox

---

## License

[MIT](LICENSE)
