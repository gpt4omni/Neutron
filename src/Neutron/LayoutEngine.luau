local Defaults = require(script.Parent.Defaults)

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
