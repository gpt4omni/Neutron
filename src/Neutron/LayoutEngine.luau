local Defaults = require(script.Parent.Defaults)

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
