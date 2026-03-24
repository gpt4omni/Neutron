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

	local red, green, blue = lowered:match("^#(%x)(%x)(%x)$")
	if red and green and blue then
		return "#" .. red .. red .. green .. green .. blue .. blue
	end

	return lowered
end

local function resolveLength(value, baseFontSize)
	if type(value) == "number" then
		return value
	end

	if type(value) == "table" then
		if value.unit == "em" then
			return math.floor((baseFontSize or 16) * value.value + 0.5)
		end

		return value
	end

	return tonumber(value) or 0
end

local function normalizeBoxValue(style, property, baseFontSize)
	local value = style[property]
	if value == nil then
		return 0
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

local function normalizeComputedStyle(style)
	style.display = style.display or "inline"
	if style.background ~= nil then
		style["background-color"] = style.background
	end
	style.color = normalizeColor(style.color or "#111111")
	style["background-color"] = normalizeColor(style["background-color"] or "transparent")
	style["font-size"] = tonumber(style["font-size"]) or 16
	style["font-weight"] = style["font-weight"] or "normal"
	style["font-style"] = style["font-style"] or "normal"
	style["text-align"] = style["text-align"] or "left"
	style["text-decoration"] = style["text-decoration"] or "none"
	style["font-family"] = style["font-family"] or "Gotham"
	expandBoxShorthand(style, "padding")
	expandBoxShorthand(style, "margin")
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
	style.width = style.width == "auto" and "auto" or resolveLength(style.width, style["font-size"])
	style["border-radius"] = resolveLength(style["border-radius"], style["font-size"])
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
