local Defaults = require(script.Parent.Defaults)
local HtmlTokenizer = require(script.Parent.HtmlTokenizer)

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
