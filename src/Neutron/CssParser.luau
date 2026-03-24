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
