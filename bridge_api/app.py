import asyncio
import io
import ipaddress
import os
import socket
import time
from collections import OrderedDict
from typing import Any
from urllib.parse import urlparse

import httpx
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import JSONResponse
from PIL import Image, ImageOps


class LruTtlCache:
    def __init__(self, max_size: int, ttl_seconds: float) -> None:
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds
        self._items: OrderedDict[str, tuple[float, Any]] = OrderedDict()
        self._lock = asyncio.Lock()

    async def get(self, key: str) -> Any | None:
        async with self._lock:
            item = self._items.get(key)
            if item is None:
                return None
            expires_at, value = item
            if expires_at <= time.monotonic():
                self._items.pop(key, None)
                return None
            self._items.move_to_end(key)
            return value

    async def set(self, key: str, value: Any) -> None:
        async with self._lock:
            self._items[key] = (time.monotonic() + self.ttl_seconds, value)
            self._items.move_to_end(key)
            while len(self._items) > self.max_size:
                self._items.popitem(last=False)


MAX_SOURCE_BYTES = int(os.getenv("NEUTRON_MAX_SOURCE_BYTES", str(8 * 1024 * 1024)))
REQUEST_TIMEOUT = float(os.getenv("NEUTRON_REQUEST_TIMEOUT", "12"))
BYTE_CACHE_SIZE = int(os.getenv("NEUTRON_BYTE_CACHE_SIZE", "128"))
BYTE_CACHE_TTL = float(os.getenv("NEUTRON_BYTE_CACHE_TTL", "300"))
PAYLOAD_CACHE_SIZE = int(os.getenv("NEUTRON_PAYLOAD_CACHE_SIZE", "512"))
PAYLOAD_CACHE_TTL = float(os.getenv("NEUTRON_PAYLOAD_CACHE_TTL", "1800"))
ALLOW_PRIVATE_HOSTS = os.getenv("NEUTRON_ALLOW_PRIVATE_HOSTS", "").lower() in {"1", "true", "yes"}

byte_cache = LruTtlCache(BYTE_CACHE_SIZE, BYTE_CACHE_TTL)
payload_cache = LruTtlCache(PAYLOAD_CACHE_SIZE, PAYLOAD_CACHE_TTL)

app = FastAPI(title="Neutron Image Bridge", version="1.0.0")
http_client = httpx.AsyncClient(
    follow_redirects=True,
    timeout=httpx.Timeout(REQUEST_TIMEOUT),
    limits=httpx.Limits(max_connections=128, max_keepalive_connections=32),
    headers={"User-Agent": "NeutronImageBridge/1.0"},
)


def clamp(value: float, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, int(value)))


def is_public_address(hostname: str) -> bool:
    try:
        records = socket.getaddrinfo(hostname, None, proto=socket.IPPROTO_TCP)
    except socket.gaierror:
        return False

    for record in records:
        address = record[4][0]
        ip = ipaddress.ip_address(address)
        if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved or ip.is_multicast:
            return False
    return True


def validate_url(url: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise HTTPException(status_code=400, detail="Only http and https URLs are supported")
    if not parsed.netloc:
        raise HTTPException(status_code=400, detail="Missing host")
    if not ALLOW_PRIVATE_HOSTS and not is_public_address(parsed.hostname or ""):
        raise HTTPException(status_code=400, detail="Host is not publicly routable")


def calculate_target_size(width: int, height: int, max_width: int, max_height: int) -> tuple[int, int]:
    if width <= 0 or height <= 0:
        return 1, 1
    scale = min(max_width / width, max_height / height, 1)
    return max(1, int(width * scale + 0.5)), max(1, int(height * scale + 0.5))


def build_payload(image_bytes: bytes, max_width: int, max_height: int, max_colors: int) -> dict[str, Any]:
    with Image.open(io.BytesIO(image_bytes)) as opened:
        image = ImageOps.exif_transpose(opened).convert("RGBA")

    target_width, target_height = calculate_target_size(image.width, image.height, max_width, max_height)
    resized = image.resize((target_width, target_height), Image.Resampling.LANCZOS)

    alpha = resized.getchannel("A")
    alpha_values = list(alpha.getdata())
    transparent_mask = [value < 32 for value in alpha_values]

    rgb = Image.new("RGB", resized.size, (255, 255, 255))
    rgb.paste(resized.convert("RGB"), mask=alpha)

    color_budget = max(1, min(16, max_colors) - (1 if any(transparent_mask) else 0))
    quantized = rgb.quantize(colors=color_budget, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    indexed_pixels = list(quantized.getdata())
    raw_palette = quantized.getpalette() or []

    used_indexes = []
    seen_indexes: set[int] = set()
    alpha_totals: dict[int, tuple[int, int]] = {}

    for index, alpha_value in zip(indexed_pixels, alpha_values):
        if alpha_value < 32:
            continue
        if index not in seen_indexes:
            seen_indexes.add(index)
            used_indexes.append(index)
        total_alpha, count = alpha_totals.get(index, (0, 0))
        alpha_totals[index] = (total_alpha + alpha_value, count + 1)

    palette: list[list[int]] = []
    index_map: dict[int, int] = {}

    if any(transparent_mask):
        palette.append([0, 0, 0, 0])

    for source_index in used_indexes:
        base = source_index * 3
        average_alpha, alpha_count = alpha_totals[source_index]
        alpha_value = int(average_alpha / max(1, alpha_count) + 0.5)
        index_map[source_index] = len(palette)
        palette.append([
            raw_palette[base] if base < len(raw_palette) else 0,
            raw_palette[base + 1] if base + 1 < len(raw_palette) else 0,
            raw_palette[base + 2] if base + 2 < len(raw_palette) else 0,
            alpha_value,
        ])

    rows: list[list[dict[str, int]]] = []
    for y in range(target_height):
        row_runs: list[dict[str, int]] = []
        last_color = None
        run_count = 0

        for x in range(target_width):
            pixel_offset = y * target_width + x
            if transparent_mask[pixel_offset]:
                color_index = 0
            else:
                color_index = index_map[indexed_pixels[pixel_offset]]

            if color_index == last_color:
                run_count += 1
            else:
                if last_color is not None and run_count > 0:
                    row_runs.append({"color": last_color + 1, "count": run_count})
                last_color = color_index
                run_count = 1

        if last_color is not None and run_count > 0:
            row_runs.append({"color": last_color + 1, "count": run_count})

        rows.append(row_runs)

    return {
        "format": "palette-rle",
        "width": target_width,
        "height": target_height,
        "palette": palette,
        "rows": rows,
    }


async def fetch_image_bytes(url: str) -> bytes:
    cached = await byte_cache.get(url)
    if cached is not None:
        return cached

    response = await http_client.get(url)
    response.raise_for_status()

    content_length = response.headers.get("content-length")
    if content_length and int(content_length) > MAX_SOURCE_BYTES:
        raise HTTPException(status_code=413, detail="Image is too large")

    content = response.content
    if len(content) > MAX_SOURCE_BYTES:
        raise HTTPException(status_code=413, detail="Image is too large")

    await byte_cache.set(url, content)
    return content


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/render")
async def render(
    url: str = Query(...),
    max_width: int = Query(128, ge=1, le=256),
    max_height: int = Query(72, ge=1, le=256),
    max_colors: int = Query(16, ge=2, le=16),
    dither_strength: float = Query(0.2, ge=0, le=1),
) -> JSONResponse:
    del dither_strength
    validate_url(url)

    cache_key = "|".join([
        url,
        str(max_width),
        str(max_height),
        str(max_colors),
    ])
    cached = await payload_cache.get(cache_key)
    if cached is not None:
        return JSONResponse(cached)

    try:
        image_bytes = await fetch_image_bytes(url)
        payload = await asyncio.to_thread(build_payload, image_bytes, max_width, max_height, max_colors)
    except HTTPException:
        raise
    except httpx.HTTPStatusError as error:
        raise HTTPException(status_code=error.response.status_code, detail="Upstream image request failed") from error
    except httpx.HTTPError as error:
        raise HTTPException(status_code=502, detail="Failed to fetch image") from error
    except Exception as error:
        raise HTTPException(status_code=400, detail=f"Failed to decode image: {error}") from error

    await payload_cache.set(cache_key, payload)
    return JSONResponse(payload)


@app.on_event("shutdown")
async def shutdown_event() -> None:
    await http_client.aclose()
