local Url = require(script.Parent.Url)

local Fetcher = {}
Fetcher.__index = Fetcher

local function interpolate(template, url, encodedUrl)
	return template:gsub("{url_encoded}", encodedUrl):gsub("{url}", url)
end

local function createFetcher(state)
	return setmetatable(state, Fetcher)
end

function Fetcher.new(httpService, options)
	assert(httpService, "Fetcher.new requires HttpService")

	options = options or {}

	return createFetcher({
		httpService = httpService,
		proxyTemplate = options.proxyTemplate,
		headers = options.headers or {},
		transformUrl = options.transformUrl,
		remoteFunction = nil,
	})
end

function Fetcher.fromRemoteFunction(remoteFunction, options)
	assert(remoteFunction, "Fetcher.fromRemoteFunction requires a RemoteFunction")

	options = options or {}

	return createFetcher({
		httpService = nil,
		proxyTemplate = options.proxyTemplate,
		headers = options.headers or {},
		transformUrl = options.transformUrl,
		remoteFunction = remoteFunction,
	})
end

function Fetcher.createRemoteHandler(httpService, options)
	local fetcher = Fetcher.new(httpService, options)

	return function(_, url)
		return fetcher:fetch(url)
	end
end

function Fetcher.bindRemoteFunction(remoteFunction, httpService, options)
	assert(remoteFunction, "Fetcher.bindRemoteFunction requires a RemoteFunction")
	remoteFunction.OnServerInvoke = Fetcher.createRemoteHandler(httpService, options)
	return remoteFunction
end

function Fetcher.isRemote(self)
	return self.remoteFunction ~= nil
end

function Fetcher:resolve(url)
	if type(self.transformUrl) == "function" then
		return self.transformUrl(url)
	end

	if self.proxyTemplate then
		if self.httpService then
			return interpolate(self.proxyTemplate, url, self.httpService:UrlEncode(url))
		end
		return interpolate(self.proxyTemplate, url, url)
	end

	return url
end

function Fetcher:fetch(url)
	if self.remoteFunction then
		local resolvedUrl = self:resolve(url)
		return self.remoteFunction:InvokeServer(resolvedUrl)
	end

	assert(self.httpService, "Fetcher:fetch requires HttpService or a RemoteFunction bridge")
	local resolvedUrl = self:resolve(url)
	local headers = next(self.headers) ~= nil and self.headers or nil
	return self.httpService:GetAsync(resolvedUrl, false, headers)
end

function Fetcher:fetchRelative(baseUrl, path)
	return self:fetch(Url.join(baseUrl, path))
end

return Fetcher
