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
