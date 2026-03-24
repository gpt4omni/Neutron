local Url = require(script.Parent.Url)

local Fetcher = {}
Fetcher.__index = Fetcher

local function interpolate(template, url, encodedUrl)
	return template:gsub("{url_encoded}", encodedUrl):gsub("{url}", url)
end

function Fetcher.new(httpService, options)
	return setmetatable({
		httpService = httpService,
		proxyTemplate = options and options.proxyTemplate,
		headers = options and options.headers or {},
		transformUrl = options and options.transformUrl,
	}, Fetcher)
end

function Fetcher:resolve(url)
	if type(self.transformUrl) == "function" then
		return self.transformUrl(url)
	end

	if self.proxyTemplate then
		return interpolate(self.proxyTemplate, url, self.httpService:UrlEncode(url))
	end

	return url
end

function Fetcher:fetch(url)
	local resolvedUrl = self:resolve(url)
	return self.httpService:GetAsync(resolvedUrl, false, self.headers)
end

function Fetcher:fetchRelative(baseUrl, path)
	return self:fetch(Url.join(baseUrl, path))
end

return Fetcher
