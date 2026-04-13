# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Volební atlas — interactive electoral map of Czech Pirate Party (Piráti) results in the 2025 parliamentary elections. Spatial exploration of GWR (Geographically Weighted Regression) analysis results at municipality (obec), ORP, district (okres), and region (kraj) levels, including custom polygon drawing.

## No build step

This is **pure vanilla JS/HTML/CSS** — no bundler, no npm, no compilation. Edit files and refresh the browser. All dependencies are loaded from CDN in `index.html`.

## Serving for development

Open `index.html` directly in a browser, or serve the parent `web/public/` directory via any static server:

```bash
# From the repo root or web/public/
python3 -m http.server 8080
# Then open http://localhost:8080/map/
```

## Backend setup

The frontend talks to a FastAPI + PostGIS backend via a Cloudflare Tunnel URL hardcoded at the top of `app.js`:

```javascript
// app.js, line 4
const API = 'https://shanghai-villages-doors-tucson.trycloudflare.com';
```

When the tunnel URL changes, update this constant. For a local dev backend:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
# Then set API = 'http://localhost:8000' in app.js
```

Data import into PostGIS:
```bash
ogr2ogr -f "PostgreSQL" PG:"dbname=pogeo user=postgres" \
  data/processed/pirati_final.gpkg -nln obce -overwrite
```

## Architecture

```
web/public/map/
  index.html   — HTML shell + CDN imports (Leaflet, Leaflet.Draw, Chart.js)
  app.js       — ALL application logic (single file, ~640 lines)
  style.css    — All styles
```

**`app.js` is the entire application.** It is structured into clearly delimited sections with `// ─── SECTION ───` headers:

| Section | Responsibility |
|---------|----------------|
| `CONFIG` | `API` URL, `IND` indicator definitions (label, unit, color scale), tile URLs |
| `STATE` (`S`)  | Single global state object — map instance, layers, caches, current selection |
| `BOOT` | `DOMContentLoaded` → `initMap()` → `initDraw()` → `bindAll()` → `readURL()` → `boot()` |
| `MAP` | Leaflet init, tile layer switching |
| `DRAW` | Leaflet.Draw polygon tool → `analyzePolygon()` |
| `GEOJSON LOADING` | Fetches and caches GeoJSON per level; computes min/max ranges for choropleth |
| `UNITS DROPDOWN` | Fetches unit lists, renders searchable dropdown |
| `SELECTION & ANALYSIS` | `selectUnit()`, `analyze()`, `analyzePolygon()`, `fetchStats()` |
| `CHOROPLETH` | `updateChoropleth()`, `highlightFeature()`, `featureStyle()`, `colorFor()` |
| `HOVER / CLICK` | Tooltip on hover, click-to-analyze on municipality layer |
| `RENDER STATS` | `renderStats()` — populates all panel DOM elements from API response |
| `CHARTS` | `drawAge()` (horizontal bar), `drawEdu()` (doughnut) via Chart.js |
| `LEGEND` | Updates gradient legend bar |
| `URL` | `updateURL()` / `readURL()` — `?level=&id=&indicator=` params |
| `UI HELPERS` | `set()`, `fmtPct()`, `progSet()`, `showResults()`, `setBtnLoad()`, etc. |
| `FETCH WITH ABORT` | `apiFetch()` — wraps `fetch` with AbortController to cancel in-flight requests |
| `EVENT BINDINGS` | `bindAll()` — wires all DOM events |

## Key data flow

1. On boot: loads obce GeoJSON (includes all choropleth indicator values in `properties`), computes `S.ranges` for each indicator — **no per-feature API calls for choropleth coloring**.
2. User selects level → loads GeoJSON boundaries (orp/okresy/kraje) and unit list from API.
3. User selects unit → `fetchStats(level, id)` → `renderStats()` → updates panel + charts.
4. Custom polygon draw → Leaflet.Draw → `analyzePolygon(geometry)` → `POST /api/stats/custom`.

## GeoJSON property name variants

The backend may return different property names. `app.js` handles both via `??` chaining:
- ID: `f.properties.id ?? f.properties.kod_obce ?? f.properties.kod ?? f.properties.kod_orp ?? f.properties.kod_okres`
- Name: `f.properties.nazev ?? f.properties.name ?? f.properties.nazev_orp`

## Mobile responsiveness

On mobile, `#panel` becomes a slide-up bottom sheet. The `.panel-handle` click toggles `.open` class. `renderStats()` also programmatically adds `.open` when results arrive.

## Color scale format

Each indicator in `IND` has a `scale` array of RGB stop arrays, e.g.:
```javascript
pirati_pct: { scale: [[26,10,46], [109,31,190], [180,100,255]] }
```
`colorFor()` interpolates linearly between stops based on normalized value position.
