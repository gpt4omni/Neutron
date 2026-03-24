local HtmlEntities = require(script.Parent.HtmlEntities)

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
