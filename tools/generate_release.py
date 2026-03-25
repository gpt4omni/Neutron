from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src" / "Neutron"
OUT = ROOT / "release" / "Neutron.module.lua"

ORDER = [
    "Defaults",
    "Url",
    "HtmlEntities",
    "HtmlTokenizer",
    "HtmlParser",
    "CssParser",
    "StyleResolver",
    "LayoutEngine",
    "Renderer",
    "Fetcher",
    "ImageCompression",
    "ImagePipeline",
    "Neutron",
]

SOURCE_NAME = {
    "Neutron": "init.luau",
}


def read_module(name: str) -> str:
    file_name = SOURCE_NAME.get(name, f"{name}.luau")
    return (SRC / file_name).read_text()


def rewrite_requires(text: str) -> str:
    text = re.sub(
        r'local\s+(\w+)\s*=\s*require\(script\.Parent\.(\w+)\)',
        lambda m: f'local {m.group(1)} = loadModule("{m.group(2)}")',
        text,
    )
    text = re.sub(
        r'local\s+(\w+)\s*=\s*require\(script\.(\w+)\)',
        lambda m: f'local {m.group(1)} = loadModule("{m.group(2)}")',
        text,
    )
    return text


def indent(text: str, prefix: str) -> str:
    return "".join(prefix + line if line else prefix for line in text.splitlines(True))


parts = [
    "local modules = {}\n",
    "local cache = {}\n\n",
    "local function define(name, factory)\n\tmodules[name] = factory\nend\n\n",
    "local function load(name)\n",
    "\tlocal existing = cache[name]\n",
    "\tif existing ~= nil then\n\t\treturn existing\n\tend\n\n",
    "\tlocal factory = modules[name]\n",
    "\tassert(factory, string.format(\"Missing module %s\", name))\n",
    "\tlocal value = factory(load)\n",
    "\tcache[name] = value\n",
    "\treturn value\n",
    "end\n\n",
]

for name in ORDER:
    source = rewrite_requires(read_module(name))
    parts.append(f'define("{name}", function(loadModule)\n')
    parts.append(indent(source, "\t"))
    if not source.endswith("\n"):
        parts.append("\n")
    parts.append("end)\n\n")

parts.append('return load("Neutron")\n')

OUT.write_text("".join(parts))
