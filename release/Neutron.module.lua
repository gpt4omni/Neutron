local modules = {}
local cache = {}

local function define(name, factory)
	modules[name] = factory
end

local function load(name)
	local existing = cache[name]
	if existing ~= nil then
		return existing
	end

	local factory = modules[name]
	assert(factory, string.format("Missing module %s", name))
	local value = factory(load)
	cache[name] = value
	return value
end

define("Defaults", function()
	local Defaults = {}

	Defaults.blockTags = {
		body = true,
		div = true,
		p = true,
		main = true,
		section = true,
		article = true,
		header = true,
		footer = true,
		nav = true,
		aside = true,
		ul = true,
		ol = true,
		li = true,
		h1 = true,
		h2 = true,
		h3 = true,
		h4 = true,
		h5 = true,
		h6 = true,
		pre = true,
		blockquote = true,
	}

	Defaults.voidTags = {
		br = true,
		hr = true,
		img = true,
		meta = true,
		link = true,
		input = true,
		source = true,
	}

	Defaults.inheritableProperties = {
		color = true,
		["font-size"] = true,
		["font-weight"] = true,
		["font-style"] = true,
		["text-align"] = true,
		["text-decoration"] = true,
		["font-family"] = true,
	}

	Defaults.namedColors = {
		black = "#000000",
		silver = "#c0c0c0",
		gray = "#808080",
		white = "#ffffff",
		maroon = "#800000",
		red = "#ff0000",
		purple = "#800080",
		fuchsia = "#ff00ff",
		green = "#008000",
		lime = "#00ff00",
		olive = "#808000",
		yellow = "#ffff00",
		navy = "#000080",
		blue = "#0000ff",
		teal = "#008080",
		aqua = "#00ffff",
		transparent = "transparent",
	}

	Defaults.userAgentStyles = {
		html = {
			display = "block",
			["font-size"] = 16,
			color = "#111111",
		},
		body = {
			display = "block",
			["font-size"] = 16,
			color = "#111111",
			["background-color"] = "#ffffff",
			padding = 16,
		},
		head = {
			display = "none",
		},
		title = {
			display = "none",
		},
		style = {
			display = "none",
		},
		script = {
			display = "none",
		},
		div = {
			display = "block",
		},
		span = {
			display = "inline",
		},
		p = {
			display = "block",
			["margin-top"] = 0,
			["margin-bottom"] = 12,
		},
		a = {
			display = "inline",
			color = "#1a73e8",
			["text-decoration"] = "underline",
		},
		strong = {
			display = "inline",
			["font-weight"] = "bold",
		},
		b = {
			display = "inline",
			["font-weight"] = "bold",
		},
		em = {
			display = "inline",
			["font-style"] = "italic",
		},
		i = {
			display = "inline",
			["font-style"] = "italic",
		},
		u = {
			display = "inline",
			["text-decoration"] = "underline",
		},
		br = {
			display = "inline",
		},
		ul = {
			display = "block",
			["margin-bottom"] = 12,
		},
		ol = {
			display = "block",
			["margin-bottom"] = 12,
		},
		li = {
			display = "block",
			["margin-bottom"] = 6,
		},
		h1 = {
			display = "block",
			["font-size"] = 32,
			["font-weight"] = "bold",
			["margin-bottom"] = 14,
		},
		h2 = {
			display = "block",
			["font-size"] = 28,
			["font-weight"] = "bold",
			["margin-bottom"] = 12,
		},
		h3 = {
			display = "block",
			["font-size"] = 24,
			["font-weight"] = "bold",
			["margin-bottom"] = 10,
		},
		h4 = {
			display = "block",
			["font-size"] = 20,
			["font-weight"] = "bold",
			["margin-bottom"] = 8,
		},
		h5 = {
			display = "block",
			["font-size"] = 18,
			["font-weight"] = "bold",
			["margin-bottom"] = 8,
		},
		h6 = {
			display = "block",
			["font-size"] = 16,
			["font-weight"] = "bold",
			["margin-bottom"] = 8,
		},
	}

	return Defaults
end)

define("Url", function()
	local Url = {}

	local function normalizePath(path)
		local suffixIndex = path:find("[?#]")
		local pathname = path
		local suffix = ""

		if suffixIndex then
			pathname = path:sub(1, suffixIndex - 1)
			suffix = path:sub(suffixIndex)
		end

		local segments = {}
		for segment in pathname:gmatch("[^/]+") do
			if segment == ".." then
				table.remove(segments)
			elseif segment ~= "." and segment ~= "" then
				table.insert(segments, segment)
			end
		end

		return "/" .. table.concat(segments, "/") .. suffix
	end

	function Url.join(baseUrl, path)
		if path == nil or path == "" then
			return baseUrl
		end

		if path:match("^https?://") then
			return path
		end

		if not baseUrl or baseUrl == "" then
			return path
		end

		local origin = baseUrl:match("^(https?://[^/]+)")

		if path:sub(1, 1) == "/" and origin then
			return origin .. normalizePath(path)
		end

		local currentPath = baseUrl:match("^https?://[^/]+(.*)$") or ""
		if currentPath == "" then
			currentPath = "/"
		end

		local baseDirectory = currentPath:gsub("[?#].*$", ""):gsub("[^/]*$", "")
		local combinedPath = normalizePath(baseDirectory .. path)

		if origin then
			return origin .. combinedPath
		end

		return combinedPath
	end

	return Url
end)

define("HtmlEntities", function()
	local HtmlEntities = {}

	local named = {
		amp = "&",
		lt = "<",
		gt = ">",
		quot = "\"",
		apos = "'",
		nbsp = " ",
	}

	function HtmlEntities.decode(text)
		return (text:gsub("&(#?[%w]+);", function(entity)
			if entity:sub(1, 1) == "#" then
				local numeric = entity:sub(2)
				local codepoint
				if numeric:sub(1, 1):lower() == "x" then
					codepoint = tonumber(numeric:sub(2), 16)
				else
					codepoint = tonumber(numeric, 10)
				end

				if codepoint then
					local ok, value = pcall(utf8.char, codepoint)
					if ok then
						return value
					end
				end

				return "&" .. entity .. ";"
			end

			return named[entity] or "&" .. entity .. ";"
		end))
	end

	return HtmlEntities
end)

define("HtmlTokenizer", function(loadModule)
	local HtmlEntities = loadModule("HtmlEntities")
	local HtmlTokenizer = {}

	local function parseAttributes(source)
		local attributes = {}
		local cursor = 1

		while cursor <= #source do
			local remaining = source:sub(cursor)
			local whitespace = remaining:match("^(%s+)")
			if whitespace then
				cursor += #whitespace
				remaining = source:sub(cursor)
			end

			local name = remaining:match("^([%w_:%-]+)")
			if not name then
				break
			end

			cursor += #name
			remaining = source:sub(cursor)
			local afterNameWhitespace = remaining:match("^(%s+)")
			if afterNameWhitespace then
				cursor += #afterNameWhitespace
				remaining = source:sub(cursor)
			end

			if remaining:sub(1, 1) == "=" then
				cursor += 1
				remaining = source:sub(cursor)
				local afterAssignmentWhitespace = remaining:match("^(%s+)")
				if afterAssignmentWhitespace then
					cursor += #afterAssignmentWhitespace
					remaining = source:sub(cursor)
				end

				local delimiter = remaining:sub(1, 1)

				if delimiter == "\"" or delimiter == "'" then
					local valueBody = remaining:sub(2)
					local valueEnd = valueBody:find(delimiter, 1, true)
					if valueEnd then
						attributes[string.lower(name)] = HtmlEntities.decode(valueBody:sub(1, valueEnd - 1))
						cursor += valueEnd + 1
					else
						attributes[string.lower(name)] = HtmlEntities.decode(valueBody)
						break
					end
				else
					local rawValue = remaining:match("^([^%s>]+)") or ""
					if rawValue == "" then
						attributes[string.lower(name)] = true
						break
					end
					attributes[string.lower(name)] = HtmlEntities.decode(rawValue)
					cursor += #rawValue
				end
			else
				attributes[string.lower(name)] = true
			end
		end

		return attributes
	end

	function HtmlTokenizer.tokenize(html)
		local tokens = {}
		local cursor = 1

		while cursor <= #html do
			local startIndex, endIndex, tagContent = html:find("<(.-)>", cursor)
			if not startIndex then
				local text = html:sub(cursor)
				if text ~= "" then
					table.insert(tokens, {
						type = "text",
						value = HtmlEntities.decode(text),
					})
				end
				break
			end

			if startIndex > cursor then
				local text = html:sub(cursor, startIndex - 1)
				if text ~= "" then
					table.insert(tokens, {
						type = "text",
						value = HtmlEntities.decode(text),
					})
				end
			end

			local cleaned = tagContent:gsub("^%s+", ""):gsub("%s+$", "")
			if cleaned:sub(1, 3) == "!--" then
				cursor = endIndex + 1
				continue
			end

			if cleaned:sub(1, 1) == "/" then
				local name = cleaned:match("^/%s*([%w_:%-]+)")
				if name then
					table.insert(tokens, {
						type = "closeTag",
						name = string.lower(name),
					})
				end
			else
				local name, attributeSource = cleaned:match("^([%w_:%-]+)(.*)$")
				if name then
					local selfClosing = attributeSource:match("/%s*$") ~= nil
					attributeSource = attributeSource:gsub("/%s*$", "")
					table.insert(tokens, {
						type = "openTag",
						name = string.lower(name),
						attributes = parseAttributes(attributeSource),
						selfClosing = selfClosing,
					})
				end
			end

			cursor = endIndex + 1
		end

		return tokens
	end

	return HtmlTokenizer
end)

define("HtmlParser", function(loadModule)
	local Defaults = loadModule("Defaults")
	local HtmlTokenizer = loadModule("HtmlTokenizer")
	local HtmlParser = {}

	local function createElement(name, attributes)
		return {
			type = "element",
			name = name,
			attributes = attributes or {},
			children = {},
		}
	end

	function HtmlParser.parse(html)
		local root = createElement("root")
		local stack = { root }
		local tokens = HtmlTokenizer.tokenize(html)

		for _, token in ipairs(tokens) do
			local current = stack[#stack]
			if token.type == "text" then
				table.insert(current.children, {
					type = "text",
					value = token.value,
				})
			elseif token.type == "openTag" then
				local element = createElement(token.name, token.attributes)
				table.insert(current.children, element)

				if not token.selfClosing and not Defaults.voidTags[token.name] then
					table.insert(stack, element)
				end
			elseif token.type == "closeTag" then
				for index = #stack, 2, -1 do
					if stack[index].name == token.name then
						while #stack >= index do
							table.remove(stack)
						end
						break
					end
				end
			end
		end

		return root
	end

	return HtmlParser
end)

define("CssParser", function()
	local CssParser = {}

	local function trim(value)
		return (value:gsub("^%s+", ""):gsub("%s+$", ""))
	end

	local function coerceValue(value)
		local number = tonumber(value:match("^([%d%.]+)px$"))
		if number then
			return number
		end

		local rawNumber = tonumber(value)
		if rawNumber then
			return rawNumber
		end

		return value
	end

	local function parseDeclarations(source)
		local declarations = {}
		for declaration in source:gmatch("([^;]+)") do
			local property, value = declaration:match("^%s*([%w%-]+)%s*:%s*(.-)%s*$")
			if property and value then
				declarations[string.lower(property)] = coerceValue(string.lower(value))
			end
		end
		return declarations
	end

	function CssParser.parse(css)
		local rules = {}
		local cleaned = css:gsub("/%*.-%*/", "")

		for selectorGroup, body in cleaned:gmatch("([^{}]+){([^{}]+)}") do
			local declarations = parseDeclarations(body)
			for selector in selectorGroup:gmatch("([^,]+)") do
				table.insert(rules, {
					selector = trim(string.lower(selector)),
					declarations = declarations,
				})
			end
		end

		return rules
	end

	function CssParser.parseInline(styleAttribute)
		return parseDeclarations(styleAttribute or "")
	end

	return CssParser
end)

define("StyleResolver", function(loadModule)
	local Defaults = loadModule("Defaults")
	local CssParser = loadModule("CssParser")
	local StyleResolver = {}

	local function clone(source)
		local result = {}
		for key, value in pairs(source or {}) do
			result[key] = value
		end
		return result
	end

	local function assign(target, source)
		for key, value in pairs(source or {}) do
			target[key] = value
		end
	end

	local function parseClassList(value)
		local classMap = {}
		if type(value) ~= "string" then
			return classMap
		end

		for className in value:gmatch("%S+") do
			classMap[className] = true
		end

		return classMap
	end

	local function matchesSelector(node, selector)
		if node.type ~= "element" or selector == "" then
			return false
		end

		if selector:sub(1, 1) == "." then
			local classes = parseClassList(node.attributes.class)
			return classes[selector:sub(2)] == true
		end

		if selector:sub(1, 1) == "#" then
			return node.attributes.id == selector:sub(2)
		end

		return node.name == selector
	end

	local function normalizeColor(value)
		if type(value) ~= "string" then
			return value
		end

		local lowered = string.lower(value)
		if Defaults.namedColors[lowered] then
			return Defaults.namedColors[lowered]
		end

		return lowered
	end

	local function normalizeBoxValue(style, property)
		local value = style[property]
		if value == nil then
			return 0
		end
		return tonumber(value) or 0
	end

	local function normalizeComputedStyle(style)
		style.display = style.display or "inline"
		style.color = normalizeColor(style.color or "#111111")
		style["background-color"] = normalizeColor(style["background-color"] or "transparent")
		style["font-size"] = tonumber(style["font-size"]) or 16
		style["font-weight"] = style["font-weight"] or "normal"
		style["font-style"] = style["font-style"] or "normal"
		style["text-align"] = style["text-align"] or "left"
		style["text-decoration"] = style["text-decoration"] or "none"
		style["font-family"] = style["font-family"] or "Gotham"
		style.padding = normalizeBoxValue(style, "padding")
		style["padding-left"] = style["padding-left"] == nil and style.padding or normalizeBoxValue(style, "padding-left")
		style["padding-right"] = style["padding-right"] == nil and style.padding or normalizeBoxValue(style, "padding-right")
		style["padding-top"] = style["padding-top"] == nil and style.padding or normalizeBoxValue(style, "padding-top")
		style["padding-bottom"] = style["padding-bottom"] == nil and style.padding or normalizeBoxValue(style, "padding-bottom")
		style.margin = normalizeBoxValue(style, "margin")
		style["margin-left"] = style["margin-left"] == nil and style.margin or normalizeBoxValue(style, "margin-left")
		style["margin-right"] = style["margin-right"] == nil and style.margin or normalizeBoxValue(style, "margin-right")
		style["margin-top"] = style["margin-top"] == nil and style.margin or normalizeBoxValue(style, "margin-top")
		style["margin-bottom"] = style["margin-bottom"] == nil and style.margin or normalizeBoxValue(style, "margin-bottom")
		return style
	end

	local function collectStyleRules(root)
		local rules = {}

		local function visit(node)
			if node.type ~= "element" then
				return
			end

			if node.name == "style" then
				local buffer = {}
				for _, child in ipairs(node.children) do
					if child.type == "text" then
						table.insert(buffer, child.value)
					end
				end
				for _, rule in ipairs(CssParser.parse(table.concat(buffer, ""))) do
					table.insert(rules, rule)
				end
			end

			for _, child in ipairs(node.children) do
				visit(child)
			end
		end

		visit(root)
		return rules
	end

	local function buildComputedTree(node, inheritedStyle, styleRules)
		if node.type == "text" then
			return {
				type = "text",
				value = node.value,
				style = inheritedStyle,
			}
		end

		local style = {}
		for key, value in pairs(inheritedStyle or {}) do
			if Defaults.inheritableProperties[key] then
				style[key] = value
			end
		end

		assign(style, Defaults.userAgentStyles[node.name])

		for _, rule in ipairs(styleRules) do
			if matchesSelector(node, rule.selector) then
				assign(style, rule.declarations)
			end
		end

		assign(style, CssParser.parseInline(node.attributes.style))
		style = normalizeComputedStyle(style)

		local computed = {
			type = node.type,
			name = node.name,
			attributes = node.attributes,
			style = style,
			children = {},
		}

		for _, child in ipairs(node.children) do
			table.insert(computed.children, buildComputedTree(child, style, styleRules))
		end

		return computed
	end

	function StyleResolver.resolve(root)
		local rules = collectStyleRules(root)
		local computedRoot = {
			type = "element",
			name = "root",
			attributes = {},
			style = normalizeComputedStyle(clone(Defaults.userAgentStyles.html)),
			children = {},
		}

		for _, child in ipairs(root.children) do
			if child.type == "element" and child.name ~= "style" then
				table.insert(computedRoot.children, buildComputedTree(child, computedRoot.style, rules))
			end
		end

		return computedRoot
	end

	return StyleResolver
end)

define("LayoutEngine", function(loadModule)
	local Defaults = loadModule("Defaults")
	local LayoutEngine = {}

	local function normalizeInlineText(value)
		local normalized = value:gsub("%s+", " ")
		if normalized == " " then
			return normalized
		end
		return normalized
	end

	local function escapeRichText(value)
		return value
			:gsub("&", "&amp;")
			:gsub("<", "&lt;")
			:gsub(">", "&gt;")
			:gsub("\"", "&quot;")
			:gsub("'", "&apos;")
	end

	local function applyRichTextStyle(text, style)
		local buffer = text
		if style["font-weight"] == "bold" then
			buffer = "<b>" .. buffer .. "</b>"
		end
		if style["font-style"] == "italic" then
			buffer = "<i>" .. buffer .. "</i>"
		end
		if style["text-decoration"] == "underline" then
			buffer = "<u>" .. buffer .. "</u>"
		end

		local color = style.color or "#111111"
		local face = style["font-family"] or "Gotham"
		local size = style["font-size"] or 16

		return string.format('<font color="%s" face="%s" size="%s">%s</font>', color, face, tostring(size), buffer)
	end

	local function isBlock(node)
		if node.type ~= "element" then
			return false
		end

		if node.style.display == "block" then
			return true
		end

		return Defaults.blockTags[node.name] == true
	end

	local function serializeInline(node)
		if node.type == "text" then
			local text = normalizeInlineText(node.value)
			if text == "" then
				return ""
			end
			return applyRichTextStyle(escapeRichText(text), node.style)
		end

		if node.name == "br" then
			return "\n"
		end

		if isBlock(node) then
			return ""
		end

		local parts = {}
		for _, child in ipairs(node.children) do
			local segment = serializeInline(child)
			if segment ~= "" then
				table.insert(parts, segment)
			end
		end
		return table.concat(parts)
	end

	local function buildContainer(node)
		local children = {}
		local inlineSegments = {}

		local function flushInline()
			if #inlineSegments == 0 then
				return
			end

			table.insert(children, {
				kind = "text",
				tag = node.name,
				style = node.style,
				text = table.concat(inlineSegments),
			})
			table.clear(inlineSegments)
		end

		for _, child in ipairs(node.children) do
			if child.type == "text" then
				local segment = serializeInline(child)
				if segment ~= "" then
					table.insert(inlineSegments, segment)
				end
			elseif child.type == "element" then
				if child.name == "style" or child.style.display == "none" then
					continue
				end

				if child.name == "img" then
					flushInline()
					table.insert(children, {
						kind = "image",
						tag = child.name,
						style = child.style,
						source = child.attributes.src,
						alt = child.attributes.alt or "",
					})
				elseif isBlock(child) then
					flushInline()
					table.insert(children, buildContainer(child))
				else
					local segment = serializeInline(child)
					if segment ~= "" then
						table.insert(inlineSegments, segment)
					end
				end
			end
		end

		flushInline()

		return {
			kind = "container",
			tag = node.name,
			style = node.style,
			attributes = node.attributes,
			children = children,
		}
	end

	function LayoutEngine.build(root)
		local bodyNode = nil
		local firstElement = nil

		for _, child in ipairs(root.children) do
			if child.type == "element" and not firstElement then
				firstElement = child
			end

			if child.type == "element" and child.name == "html" then
				for _, htmlChild in ipairs(child.children) do
					if htmlChild.type == "element" and htmlChild.name == "body" then
						bodyNode = htmlChild
						break
					end
				end
			elseif child.type == "element" and child.name == "body" then
				bodyNode = child
			end
		end

		local source = bodyNode or firstElement or {
			type = "element",
			name = "body",
			style = root.style,
			attributes = {},
			children = {},
		}

		return buildContainer(source)
	end

	return LayoutEngine
end)

define("Renderer", function(loadModule)
	local Url = loadModule("Url")
	local Renderer = {}
	Renderer.__index = Renderer

	local function pickFont(style)
		local family = string.lower(style["font-family"] or "")
		if family:find("mono") then
			return Enum.Font.Code
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
		container.Size = UDim2.new(1, 0, 0, 0)
		container.AutomaticSize = Enum.AutomaticSize.Y
		container.Parent = wrapper

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

		for _, child in ipairs(tree.children) do
			self:renderBlock(root, child)
		end

		return root
	end

	return Renderer
end)

define("Fetcher", function(loadModule)
	local Url = loadModule("Url")
	local Fetcher = {}
	Fetcher.__index = Fetcher

	local function interpolate(template, url, encodedUrl)
		return template:gsub("{url_encoded}", encodedUrl):gsub("{url}", url)
	end

	local function createFetcher(state)
		return setmetatable(state, Fetcher)
	end

	function Fetcher.new(httpService, options)
		assert(httpService, "Fetcher.new requires HttpService")

		options = options or {}

		return createFetcher({
			httpService = httpService,
			proxyTemplate = options.proxyTemplate,
			headers = options.headers or {},
			transformUrl = options.transformUrl,
			remoteFunction = nil,
		})
	end

	function Fetcher.fromRemoteFunction(remoteFunction, options)
		assert(remoteFunction, "Fetcher.fromRemoteFunction requires a RemoteFunction")

		options = options or {}

		return createFetcher({
			httpService = nil,
			proxyTemplate = options.proxyTemplate,
			headers = options.headers or {},
			transformUrl = options.transformUrl,
			remoteFunction = remoteFunction,
		})
	end

	function Fetcher.createRemoteHandler(httpService, options)
		local fetcher = Fetcher.new(httpService, options)

		return function(url)
			return fetcher:fetch(url)
		end
	end

	function Fetcher.bindRemoteFunction(remoteFunction, httpService, options)
		assert(remoteFunction, "Fetcher.bindRemoteFunction requires a RemoteFunction")
		remoteFunction.OnServerInvoke = Fetcher.createRemoteHandler(httpService, options)
		return remoteFunction
	end

	function Fetcher.isRemote(self)
		return self.remoteFunction ~= nil
	end

	function Fetcher:resolve(url)
		if type(self.transformUrl) == "function" then
			return self.transformUrl(url)
		end

		if self.proxyTemplate then
			if self.httpService then
				return interpolate(self.proxyTemplate, url, self.httpService:UrlEncode(url))
			end
			return interpolate(self.proxyTemplate, url, url)
		end

		return url
	end

	function Fetcher:fetch(url)
		if self.remoteFunction then
			local resolvedUrl = self:resolve(url)
			return self.remoteFunction:InvokeServer(resolvedUrl)
		end

		assert(self.httpService, "Fetcher:fetch requires HttpService or a RemoteFunction bridge")
		local resolvedUrl = self:resolve(url)
		return self.httpService:GetAsync(resolvedUrl, false, self.headers)
	end

	function Fetcher:fetchRelative(baseUrl, path)
		return self:fetch(Url.join(baseUrl, path))
	end

	return Fetcher
end)

define("Neutron", function(loadModule)
	local HtmlParser = loadModule("HtmlParser")
	local StyleResolver = loadModule("StyleResolver")
	local LayoutEngine = loadModule("LayoutEngine")
	local Renderer = loadModule("Renderer")
	local Fetcher = loadModule("Fetcher")

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
end)

return load("Neutron")
