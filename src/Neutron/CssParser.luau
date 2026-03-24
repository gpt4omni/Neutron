local CssParser = {}

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function coerceValue(value)
	value = trim(value)

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
