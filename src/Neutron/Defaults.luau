local Defaults = {}

Defaults.blockTags = {
	body = true,
	div = true,
	p = true,
	main = true,
	section = true,
	article = true,
	header = true,
	footer = true,
	nav = true,
	aside = true,
	ul = true,
	ol = true,
	li = true,
	h1 = true,
	h2 = true,
	h3 = true,
	h4 = true,
	h5 = true,
	h6 = true,
	pre = true,
	blockquote = true,
	form = true,
}

Defaults.voidTags = {
	br = true,
	hr = true,
	img = true,
	meta = true,
	link = true,
	input = true,
	source = true,
}

Defaults.inheritableProperties = {
	color = true,
	["font-size"] = true,
	["font-weight"] = true,
	["font-style"] = true,
	["text-align"] = true,
	["text-decoration"] = true,
	["font-family"] = true,
	["text-transform"] = true,
	["list-style-type"] = true,
}

Defaults.namedColors = {
	black = "#000000",
	silver = "#c0c0c0",
	gray = "#808080",
	white = "#ffffff",
	maroon = "#800000",
	red = "#ff0000",
	purple = "#800080",
	fuchsia = "#ff00ff",
	green = "#008000",
	lime = "#00ff00",
	olive = "#808000",
	yellow = "#ffff00",
	navy = "#000080",
	blue = "#0000ff",
	teal = "#008080",
	aqua = "#00ffff",
	transparent = "transparent",
}

Defaults.userAgentStyles = {
	html = {
		display = "block",
		["font-size"] = 16,
		color = "#111111",
	},
	body = {
		display = "block",
		["font-size"] = 16,
		color = "#111111",
		["background-color"] = "#ffffff",
		padding = 16,
	},
	head = {
		display = "none",
	},
	title = {
		display = "none",
	},
	style = {
		display = "none",
	},
	script = {
		display = "none",
	},
	div = {
		display = "block",
	},
	form = {
		display = "block",
	},
	span = {
		display = "inline",
	},
	input = {
		display = "inline",
	},
	p = {
		display = "block",
		["margin-top"] = 0,
		["margin-bottom"] = 12,
	},
	a = {
		display = "inline",
		color = "#1a73e8",
		["text-decoration"] = "underline",
	},
	strong = {
		display = "inline",
		["font-weight"] = "bold",
	},
	b = {
		display = "inline",
		["font-weight"] = "bold",
	},
	em = {
		display = "inline",
		["font-style"] = "italic",
	},
	i = {
		display = "inline",
		["font-style"] = "italic",
	},
	u = {
		display = "inline",
		["text-decoration"] = "underline",
	},
	br = {
		display = "inline",
	},
	ul = {
		display = "block",
		["margin-bottom"] = 12,
		["list-style-type"] = "disc",
	},
	ol = {
		display = "block",
		["margin-bottom"] = 12,
		["list-style-type"] = "decimal",
	},
	li = {
		display = "block",
		["margin-bottom"] = 6,
	},
	h1 = {
		display = "block",
		["font-size"] = 32,
		["font-weight"] = "bold",
		["margin-bottom"] = 14,
	},
	h2 = {
		display = "block",
		["font-size"] = 28,
		["font-weight"] = "bold",
		["margin-bottom"] = 12,
	},
	h3 = {
		display = "block",
		["font-size"] = 24,
		["font-weight"] = "bold",
		["margin-bottom"] = 10,
	},
	h4 = {
		display = "block",
		["font-size"] = 20,
		["font-weight"] = "bold",
		["margin-bottom"] = 8,
	},
	h5 = {
		display = "block",
		["font-size"] = 18,
		["font-weight"] = "bold",
		["margin-bottom"] = 8,
	},
	h6 = {
		display = "block",
		["font-size"] = 16,
		["font-weight"] = "bold",
		["margin-bottom"] = 8,
	},
}

return Defaults
