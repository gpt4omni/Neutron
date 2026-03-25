<div align="center">

# ⚛️ Neutron

**A modular Luau static-site renderer for Roblox.**

Neutron parses HTML, resolves CSS, builds a layout tree, and renders the result directly into Roblox GUI objects no browser engine needed.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Lua](https://img.shields.io/badge/Lua-47.8%25-blue?logo=lua)
![Luau](https://img.shields.io/badge/Luau-45.5%25-orange)
![Python](https://img.shields.io/badge/Python-6.7%25-yellow?logo=python)

> ⚠️ **Disclaimer:** We are not responsible for any action Roblox may take as a result of using this tool. By using Neutron, you acknowledge and accept these risks.

</div>

---

## 📦 Quick Start

```lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Neutron = require(ReplicatedStorage.Neutron)

-- Set up the server-side fetch bridge
local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "NeutronFetch"
remoteFunction.Parent = ReplicatedStorage

Neutron.Fetcher.bindRemoteFunction(remoteFunction, HttpService, {
    transformUrl = function(url)
        return "https://r.jina.ai/http://" .. url:gsub("^https?://", "")
    end,
})

-- Render a URL into a GUI frame
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

---

## 🗂️ Project Structure

### Core Library — `src/Neutron/`

| Module | Role |
|--------|------|
| [`init.luau`](src/Neutron/init.luau) | Public API entry point |
| [`Fetcher.luau`](src/Neutron/Fetcher.luau) | HTTP requests and proxy integration |
| [`HtmlTokenizer.luau`](src/Neutron/HtmlTokenizer.luau) | Raw HTML tokenization |
| [`HtmlParser.luau`](src/Neutron/HtmlParser.luau) | DOM tree construction |
| [`CssParser.luau`](src/Neutron/CssParser.luau) | CSS parsing |
| [`StyleResolver.luau`](src/Neutron/StyleResolver.luau) | Computed style resolution |
| [`LayoutEngine.luau`](src/Neutron/LayoutEngine.luau) | Block layout tree generation |
| [`Renderer.luau`](src/Neutron/Renderer.luau) | Roblox GUI rendering |
| [`ImageCompression.luau`](src/Neutron/ImageCompression.luau) | Palette quantization and RLE compression |
| [`ImagePipeline.luau`](src/Neutron/ImagePipeline.luau) | Image scheduling, caching, and frame budgeting |

### Other Files

| File | Purpose |
|------|---------|
| [`release/Neutron.module.lua`](release/Neutron.module.lua) | Single-file bundle for Studio use |
| [`examples/Example.server.luau`](examples/Example.server.luau) | Server-side HTTP bridge setup |
| [`examples/Example.client.luau`](examples/Example.client.luau) | Client-side rendering example |
| [`bridge_api/app.py`](bridge_api/app.py) | External Python image bridge API |
| [`bridge_api/requirements.txt`](bridge_api/requirements.txt) | Python dependencies |

---

## ✅ Supported Features

- HTML text nodes and common structural tags
- Inline and embedded CSS
- Tag, class, and ID selectors
- Block layout with margins and padding
- Text styling via Roblox RichText
- Optional proxy-based fetching for public websites
- Low-resolution image rendering *(no `EditableImage` required)*
- Palette-quantized image payloads with caching and frame budgeting

---

## 🖥️ Client & Server

| Method | Where it runs |
|--------|---------------|
| `renderHtml()` | Client **and** Server — processes HTML already in memory |
| `renderUrl()` | Requires a fetcher |

Because Roblox only allows HTTP requests on the **server**, client scripts can't fetch URLs directly. The recommended pattern:

1. On the **server**: call `Fetcher.bindRemoteFunction()` to wire a `RemoteFunction` to a standard HTTP fetcher.
2. In your **`LocalScript`**: use `Fetcher.fromRemoteFunction()` to route requests through that bridge.

---

## 🎮 Studio Setup

No package manager needed. To use Neutron directly in Roblox Studio:

1. Open `release/Neutron.module.lua`
2. Create a `ModuleScript` named **`Neutron`** in Studio
3. Paste the file contents in
4. `require()` it as normal

---

## 🌉 External Image Bridge

For rendering images from static websites, Neutron includes a Python bridge API that returns compressed image payloads.

**Server setup:**

```lua
-- 1. Create the RemoteFunction
local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "NeutronImageFetch"
remoteFunction.Parent = ReplicatedStorage

-- 2. Connect it to the Python bridge
Neutron.ImagePipeline.bindBridgeRemoteFunction(remoteFunction, HttpService, bridgeUrl)
```

> Also start the Python service: `cd bridge_api && pip install -r requirements.txt && python app.py`

**Client setup:**

```lua
local renderer = Neutron.new({
    imageRemoteFunction = ReplicatedStorage.NeutronImageFetch
})
```

The bridge returns `palette-rle` payloads, so external images go through the same lightweight renderer as local ones — no special client handling needed.

---

## 🌐 Fetch Options

```lua
Fetcher.new(HttpService, options)               -- server-side HTTP
Fetcher.fromRemoteFunction(remoteFunction, options)  -- client-side via bridge
```

| Option | Description |
|--------|-------------|
| `proxyTemplate` | Supports `{url}` and `{url_encoded}` placeholders |
| `transformUrl` | Provide your own URL rewriting function |

---

## 🖼️ Image Options

All image options are passed through `rendererOptions`:

| Option | Default | Description |
|--------|---------|-------------|
| `imageMaxWidth` | `128` | Max render width in pixels |
| `imageMaxHeight` | `72` | Max render height in pixels |
| `imageMaxColors` | `16` | Max colors in the quantized palette |
| `imageMaxPixelsPerFrame` | `10000` | Pixel budget per frame |
| `imageMaxRunsPerFrame` | `160` | RLE run budget per frame |
| `imagePixelScale` | `2` | GUI pixel size multiplier |
| `imageFetchPayload` | — | Provide quantized payloads directly on the client |
| `imageRemoteFunction` | — | Fetch quantized payloads from the server |

To connect the Python bridge on the server:
```lua
Neutron.ImagePipeline.bindBridgeRemoteFunction(remoteFunction, HttpService, bridgeUrl)
```

### Image Notes

- **`rbxassetid://` images** work out of the box — no `EditableImage` needed
- **External web images** require either a payload provider or the Python bridge
- Image rendering is spread across frames intentionally, so it never blocks text or layout

---

## ⚠️ Known Limitations

- This is a **static renderer**, not a browser engine
- **JavaScript is not supported**
- CSS coverage is intentionally minimal
- Arbitrary web pages may need a proxy or content adapter before Roblox can fetch them cleanly

---

## 📄 License

[MIT](LICENSE) — use freely, at your own risk.
