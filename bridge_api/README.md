# Neutron Image Bridge

This service fetches external images, downsizes them, quantizes them, and returns `palette-rle` payloads that Neutron can render inside Roblox without `EditableImage`.

## Install

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app:app --host 0.0.0.0 --port 8000
```

## Endpoint

`GET /render`

Query parameters:

- `url`
- `max_width`
- `max_height`
- `max_colors`
- `dither_strength`

Example:

```text
http://localhost:8000/render?url=https%3A%2F%2Fexample.com%2Fimage.png&max_width=128&max_height=72&max_colors=16
```

## Environment

- `NEUTRON_MAX_SOURCE_BYTES`
- `NEUTRON_REQUEST_TIMEOUT`
- `NEUTRON_BYTE_CACHE_SIZE`
- `NEUTRON_BYTE_CACHE_TTL`
- `NEUTRON_PAYLOAD_CACHE_SIZE`
- `NEUTRON_PAYLOAD_CACHE_TTL`
- `NEUTRON_ALLOW_PRIVATE_HOSTS`
