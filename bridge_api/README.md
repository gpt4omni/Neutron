# Neutron Image Bridge API

This service fetches external images, downsizes them, quantizes them, and returns `palette-rle` payloads that Neutron can render inside Roblox without `EditableImage`, as it requires ID.

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

## endpoint

`GET /render`

parameters:

- `url`
- `max_width`
- `max_height`
- `max_colors`
- `dither_strength`

Example:
```text
http://localhost:8000/render?url=https%3A%2F%2Fexample.com%2Fimage.png&max_width=128&max_height=72&max_colors=16
```
