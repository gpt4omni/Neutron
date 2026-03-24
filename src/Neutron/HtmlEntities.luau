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
