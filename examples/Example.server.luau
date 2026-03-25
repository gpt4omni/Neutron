local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Neutron = require(ReplicatedStorage.Neutron)
local imageBridgeUrl = "https://neutronbridgeapi.onrender.com/render"

local remoteFunction = ReplicatedStorage:FindFirstChild("NeutronFetch") or Instance.new("RemoteFunction")
remoteFunction.Name = "NeutronFetch"
remoteFunction.Parent = ReplicatedStorage

local imageRemoteFunction = ReplicatedStorage:FindFirstChild("NeutronImageFetch") or Instance.new("RemoteFunction")
imageRemoteFunction.Name = "NeutronImageFetch"
imageRemoteFunction.Parent = ReplicatedStorage

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

Neutron.ImagePipeline.bindBridgeRemoteFunction(imageRemoteFunction, HttpService, imageBridgeUrl)
