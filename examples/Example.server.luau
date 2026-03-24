local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Neutron = require(ReplicatedStorage.Neutron)

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "NeutronFetch"
remoteFunction.Parent = ReplicatedStorage

local directFetcher = Neutron.Fetcher.new(HttpService)
local proxyFetcher = Neutron.Fetcher.new(HttpService, {
	transformUrl = function(url)
		return "https://r.jina.ai/http://" .. url:gsub("^https?://", "")
	end,
})

remoteFunction.OnServerInvoke = function(_, url)
	local ok, result = pcall(function()
		return directFetcher:fetch(url)
	end)

	if ok then
		return result
	end

	return proxyFetcher:fetch(url)
end
