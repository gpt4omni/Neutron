local Defaults = require(script.Parent.Defaults)
local CssParser = require(script.Parent.CssParser)

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
