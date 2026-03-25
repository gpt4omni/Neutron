# 📖 Neutron — Info & Reference

Everything you need to know about how Neutron works, how to configure it, and what all the pieces do.

---

## 🗂️ Project Structure

### Core Library — `src/Neutron/`

| Module | What it does |
|--------|--------------|
| [`init.luau`](src/Neutron/init.luau) | Public API — this is what you `require()` |
| [`Fetcher.luau`](src/Neutron/Fetcher.luau) | HTTP requests and proxy integration |
| [`HtmlTokenizer.luau`](src/Neutron/HtmlTokenizer.luau) | Breaks raw HTML into tokens |
| [`HtmlParser.luau`](src/Neutron/HtmlParser.luau) | Builds a DOM tree from tokens |
| [`CssParser.luau`](src/Neutron/CssParser.luau) | Parses CSS rules |
| [`StyleResolver.luau`](src/Neutron/StyleResolver.luau) | Computes final styles for each element |
| [`LayoutEngine.luau`](src/Neutron/LayoutEngine.luau) | Generates the block layout tree |
| [`Renderer.luau`](src/Neutron/Renderer.luau) | Turns the layout tree into Roblox GUI objects |
| [`ImageCompression.luau`](src/Neutron/ImageCompression.luau) | Palette quantization and RLE compression |
| [`ImagePipeline.luau`](src/Neutron/ImagePipeline.luau) | Schedules, caches, and budgets image rendering |

### Everything Else

| File | Purpose |
|------|---------|
| [`release/Neutron.module.lua`](release/Neutron.module.lua) | Single-file bundle — use this in Studio |
| [`examples/Example.server.luau`](examples/Example.server.luau) | How to set up the server-side fetch bridge |
| [`examples/Example.client.luau`](examples/Example.client.luau) | How to render on the client |
| [`bridge_api/app.py`](bridge_api/app.py) | Python image bridge API |
| [`bridge_api/requirements.txt`](bridge_api/requirements.txt) | Python dependencies |

---

## 🖥️ Client & Server

Neutron has two main render methods:

| Method | Where it works |
|--------|----------------|
| `renderHtml()` | Client **and** Server — renders HTML you already have in memory |
| `renderUrl()` | Server only (or client via bridge) — fetches and renders a URL |

Roblox only allows HTTP requests on the **server**, so if you want to fetch a URL from a `LocalScript`, you need to route it through a server bridge:

**Server** — wire a `RemoteFunction` to a standard HTTP fetcher:
```lua
Neutron.Fetcher.bindRemoteFunction(remoteFunction, HttpService, options)
```

**Client** — use that `RemoteFunction` as your fetcher:
```lua
local fetcher = Neutron.Fetcher.fromRemoteFunction(remoteFunction)
local renderer = Neutron.new({ fetcher = fetcher })
```

---

## 🌐 Fetch Options

Two ways to create a fetcher:

```lua
-- Server-side
Fetcher.new(HttpService, options)

-- Client-side (via RemoteFunction bridge)
Fetcher.fromRemoteFunction(remoteFunction, options)
```

### Options

| Option | Description |
|--------|-------------|
| `proxyTemplate` | A proxy URL template. Supports `{url}` and `{url_encoded}` placeholders |
| `transformUrl` | A function `(url: string) -> string` for custom URL rewriting |

---

## 🌉 External Image Bridge

Neutron includes a Python bridge API for rendering images from external static websites. It returns `palette-rle` payloads — the same format Neutron uses internally — so no extra work is needed on the client.

### Server Setup

```lua
-- Create the RemoteFunction
local imageRemote = Instance.new("RemoteFunction")
imageRemote.Name = "NeutronImageFetch"
imageRemote.Parent = ReplicatedStorage

-- Connect it to the Python bridge
Neutron.ImagePipeline.bindBridgeRemoteFunction(imageRemote, HttpService, bridgeUrl)
```

Start the Python service:
```bash
cd bridge_api
pip install -r requirements.txt
python app.py
```

### Client Setup

```lua
local renderer = Neutron.new({
    imageRemoteFunction = ReplicatedStorage.NeutronImageFetch
})
```

---

## 🖼️ Image Options

Pass any of these through `rendererOptions` when creating a renderer:

| Option | Default | Description |
|--------|---------|-------------|
| `imageMaxWidth` | `128` | Max rendered image width in pixels |
| `imageMaxHeight` | `72` | Max rendered image height in pixels |
| `imageMaxColors` | `16` | Max colors in the quantized palette |
| `imageMaxPixelsPerFrame` | `10000` | How many pixels can be drawn per frame |
| `imageMaxRunsPerFrame` | `160` | Max RLE runs processed per frame |
| `imagePixelScale` | `2` | Size multiplier for each rendered pixel |
| `imageFetchPayload` | — | Supply a pre-quantized payload directly on the client |
| `imageRemoteFunction` | — | Fetch quantized payloads from the server via a `RemoteFunction` |

### How Image Rendering Works

- **`rbxassetid://` images** render out of the box — no `EditableImage` or bridge required
- **External web images** need either a `imageFetchPayload` provider or the Python bridge server
- Rendering is intentionally spread across multiple frames so it never stalls your text and layout

---

## 🔬 How It All Fits Together

```
URL / HTML string
       │
       ▼
  HtmlTokenizer   →  raw token stream
       │
       ▼
   HtmlParser     →  DOM tree
       │
       ▼
   CssParser      →  parsed CSS rules
       │
       ▼
 StyleResolver    →  elements with computed styles
       │
       ▼
 LayoutEngine     →  block layout tree
       │
       ▼
   Renderer       →  Roblox Frame / Label / ImageLabel hierarchy
       │
       ▼
 ImagePipeline    →  async image decode + render (spread across frames)
```
