# Volební atlas · Piráti PSP 2025

[![Leaflet](https://img.shields.io/badge/Leaflet-1.9.4-green.svg)](https://leafletjs.com/)
[![Chart.js](https://img.shields.io/badge/Chart.js-4.4-FF6384.svg)](https://www.chartjs.org/)
[![PostGIS](https://img.shields.io/badge/Backend-PostGIS-336791.svg)](https://postgis.net/)
[![Cloudflare](https://img.shields.io/badge/Tunnel-Cloudflare-F38020.svg)](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

Interaktivní volební atlas výsledků České pirátské strany v parlamentních volbách 2025. Umožňuje prostorovou exploraci výsledků GWR analýzy na úrovni obcí, ORP, okresů a krajů — včetně kreslení vlastních polygonů.

## Funkce

- **Choropleth mapa** 6 157 obcí s přepínáním ukazatelů (% Pirátů, vzdělání VŠ, věk 65+, nezaměstnanost, věřící, Romové)
- **Výběr jednotky** — Obce / ORP / Okresy / Kraje se searchable dropdownem
- **Vlastní polygon** — Leaflet.Draw → POST na backend → prostorový překryv a vážený průměr
- **Výsledkový panel** se třemi záložkami:
  - *Volby* — % Pirátů, OLS predikce, GWR reziduum, lokální R²
  - *Demografie* — věková pyramida, pohlaví, věřící, Romové
  - *Vzdělání & Práce* — vzdělanostní struktura, zaměstnanost, podnikatelé, důchodci
- **Přepínač podkladů** — CartoDB Dark / OpenStreetMap / ČÚZK Ortofoto (WMS)
- **URL parametry** pro sdílení stavu (`?level=kraje&id=1&indicator=pirati_pct`)
- Responsivní — na mobilu panel jako slide-up bottom sheet

## Architektura

```
[Leaflet frontend]  →  [Cloudflare Tunnel]  →  [Ubuntu server]
  petrmikeska.cz                                  PostGIS + FastAPI
  /pogeo/map/                                      localhost:8000
```

Frontend je čistý vanilla JS (bez build stepu), hostovaný jako statický soubor v rámci Vite projektu (`web/public/`).

## API endpointy

Backend musí implementovat následující endpointy:

| Metoda | Endpoint | Popis |
|--------|----------|-------|
| `GET` | `/api/geojson/obce` | GeoJSON všech obcí s atributy |
| `GET` | `/api/geojson/orp` | GeoJSON hranic ORP |
| `GET` | `/api/geojson/okresy` | GeoJSON hranic okresů |
| `GET` | `/api/geojson/kraje` | GeoJSON hranic krajů |
| `GET` | `/api/units/{level}` | Seznam jednotek pro dropdown `[{id, name}]` |
| `GET` | `/api/stats/{level}/{id}` | Statistiky pro admin jednotku |
| `POST` | `/api/stats/custom` | Statistiky pro vlastní polygon `{"geometry": <GeoJSON>}` |

### Odpověď `/api/stats`

```json
{
  "pirati_pct": 11.07,
  "fitted_ols": 8.23,
  "resid_ols": 2.84,
  "resid_gwr": 0.12,
  "local_r2": 0.7795,
  "muzi": 49.5,
  "zeny": 50.5,
  "vek0_14": 15.2,
  "vek15_64": 63.1,
  "vek65": 21.7,
  "vzdelani_bez": 0.4,
  "vzdelani_zaklad": 12.1,
  "vzdelani_str_bez": 33.2,
  "vzdelani_str_s": 31.5,
  "vzdelani_vos": 2.1,
  "vzdelani_vysoko": 20.7,
  "romove": 0.08,
  "verici": 18.22,
  "zamestnanci": 72.1,
  "zamestnavatele": 2.3,
  "podnikatele": 14.2,
  "nezamest": 3.41,
  "prac_duch": 5.8,
  "neprac_duch": 22.1,
  "pocet_obci": 39
}
```

### GeoJSON atributy obcí (`/api/geojson/obce`)

Features musí obsahovat v `properties`:
- `id` nebo `kod_obce` — identifikátor pro stats lookup
- `nazev` nebo `name` — název obce
- Všechny ukazatele (`pirati_pct`, `vzdelani_vysoko`, `vek65`, `nezamest`, `verici`, `romove`) pro lokální choropleth bez API volání

## Spuštění backendu (Ubuntu + PostGIS)

### 1. Import dat do PostGIS

```bash
# Import GeoPackage
ogr2ogr -f "PostgreSQL" PG:"dbname=pogeo user=postgres" \
  data/processed/pirati_final.gpkg \
  -nln obce -overwrite

# Import hranic ORP, okresů, krajů (pokud máš jako SHP/GPKG)
ogr2ogr -f "PostgreSQL" PG:"dbname=pogeo user=postgres" orp.gpkg -nln orp
ogr2ogr -f "PostgreSQL" PG:"dbname=pogeo user=postgres" okresy.gpkg -nln okresy
ogr2ogr -f "PostgreSQL" PG:"dbname=pogeo user=postgres" kraje.gpkg -nln kraje
```

### 2. FastAPI backend

```python
# requirements.txt
fastapi
uvicorn
asyncpg
shapely
geojson

# Spuštění
uvicorn main:app --host 0.0.0.0 --port 8000
```

Prostorový překryv pro vlastní polygon (PostGIS SQL):
```sql
SELECT
  AVG(o.pirati_pct * ST_Area(ST_Intersection(o.geom, $1::geometry)) / ST_Area(o.geom))
    AS pirati_pct,
  COUNT(*) AS pocet_obci
FROM obce o
WHERE ST_Intersects(o.geom, $1::geometry)
  AND ST_Area(ST_Intersection(o.geom, $1::geometry)) / ST_Area(o.geom) > 0.1;
```

### 3. Cloudflare Tunnel

```bash
# Instalace
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o cloudflared && chmod +x cloudflared && sudo mv cloudflared /usr/local/bin/

# Spuštění quick tunelu (bez registrace, URL se vygeneruje)
cloudflared tunnel --url http://localhost:8000

# Výstup: https://xxxxx-yyyyy-zzzz.trycloudflare.com
# Tuto URL nastavit jako API v app.js
```

> Pro permanentní tunel s vlastní doménou: `cloudflared tunnel create pogeo` + DNS CNAME záznam.

### 4. Aktualizace API URL v `app.js`

```javascript
// app.js, řádek 4
const API = 'https://tvoje-tunnel-url.trycloudflare.com';
```

## Soubory

| Soubor | Popis |
|--------|-------|
| `index.html` | HTML struktura, CDN závislosti |
| `app.js` | Veškerá logika — mapa, API, grafy, URL params |
| `style.css` | Styly sjednocené s hlavním projektem |

## Technologie

- **Leaflet 1.9.4** — interaktivní mapa
- **Leaflet.Draw 1.0.4** — kreslení polygonů
- **Chart.js 4.4** — věková pyramida, vzdělanostní doughnut
- **ČÚZK WMS** — letecká ortofotomapa
- Vanilla JS ES6, žádný build step
