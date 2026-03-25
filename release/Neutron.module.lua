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

define("Defaults", function(loadModule)
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
		form = true,
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
		["text-transform"] = true,
		["list-style-type"] = true,
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
		form = {
			display = "block",
		},
		span = {
			display = "inline",
		},
		input = {
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
			["list-style-type"] = "disc",
		},
		ol = {
			display = "block",
			["margin-bottom"] = 12,
			["list-style-type"] = "decimal",
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

define("Url", function(loadModule)
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

define("HtmlEntities", function(loadModule)
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

define("CssParser", function(loadModule)
	local CssParser = {}
	
	local function trim(value)
		return (value:gsub("^%s+", ""):gsub("%s+$", ""))
	end
	
	local function coerceValue(value)
		value = trim(value:gsub("%s*!important%s*$", ""))
	
		if value:find("%s") then
			local parts = {}
			for part in value:gmatch("%S+") do
				table.insert(parts, coerceValue(part))
			end
			return parts
		end
	
		local number = tonumber(value:match("^([%d%.]+)px$"))
		if number then
			return number
		end
	
		local emNumber = tonumber(value:match("^([%d%.]+)em$"))
		if emNumber then
			return {
				unit = "em",
				value = emNumber,
			}
		end
	
		local percentNumber = tonumber(value:match("^([%d%.]+)%%$"))
		if percentNumber then
			return {
				unit = "%",
				value = percentNumber,
			}
		end
	
		local vwNumber = tonumber(value:match("^([%d%.]+)vw$"))
		if vwNumber then
			return {
				unit = "vw",
				value = vwNumber,
			}
		end
	
		local vhNumber = tonumber(value:match("^([%d%.]+)vh$"))
		if vhNumber then
			return {
				unit = "vh",
				value = vhNumber,
			}
		end
	
		if value == "auto" then
			return value
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
	
		repeat
			local nextCleaned, replacements = cleaned:gsub("@[%w%-]+[^{}]*{%s*([^{}]+{[^{}]+})%s*}", "%1")
			cleaned = nextCleaned
		until replacements == 0
	
		for selectorGroup, body in cleaned:gmatch("([^{}]+){([^{}]+)}") do
			local declarations = parseDeclarations(body)
			for selector in selectorGroup:gmatch("([^,]+)") do
				table.insert(rules, {
					selector = trim(string.lower(selector)):gsub(":%w+", ""),
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
	
	local function matchesSimpleSelector(node, selector)
		if node.type ~= "element" or selector == "" then
			return false
		end
	
		local classes = parseClassList(node.attributes.class)
		local tagName = selector:match("^[%a][%w%-]*")
		if tagName and node.name ~= tagName then
			return false
		end
	
		for idValue in selector:gmatch("#([%w%-_]+)") do
			if node.attributes.id ~= idValue then
				return false
			end
		end
	
		for className in selector:gmatch("%.([%w%-_]+)") do
			if not classes[className] then
				return false
			end
		end
	
		if selector:find("#", 1, true) or selector:find(".", 1, true) then
			return true
		end
	
		return node.name == selector
	end
	
	local function matchesSelector(node, selector, ancestors)
		if node.type ~= "element" or selector == "" then
			return false
		end
	
		local parts = {}
		for part in selector:gmatch("%S+") do
			table.insert(parts, part)
		end
	
		if #parts == 0 then
			return false
		end
	
		if not matchesSimpleSelector(node, parts[#parts]) then
			return false
		end
	
		local ancestorIndex = #ancestors
		for partIndex = #parts - 1, 1, -1 do
			local matched = false
			while ancestorIndex >= 1 do
				if matchesSimpleSelector(ancestors[ancestorIndex], parts[partIndex]) then
					matched = true
					ancestorIndex -= 1
					break
				end
				ancestorIndex -= 1
			end
	
			if not matched then
				return false
			end
		end
	
		return true
	end
	
	local function normalizeColor(value)
		if type(value) ~= "string" then
			return value
		end
	
		local lowered = string.lower(value)
		if lowered == "inherit" or lowered == "initial" or lowered == "currentcolor" then
			return nil
		end
		if Defaults.namedColors[lowered] then
			return Defaults.namedColors[lowered]
		end
	
		local red, green, blue = lowered:match("^#(%x)(%x)(%x)$")
		if red and green and blue then
			return "#" .. red .. red .. green .. green .. blue .. blue
		end
	
		return lowered
	end
	
	local function colorFromBackgroundValue(value)
		if type(value) == "string" then
			local normalized = normalizeColor(value)
			if normalized ~= nil then
				return normalized
			end
			if value == "none" then
				return "transparent"
			end
			return nil
		end
	
		if type(value) == "table" then
			for _, part in ipairs(value) do
				local color = colorFromBackgroundValue(part)
				if color ~= nil then
					return color
				end
			end
		end
	
		return nil
	end
	
	local function borderColorFromValue(value)
		if type(value) ~= "string" then
			return nil
		end
	
		local lowered = string.lower(value)
		if Defaults.namedColors[lowered] then
			return Defaults.namedColors[lowered]
		end
	
		if lowered:match("^#%x%x%x%x%x%x$") or lowered:match("^#%x%x%x$") then
			return normalizeColor(lowered)
		end
	
		return nil
	end
	
	local function parseBorderValue(value)
		local width
		local color
	
		if type(value) == "number" then
			return value, nil
		end
	
		if type(value) == "string" then
			if value == "none" then
				return 0, nil
			end
	
			local numeric = tonumber(value)
			if numeric ~= nil then
				return numeric, nil
			end
	
			return nil, borderColorFromValue(value)
		end
	
		if type(value) == "table" then
			for _, part in ipairs(value) do
				if type(part) == "number" then
					width = part
				elseif type(part) == "string" then
					if part == "none" then
						width = 0
					else
						local numeric = tonumber(part)
						if numeric ~= nil then
							width = numeric
						else
							color = borderColorFromValue(part) or color
						end
					end
				end
			end
		end
	
		return width, color
	end
	
	local function applyBorderShorthand(style, property, sides)
		local width, color = parseBorderValue(style[property])
		if width == nil and color == nil then
			return
		end
	
		for _, side in ipairs(sides) do
			local widthKey = "border-" .. side .. "-width"
			local colorKey = "border-" .. side .. "-color"
			if width ~= nil and style[widthKey] == nil then
				style[widthKey] = width
			end
			if color ~= nil and style[colorKey] == nil then
				style[colorKey] = color
			end
		end
	end
	
	local function resolveLength(value, baseFontSize)
		if type(value) == "number" then
			return value
		end
	
		if type(value) == "table" then
			if value.unit == "em" then
				return math.floor((baseFontSize or 16) * value.value + 0.5)
			end
	
			if value.unit == "%" then
				return {
					unit = "%",
					value = value.value,
				}
			end
	
			return value
		end
	
		local numeric = tonumber(value)
		if numeric ~= nil then
			return numeric
		end
	
		return 0
	end
	
	local function normalizeBoxValue(style, property, baseFontSize)
		local value = style[property]
		if value == nil then
			return 0
		end
	
		return resolveLength(value, baseFontSize)
	end
	
	local function resolveOptionalLength(value, baseFontSize)
		if value == nil or value == "" then
			return nil
		end
	
		return resolveLength(value, baseFontSize)
	end
	
	local function expandBoxShorthand(style, property)
		local value = style[property]
		if type(value) ~= "table" then
			return
		end
	
		local parts = value
		if #parts == 1 then
			style[property .. "-top"] = parts[1]
			style[property .. "-right"] = parts[1]
			style[property .. "-bottom"] = parts[1]
			style[property .. "-left"] = parts[1]
		elseif #parts == 2 then
			style[property .. "-top"] = parts[1]
			style[property .. "-right"] = parts[2]
			style[property .. "-bottom"] = parts[1]
			style[property .. "-left"] = parts[2]
		elseif #parts == 3 then
			style[property .. "-top"] = parts[1]
			style[property .. "-right"] = parts[2]
			style[property .. "-bottom"] = parts[3]
			style[property .. "-left"] = parts[2]
		elseif #parts >= 4 then
			style[property .. "-top"] = parts[1]
			style[property .. "-right"] = parts[2]
			style[property .. "-bottom"] = parts[3]
			style[property .. "-left"] = parts[4]
		end
	end
	
	local function normalizeComputedStyle(style, inheritedStyle)
		local baseFontSize = inheritedStyle and inheritedStyle["font-size"] or 16
		style.display = style.display or "inline"
		if style.background ~= nil then
			style["background-color"] = colorFromBackgroundValue(style.background) or style["background-color"]
		end
		style.color = normalizeColor(style.color) or (inheritedStyle and inheritedStyle.color) or "#111111"
		style["background-color"] = normalizeColor(style["background-color"] or "transparent") or "transparent"
		if type(style["font-size"]) == "table" and style["font-size"].unit == "%" then
			style["font-size"] = math.floor((baseFontSize or 16) * style["font-size"].value / 100 + 0.5)
		else
			style["font-size"] = tonumber(style["font-size"]) or 16
		end
		style["font-weight"] = style["font-weight"] or "normal"
		style["font-style"] = style["font-style"] or "normal"
		style["text-align"] = style["text-align"] or "left"
		style["text-decoration"] = style["text-decoration"] or "none"
		style["font-family"] = style["font-family"] or "Gotham"
		style["text-transform"] = style["text-transform"] or "none"
		if style["list-style"] == "none" then
			style["list-style-type"] = "none"
		elseif type(style["list-style"]) == "table" then
			for _, part in ipairs(style["list-style"]) do
				if part == "none" or part == "disc" or part == "decimal" then
					style["list-style-type"] = part
					break
				end
			end
		end
		style["list-style-type"] = style["list-style-type"] or "none"
		style.position = style.position or "static"
		expandBoxShorthand(style, "padding")
		expandBoxShorthand(style, "margin")
		applyBorderShorthand(style, "border", { "top", "right", "bottom", "left" })
		applyBorderShorthand(style, "border-top", { "top" })
		applyBorderShorthand(style, "border-right", { "right" })
		applyBorderShorthand(style, "border-bottom", { "bottom" })
		applyBorderShorthand(style, "border-left", { "left" })
		style.padding = normalizeBoxValue(style, "padding", style["font-size"])
		style["padding-left"] = style["padding-left"] == nil and style.padding or normalizeBoxValue(style, "padding-left", style["font-size"])
		style["padding-right"] = style["padding-right"] == nil and style.padding or normalizeBoxValue(style, "padding-right", style["font-size"])
		style["padding-top"] = style["padding-top"] == nil and style.padding or normalizeBoxValue(style, "padding-top", style["font-size"])
		style["padding-bottom"] = style["padding-bottom"] == nil and style.padding or normalizeBoxValue(style, "padding-bottom", style["font-size"])
		style.margin = type(style.margin) == "string" and style.margin or normalizeBoxValue(style, "margin", style["font-size"])
		style["margin-left"] = style["margin-left"] == nil and style.margin or style["margin-left"]
		style["margin-right"] = style["margin-right"] == nil and style.margin or style["margin-right"]
		style["margin-top"] = style["margin-top"] == nil and style.margin or style["margin-top"]
		style["margin-bottom"] = style["margin-bottom"] == nil and style.margin or style["margin-bottom"]
		style["margin-left"] = style["margin-left"] == "auto" and "auto" or normalizeBoxValue(style, "margin-left", style["font-size"])
		style["margin-right"] = style["margin-right"] == "auto" and "auto" or normalizeBoxValue(style, "margin-right", style["font-size"])
		style["margin-top"] = style["margin-top"] == "auto" and "auto" or normalizeBoxValue(style, "margin-top", style["font-size"])
		style["margin-bottom"] = style["margin-bottom"] == "auto" and "auto" or normalizeBoxValue(style, "margin-bottom", style["font-size"])
		style.width = style.width == "auto" and "auto" or resolveOptionalLength(style.width, style["font-size"])
		style.height = style.height == "auto" and "auto" or resolveOptionalLength(style.height, style["font-size"])
		style["min-width"] = resolveOptionalLength(style["min-width"], style["font-size"]) or 0
		style.left = resolveOptionalLength(style.left, style["font-size"])
		style.right = resolveOptionalLength(style.right, style["font-size"])
		style.top = resolveOptionalLength(style.top, style["font-size"])
		style.bottom = resolveOptionalLength(style.bottom, style["font-size"])
		style["border-radius"] = resolveLength(style["border-radius"], style["font-size"])
		style["border-top-width"] = resolveLength(style["border-top-width"], style["font-size"])
		style["border-right-width"] = resolveLength(style["border-right-width"], style["font-size"])
		style["border-bottom-width"] = resolveLength(style["border-bottom-width"], style["font-size"])
		style["border-left-width"] = resolveLength(style["border-left-width"], style["font-size"])
		style["border-top-color"] = borderColorFromValue(style["border-top-color"]) or "#000000"
		style["border-right-color"] = borderColorFromValue(style["border-right-color"]) or "#000000"
		style["border-bottom-color"] = borderColorFromValue(style["border-bottom-color"]) or "#000000"
		style["border-left-color"] = borderColorFromValue(style["border-left-color"]) or "#000000"
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
	
	local function buildComputedTree(node, inheritedStyle, styleRules, ancestors)
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
			if matchesSelector(node, rule.selector, ancestors) then
				assign(style, rule.declarations)
			end
		end
	
		assign(style, CssParser.parseInline(node.attributes.style))
		if node.name == "input" and string.lower(tostring(node.attributes.type or "text")) == "hidden" then
			style.display = "none"
		end
		style = normalizeComputedStyle(style, inheritedStyle)
	
		local computed = {
			type = node.type,
			name = node.name,
			attributes = node.attributes,
			style = style,
			children = {},
		}
	
		for _, child in ipairs(node.children) do
			local nextAncestors = table.clone(ancestors)
			table.insert(nextAncestors, node)
			table.insert(computed.children, buildComputedTree(child, style, styleRules, nextAncestors))
		end
	
		return computed
	end
	
	function StyleResolver.resolve(root, externalStyles)
		local rules = collectStyleRules(root)
		for _, css in ipairs(externalStyles or {}) do
			for _, rule in ipairs(CssParser.parse(css)) do
				table.insert(rules, rule)
			end
		end
		local computedRoot = {
			type = "element",
			name = "root",
			attributes = {},
			style = normalizeComputedStyle(clone(Defaults.userAgentStyles.html), Defaults.userAgentStyles.html),
			children = {},
		}
	
		for _, child in ipairs(root.children) do
			if child.type == "element" and child.name ~= "style" then
				table.insert(computedRoot.children, buildComputedTree(child, computedRoot.style, rules, {}))
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
		if not value:find("%S") then
			return ""
		end
	
		local normalized = value:gsub("%s+", " ")
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
	
	local function normalizeRichTextColor(value)
		if type(value) ~= "string" then
			return "#111111"
		end
	
		local normalized = value:gsub("^%s+", ""):gsub("%s+$", ""):lower()
		if normalized == "" or normalized == "inherit" or normalized == "initial" or normalized == "transparent" or normalized == "none" then
			return "#111111"
		end
	
		if normalized:match("^#%x%x%x%x%x%x$") or normalized:match("^#%x%x%x$") or normalized:match("^[%a]+$") then
			return normalized
		end
	
		return "#111111"
	end
	
	local function applyTextTransform(text, style)
		local transform = style["text-transform"]
		if transform == "uppercase" then
			return string.upper(text)
		end
		if transform == "lowercase" then
			return string.lower(text)
		end
		if transform == "capitalize" then
			return (text:gsub("(%a)([%w']*)", function(first, rest)
				return string.upper(first) .. string.lower(rest)
			end))
		end
		return text
	end
	
	local function applyRichTextStyle(text, style)
		local buffer = applyTextTransform(text, style)
		if style["font-weight"] == "bold" then
			buffer = "<b>" .. buffer .. "</b>"
		end
		if style["font-style"] == "italic" then
			buffer = "<i>" .. buffer .. "</i>"
		end
		if style["text-decoration"] == "underline" then
			buffer = "<u>" .. buffer .. "</u>"
		end
	
		local color = normalizeRichTextColor(style.color)
		return string.format('<font color="%s">%s</font>', color, buffer)
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
	
	local function extractInlineImage(node)
		if node.type ~= "element" then
			return nil
		end
	
		if node.name == "img" then
			return node
		end
	
		if isBlock(node) then
			return nil
		end
	
		local foundImage = nil
		for _, child in ipairs(node.children) do
			if child.type == "text" then
				if normalizeInlineText(child.value) ~= "" then
					return nil
				end
			elseif child.type == "element" then
				local nestedImage = extractInlineImage(child)
				if not nestedImage then
					return nil
				end
				if foundImage ~= nil then
					return nil
				end
				foundImage = nestedImage
			end
		end
	
		return foundImage
	end
	
	local function buildContainer(node)
		local children = {}
		local inlineSegments = {}
	
		local function pushControl(element)
			local inputType = string.lower(tostring(element.attributes.type or "text"))
			if inputType == "hidden" then
				return
			end
	
			table.insert(children, {
				kind = "control",
				tag = element.name,
				style = element.style,
				attributes = element.attributes,
				controlType = inputType,
				text = tostring(element.attributes.value or ""),
			})
		end
	
		local function flushInline()
			if #inlineSegments == 0 then
				return
			end
	
			if node.name == "li" and node.style["list-style-type"] ~= "none" then
				inlineSegments[1] = "* " .. inlineSegments[1]
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
					if not (type(child.attributes.src) == "string" and child.attributes.src:find("trans%.gif")) then
						table.insert(children, {
							kind = "image",
							tag = child.name,
							style = child.style,
							source = child.attributes.src,
							alt = child.attributes.alt or "",
						})
					end
				elseif child.name == "input" then
					flushInline()
					pushControl(child)
				elseif isBlock(child) then
					flushInline()
					table.insert(children, buildContainer(child))
				else
					local nestedImage = extractInlineImage(child)
					if nestedImage then
						flushInline()
						if not (type(nestedImage.attributes.src) == "string" and nestedImage.attributes.src:find("trans%.gif")) then
							table.insert(children, {
								kind = "image",
								tag = nestedImage.name,
								style = nestedImage.style,
								source = nestedImage.attributes.src,
								alt = nestedImage.attributes.alt or "",
							})
						end
					else
						local segment = serializeInline(child)
						if segment ~= "" then
							table.insert(inlineSegments, segment)
						end
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
	
	local function firstFontFamily(value)
		if type(value) ~= "string" then
			return ""
		end
	
		local family = value:match("^[^,]+") or value
		return family:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^['\"]", ""):gsub("['\"]$", "")
	end
	
	local function pickFont(style)
		local family = string.lower(firstFontFamily(style["font-family"]))
		if family:find("mono") then
			return Enum.Font.Code
		end
		if family:find("georgia") or family:find("palatino") or family:find("serif") then
			return Enum.Font.Garamond
		end
	
		if style["font-weight"] == "bold" then
			return Enum.Font.SourceSansBold
		end
	
		return Enum.Font.SourceSans
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
	
		local shortRed, shortGreen, shortBlue = value:match("^#(%x)(%x)(%x)$")
		if shortRed and shortGreen and shortBlue then
			return Color3.fromRGB(
				parseHexChannel(shortRed .. shortRed),
				parseHexChannel(shortGreen .. shortGreen),
				parseHexChannel(shortBlue .. shortBlue)
			)
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
	
	local function resolveViewportValue(value, axis)
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	
		if type(value) == "number" then
			return value
		end
	
		if type(value) == "table" then
			if value.unit == "vw" then
				return math.floor(viewport.X * value.value / 100 + 0.5)
			end
			if value.unit == "vh" then
				return math.floor(viewport.Y * value.value / 100 + 0.5)
			end
			if value.unit == "%" then
				local base = axis == "x" and viewport.X or viewport.Y
				return math.floor(base * value.value / 100 + 0.5)
			end
		end
	
		return axis == "x" and 0 or 0
	end
	
	local function resolveSizeValue(value, axis, fallbackScale)
		if value == "auto" or value == nil then
			return nil
		end
	
		if type(value) == "number" then
			return UDim2.new(0, value, 0, 0)
		end
	
		if type(value) == "table" then
			if value.unit == "%" then
				if axis == "x" then
					return UDim2.new(value.value / 100, 0, 0, 0)
				end
				return UDim2.new(0, 0, value.value / 100, 0)
			end
	
			local resolved = resolveViewportValue(value, axis)
			return UDim2.new(0, resolved, 0, 0)
		end
	
		return fallbackScale
	end
	
	local function resolveOffsetValue(value, axis)
		if type(value) == "number" then
			return UDim.new(0, value)
		end
	
		if type(value) == "table" and value.unit == "%" then
			return UDim.new(value.value / 100, 0)
		end
	
		if type(value) == "table" then
			return UDim.new(0, resolveViewportValue(value, axis))
		end
	
		return UDim.new(0, 0)
	end
	
	local function createWrapper(parent, style)
		local wrapper = Instance.new("Frame")
		wrapper.Name = "Block"
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel = 0
		wrapper.AutomaticSize = Enum.AutomaticSize.Y
		wrapper.Parent = parent
	
		if style.position == "absolute" then
			local widthValue = style.width
			local heightValue = style.height
			local left = resolveOffsetValue(style.left, "x")
			local right = resolveOffsetValue(style.right, "x")
			local top = resolveOffsetValue(style.top, "y")
			local marginLeft = style["margin-left"] == "auto" and UDim.new(0, 0) or resolveOffsetValue(style["margin-left"], "x")
			local marginTop = style["margin-top"] == "auto" and UDim.new(0, 0) or resolveOffsetValue(style["margin-top"], "y")
			local marginRight = style["margin-right"] == "auto" and UDim.new(0, 0) or resolveOffsetValue(style["margin-right"], "x")
			local widthScale = type(widthValue) == "table" and widthValue.unit == "%" and widthValue.value / 100 or 0
			local widthOffset = type(widthValue) == "number" and widthValue or (type(widthValue) == "table" and widthValue.unit ~= "%" and resolveViewportValue(widthValue, "x") or 0)
			local heightScale = type(heightValue) == "table" and heightValue.unit == "%" and heightValue.value / 100 or 0
			local heightOffset = type(heightValue) == "number" and heightValue or (type(heightValue) == "table" and heightValue.unit ~= "%" and resolveViewportValue(heightValue, "y") or 0)
			local widthAuto = widthValue == nil or widthValue == "auto"
			local heightAuto = heightValue == nil or heightValue == "auto"
	
			wrapper.AutomaticSize = Enum.AutomaticSize.None
			wrapper.Size = UDim2.new(widthScale, widthOffset, heightScale, heightOffset)
			if widthAuto and heightAuto then
				wrapper.Size = UDim2.new(0, 0, 0, 0)
				wrapper.AutomaticSize = Enum.AutomaticSize.XY
			elseif widthAuto then
				wrapper.Size = UDim2.new(0, 0, heightScale, heightOffset)
				wrapper.AutomaticSize = Enum.AutomaticSize.X
			elseif heightAuto then
				wrapper.Size = UDim2.new(widthScale, widthOffset, 0, 0)
				wrapper.AutomaticSize = Enum.AutomaticSize.Y
			end
			local positionXScale = left.Scale + marginLeft.Scale
			local positionXOffset = left.Offset + marginLeft.Offset
			if (style.left == nil or style.left == 0)
				and (
					type(style.right) == "table"
					or (type(style.right) == "number" and style.right > 0)
				)
			then
				positionXScale = 1 - right.Scale - marginRight.Scale - widthScale
				positionXOffset = -(right.Offset + marginRight.Offset + widthOffset)
			end
			wrapper.Position = UDim2.new(positionXScale, positionXOffset, top.Scale + marginTop.Scale, top.Offset + marginTop.Offset)
		else
			local widthValue = style.width
			if type(widthValue) == "table" and widthValue.unit == "%" then
				wrapper.Size = UDim2.new(widthValue.value / 100, 0, 0, 0)
			elseif type(widthValue) == "number" and widthValue > 0 then
				wrapper.Size = UDim2.new(0, widthValue, 0, 0)
			else
				wrapper.Size = UDim2.new(1, 0, 0, 0)
			end
		end
	
		if style.position ~= "absolute" then
			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = resolveOffsetValue(style["margin-left"], "x")
			padding.PaddingRight = resolveOffsetValue(style["margin-right"], "x")
			padding.PaddingTop = resolveOffsetValue(style["margin-top"], "y")
			padding.PaddingBottom = resolveOffsetValue(style["margin-bottom"], "y")
			padding.Parent = wrapper
		end
	
		return wrapper
	end
	
	local function renderControlShell(parent, style, defaultWidth, defaultHeight)
		local wrapper = createWrapper(parent, style)
	
		local shell = Instance.new("Frame")
		shell.Name = "Control"
		shell.BackgroundColor3 = toColor3(style["background-color"] == "transparent" and "#ffffff" or style["background-color"])
		shell.BackgroundTransparency = style["background-color"] == "transparent" and 0 or 0
		shell.BorderSizePixel = 0
		shell.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)
	
		if type(style.width) == "number" and style.width > 0 then
			shell.Size = UDim2.new(0, style.width, 0, defaultHeight)
		elseif type(style.width) == "table" and style.width.unit == "%" then
			shell.Size = UDim2.new(style.width.value / 100, 0, 0, defaultHeight)
		end
	
		if type(style.height) == "number" and style.height > 0 then
			shell.Size = UDim2.new(shell.Size.X.Scale, shell.Size.X.Offset, 0, style.height)
		end
	
		shell.Parent = wrapper
		addPadding(shell, style)
		addBorders(shell, style)
		return wrapper, shell
	end
	
	local function addCorner(instance, style)
		local radius = style["border-radius"] or 0
		if radius <= 0 then
			return nil
		end
	
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius)
		corner.Parent = instance
		return corner
	end
	
	local function addBorderSegment(parent, name, size, position, color)
		local border = Instance.new("Frame")
		border.Name = name
		border.BorderSizePixel = 0
		border.BackgroundColor3 = toColor3(color)
		border.Size = size
		border.Position = position
		border.ZIndex = parent.ZIndex + 1
		border.Parent = parent
		return border
	end
	
	local function addBorders(instance, style)
		local topWidth = style["border-top-width"] or 0
		local rightWidth = style["border-right-width"] or 0
		local bottomWidth = style["border-bottom-width"] or 0
		local leftWidth = style["border-left-width"] or 0
	
		if topWidth > 0 then
			addBorderSegment(
				instance,
				"BorderTop",
				UDim2.new(1, 0, 0, topWidth),
				UDim2.new(0, 0, 0, 0),
				style["border-top-color"]
			)
		end
	
		if rightWidth > 0 then
			addBorderSegment(
				instance,
				"BorderRight",
				UDim2.new(0, rightWidth, 1, 0),
				UDim2.new(1, -rightWidth, 0, 0),
				style["border-right-color"]
			)
		end
	
		if bottomWidth > 0 then
			addBorderSegment(
				instance,
				"BorderBottom",
				UDim2.new(1, 0, 0, bottomWidth),
				UDim2.new(0, 0, 1, -bottomWidth),
				style["border-bottom-color"]
			)
		end
	
		if leftWidth > 0 then
			addBorderSegment(
				instance,
				"BorderLeft",
				UDim2.new(0, leftWidth, 1, 0),
				UDim2.new(0, 0, 0, 0),
				style["border-left-color"]
			)
		end
	end
	
	function Renderer.new(options)
		return setmetatable({
			imageResolver = options and options.imageResolver,
			imagePipeline = options and options.imagePipeline,
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
		scrollingFrame.ClipsDescendants = true
		scrollingFrame.Parent = mount
		mount.BackgroundColor3 = scrollingFrame.BackgroundColor3
		mount.BackgroundTransparency = 0
	
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
		addBorders(label, block.style)
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
	
		local host = Instance.new("Frame")
		host.Name = "Image"
		host.BackgroundColor3 = toColor3(block.style["background-color"])
		host.BackgroundTransparency = block.style["background-color"] == "transparent" and 1 or 0
		host.BorderSizePixel = 0
		local width = block.style.width
		local height = block.style.height
		if type(width) == "number" and type(height) == "number" and width > 0 and height > 0 then
			host.Size = UDim2.new(0, width, 0, height)
		else
			host.Size = UDim2.new(0, 140, 0, 140)
		end
		host.Parent = wrapper
		addBorders(host, block.style)
	
		if self.imagePipeline then
			if self.imagePipeline:apply(host, block.source, self.baseUrl) then
				return
			end
		end
	
		local resolved = self:resolveImageSource(block.source)
		if resolved and resolved:match("^rbx") then
			local image = Instance.new("ImageLabel")
			image.Name = "AssetImage"
			image.BackgroundTransparency = 1
			image.BorderSizePixel = 0
			image.ScaleType = Enum.ScaleType.Fit
			image.Size = UDim2.new(1, 0, 1, 0)
			image.Image = resolved
			image.Parent = host
		else
			host.Visible = false
		end
	end
	
	function Renderer:renderContainer(parent, block)
		local wrapper = createWrapper(parent, block.style)
	
		local container = Instance.new("Frame")
		container.Name = block.tag
		container.BackgroundColor3 = toColor3(block.style["background-color"])
		container.BackgroundTransparency = block.style["background-color"] == "transparent" and 1 or 0
		container.BorderSizePixel = 0
		container.AutomaticSize = Enum.AutomaticSize.Y
		container.Parent = wrapper
		addCorner(container, block.style)
		addBorders(container, block.style)
	
		local width = block.style.width
		if type(width) == "table" and width.unit == "%" then
			container.Size = UDim2.new(width.value / 100, 0, 0, 0)
		elseif type(width) == "number" and width > 0 then
			container.Size = UDim2.new(0, width, 0, 0)
		else
			container.Size = UDim2.new(1, 0, 0, 0)
		end
	
		if block.style["margin-left"] == "auto" and block.style["margin-right"] == "auto" and type(width) == "number" and width > 0 then
			container.AnchorPoint = Vector2.new(0.5, 0)
			container.Position = UDim2.new(0.5, 0, 0, 0)
		end
	
		local content = Instance.new("Frame")
		content.Name = "Content"
		content.BackgroundTransparency = 1
		content.BorderSizePixel = 0
		content.Size = UDim2.new(1, 0, 0, 0)
		content.AutomaticSize = Enum.AutomaticSize.Y
		content.Parent = container
	
		addPadding(content, block.style)
	
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 0)
		layout.Parent = content
	
		for _, child in ipairs(block.children) do
			self:renderBlock(content, child)
		end
	end
	
	function Renderer:renderControl(parent, block)
		local controlType = block.controlType
		if controlType == "submit" or controlType == "button" then
			local _, shell = renderControlShell(parent, block.style, 72, 24)
			local label = Instance.new("TextLabel")
			label.Name = "ButtonLabel"
			label.BackgroundTransparency = 1
			label.BorderSizePixel = 0
			label.Size = UDim2.new(1, 0, 1, 0)
			label.Font = pickFont(block.style)
			label.TextSize = block.style["font-size"]
			label.TextColor3 = toColor3(block.style.color)
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.Text = block.text ~= "" and block.text or "Submit"
			label.Parent = shell
			return
		end
	
		local _, shell = renderControlShell(parent, block.style, 176, 24)
		local label = Instance.new("TextLabel")
		label.Name = "InputValue"
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Size = UDim2.new(1, -8, 1, 0)
		label.Position = UDim2.new(0, 4, 0, 0)
		label.Font = pickFont(block.style)
		label.TextSize = block.style["font-size"]
		label.TextColor3 = toColor3(block.style.color)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = block.text
		label.Parent = shell
	end
	
	function Renderer:renderBlock(parent, block)
		if block.kind == "text" then
			self:renderText(parent, block)
		elseif block.kind == "image" then
			self:renderImage(parent, block)
		elseif block.kind == "control" then
			self:renderControl(parent, block)
		elseif block.kind == "container" then
			self:renderContainer(parent, block)
		end
	end
	
	function Renderer:render(mount, tree)
		local root = self:createRoot(mount)
		root.BackgroundColor3 = toColor3(tree.style["background-color"])
		root.BackgroundTransparency = tree.style["background-color"] == "transparent" and 1 or 0
	
		local bodyHost = Instance.new("Frame")
		bodyHost.Name = "Body"
		bodyHost.BackgroundTransparency = 1
		bodyHost.BorderSizePixel = 0
		bodyHost.Position = UDim2.new(0, 0, 0, 0)
		bodyHost.AutomaticSize = Enum.AutomaticSize.Y
		bodyHost.Parent = root
	
		local absoluteHost = Instance.new("Frame")
		absoluteHost.Name = "AbsoluteBody"
		absoluteHost.BackgroundTransparency = 1
		absoluteHost.BorderSizePixel = 0
		absoluteHost.Position = UDim2.new(0, 0, 0, 0)
		absoluteHost.Size = UDim2.new(1, 0, 0, 0)
		absoluteHost.AutomaticSize = Enum.AutomaticSize.Y
		absoluteHost.Parent = root
	
		local topMargin = resolveViewportValue(tree.style["margin-top"], "y")
		local width = tree.style.width
		if type(width) == "table" then
			width = resolveViewportValue(width, "x")
		end
	
		if type(width) == "table" and width.unit == "%" then
			bodyHost.Size = UDim2.new(width.value / 100, 0, 0, 0)
		elseif type(width) == "number" and width > 0 then
			bodyHost.Size = UDim2.new(0, width, 0, 0)
		else
			bodyHost.Size = UDim2.new(1, 0, 0, 0)
		end
	
		local bodyPadding = Instance.new("UIPadding")
		bodyPadding.PaddingTop = UDim.new(0, topMargin)
		bodyPadding.PaddingLeft = UDim.new(0, tree.style["padding-left"] or 0)
		bodyPadding.PaddingRight = UDim.new(0, tree.style["padding-right"] or 0)
		bodyPadding.PaddingBottom = UDim.new(0, tree.style["padding-bottom"] or 0)
		bodyPadding.Parent = bodyHost
	
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = bodyHost
	
		for _, child in ipairs(tree.children) do
			if child.style.position == "absolute" then
				self:renderBlock(absoluteHost, child)
			else
				self:renderBlock(bodyHost, child)
			end
		end
	
		task.defer(function()
			local maxBottom = root.AbsoluteWindowSize.Y
			for _, descendant in ipairs(root:GetDescendants()) do
				if descendant:IsA("GuiObject") and descendant.Visible then
					local relativeY = descendant.AbsolutePosition.Y - root.AbsolutePosition.Y
					local bottom = relativeY + descendant.AbsoluteSize.Y
					if bottom > maxBottom then
						maxBottom = bottom
					end
				end
			end
			root.CanvasSize = UDim2.new(0, 0, 0, math.floor(maxBottom + 16))
		end)
	
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
	
		return function(_, url)
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
		local headers = next(self.headers) ~= nil and self.headers or nil
		return self.httpService:GetAsync(resolvedUrl, false, headers)
	end
	
	function Fetcher:fetchRelative(baseUrl, path)
		return self:fetch(Url.join(baseUrl, path))
	end
	
	return Fetcher
end)

define("ImageCompression", function(loadModule)
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
end)

define("ImagePipeline", function(loadModule)
	local RunService = game:GetService("RunService")
	
	local Url = loadModule("Url")
	local ImageCompression = loadModule("ImageCompression")
	
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
end)

define("Neutron", function(loadModule)
	local HtmlParser = loadModule("HtmlParser")
	local HtmlTokenizer = loadModule("HtmlTokenizer")
	local StyleResolver = loadModule("StyleResolver")
	local LayoutEngine = loadModule("LayoutEngine")
	local Renderer = loadModule("Renderer")
	local Fetcher = loadModule("Fetcher")
	local ImagePipeline = loadModule("ImagePipeline")
	local ImageCompression = loadModule("ImageCompression")
	
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
end)

return load("Neutron")
