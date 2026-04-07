# Workflow: GWR analýza volebního úspěchu Pirátů

## Přehled dat v GPKG

Soubor `csu_geodb_sde_CISOB_volbypspdvacetpet_etl_20240701.gpkg` obsahuje:
- **6258 obcí** ČR s polygony (MULTIPOLYGON)
- Volby do PSP ČR 2025-10-04
- Sloupce v kódech ČSÚ:

| Kód sloupce     | Popis (pravděpodobný)                 | Typ     |
|-----------------|---------------------------------------|---------|
| `kod`           | Kód obce (LAU2)                       | TEXT    |
| `nazev`         | Název obce                            | TEXT    |
| `datum`         | Datum voleb                           | DATE    |
| `gis224950001`  | Voliči v seznamu (registrovaní)       | počet   |
| `gis224960001`  | Vydané obálky                         | počet   |
| `gis224970001`  | Volební účast (%)                     | procento|
| `gis224830000`  | Platné hlasy celkem                   | počet   |
| `gis22483000X`  | Hlasy pro stranu X (absolutně)        | počet   |
| `gis22485000X`  | Hlasy pro stranu X (% z platných)     | procento|

Strany v datech (X = číslo na kandidátce):
- X=2, X=3, X=5, X=6, X=7, X=8, X=9

**ÚKOL: Ověřit, která hodnota X odpovídá Pirátům.** Nápověda z dat:
- Entity 3: průměr 38 %, silná venkov → pravděpodobně ANO
- Entity 2: průměr 20 %, Praha 34 % → pravděpodobně SPOLU
- Entity 6: průměr 6.8 %, Praha 16.85 % → pravděpodobně Piráti (silný urban bias)
- Entity 8: průměr 11 % → STAN / Motoristé?
- Entity 5: průměr 8.3 % → SPD?
- Entity 7: průměr 7.7 % → ?
- Entity 9: průměr 4.6 % → menší strana

Ověřte na webu volby.cz nebo v ČSÚ, který kód odpovídá Pirátům.

---

## A) Detailní workflow krok za krokem

### FÁZE 1: Příprava dat (R)

#### 1.1 Načtení volebních dat z GPKG
```r
library(sf)
volby <- st_read("data/raw/csu_geodb_sde_CISOB_volbypspdvacetpet_etl_20240701.gpkg")
```
- Přejmenovat sloupce na srozumitelné názvy
- Ověřit CRS (pravděpodobně S-JTSK / EPSG:5514 nebo WGS84)
- Transformovat na EPSG:5514 (S-JTSK Krovak), pokud ještě není

#### 1.2 Identifikace závislé proměnné
- **Závislá proměnná (Y)**: podíl hlasů Pirátů (%) = sloupec `gis22485000X` kde X = číslo Pirátů
- Alternativa: podíl hlasů z registrovaných voličů (hlasy / voliči * 100)
- **Doporučení**: použít % z platných hlasů — je přímo v datech a standardní v české volební geografii

#### 1.3 Získání dat ze SLDB 2021
Zdroj: https://www.czso.cz/csu/czso/vysledky-scitani-2021 → Veřejná databáze ČSÚ

Potřebná data po obcích (LAU2):
- **Věková struktura**: podíl 18–34, 35–64, 65+
- **Vzdělání**: podíl VŠ vzdělaných, podíl bez maturity
- **Zaměstnanost**: míra nezaměstnanosti, podíl OSVČ
- **Ekonomické sektory**: podíl v terciéru/IT/kultuře
- **Bydlení**: podíl nájemního bydlení vs. vlastní
- **Národnost/cizinci**: podíl cizinců
- **Rodinný stav**: podíl singles (svobodných)
- **Náboženství**: podíl bez vyznání (volitelně)
- **Urbanizace**: počet obyvatel / hustota

Stáhnout jako CSV → uložit do `data/raw/`

**Doplňková data (nepovinná, ale cenná)**:
- Průměrná mzda po okresech (MPSV/ČSÚ)
- Dostupnost internetu (ČTÚ)
- Vzdálenost od krajského města (výpočet v R)

#### 1.4 Spojení dat
```r
sldb <- read.csv("data/raw/sldb_obce.csv")
data <- merge(volby, sldb, by.x = "kod", by.y = "kod_obce")
```

#### 1.5 Příprava proměnných
- Všechny prediktory jako **podíly/procenta** (ne absolutní čísla) — normalizace na velikost obce
- Kontrola NA → případné vyloučení obcí bez dat
- Vyloučení extrémně malých obcí (< 50 voličů) → nestabilní podíly
- Výpočet centroidů pro GWR (pokud potřeba)

#### 1.6 Agregace na vyšší úroveň (volitelně)
- Obce (6258) jsou vhodné pro OLS, ale pro GWR může být výpočetně náročné
- **Alternativa**: agregovat na ORP (206 jednotek) — výpočetně snazší, robustnější podíly
- **Doporučení**: zůstat na obcích, ale pro GWR případně filtrovat na obce > 200 voličů

---

### FÁZE 2: Explorační analýza (R)

#### 2.1 Základní popisná statistika
```r
summary(data$pirati_pct)
hist(data$pirati_pct, breaks = 40)
```

#### 2.2 Mapa volebního úspěchu
```r
library(tmap)
tm_shape(data) + tm_fill("pirati_pct", style = "quantile", n = 7, palette = "YlOrRd")
```
Tato mapa jde do prezentace. Exportovat i jako GPKG pro ArcGIS Pro.

#### 2.3 Korelační matice kandidátních prediktorů
```r
library(corrplot)
cor_matrix <- cor(st_drop_geometry(data[, prediktory]), use = "complete.obs")
corrplot(cor_matrix, method = "color", type = "lower", tl.cex = 0.7)
```
- Identifikovat páry s |r| > 0.7 → kandidáti na odstranění

#### 2.4 Scatterploty Y vs. klíčové prediktory
```r
pairs(data[, c("pirati_pct", "podil_vs", "podil_mladi", "podil_najem")])
```

---

### FÁZE 3: Neprostorový regresní model (R)

#### 3.1 Teoretická úvaha — výběr kandidátních prediktorů

Piráti = liberální, městská, vzdělaná, mladá voličská základna. Kandidátní prediktory:

| Prediktor           | Očekávaný směr | Zdůvodnění                                |
|---------------------|----------------|-------------------------------------------|
| podíl VŠ            | +              | Vzdělání koreluje s liberálními hodnotami |
| podíl 18–34 let     | +              | Mladí voliči = jádro elektorátu Pirátů    |
| podíl nájemního byd.| +              | Proxy pro urbanizaci a mobilitu           |
| podíl OSVČ          | +/-            | Podnikatelé/freelanceri vs. stabilní zam. |
| míra nezaměstnanosti| -              | Vyšší nezam. → protest. volba (ANO, SPD)  |
| podíl v terciéru    | +              | Služby, IT, kreativní průmysl             |
| podíl cizinců       | +              | Kosmopolitní prostředí                    |
| hustota obyvatel    | +              | Urbanizace                                |
| podíl 65+           | -              | Starší voliči preferují jiné strany       |
| podíl bez vyznání   | +              | Sekularizace → liberální hodnoty          |

#### 3.2 Pravidla výběru proměnných (dokumentace procesu)

1. **Teorie** — zařadit jen proměnné, které mají teoretické zdůvodnění
2. **Korelace s Y** — vyřadit proměnné s |r| < 0.1 (slabý vztah)
3. **Multikolinearita** — korelační matice (|r| > 0.7 mezi prediktory → odstranit jeden)
4. **VIF** — po fitování modelu: VIF > 7.5 → zvážit odstranění, VIF > 10 → nutně odstranit
5. **Statistická významnost** — postupné odstraňování nevýznamných (p > 0.05)
6. **Interpretovatelnost** — zůstat u proměnných, které lze vysvětlit v kontextu voleb
7. **Stabilita** — metoda: backward stepwise + kontrola AIC

#### 3.3 Sestavení modelu
```r
# Plný model se všemi kandidátními prediktory
model_full <- lm(pirati_pct ~ podil_vs + podil_mladi + podil_65plus +
                   podil_najem + hustota + mira_nezam + podil_tercier +
                   podil_cizincu + podil_osvc + podil_bez_vyznani,
                 data = data)
summary(model_full)

# VIF
library(car)
vif(model_full)

# Backward stepwise
model_step <- step(model_full, direction = "backward")
summary(model_step)
```

#### 3.4 Diagnostika neprostorového modelu

```r
# R² a Adjusted R²
summary(model_step)$r.squared
summary(model_step)$adj.r.squared

# VIF finálního modelu
vif(model_step)

# Normalita reziduí
shapiro.test(residuals(model_step))  # pozor: nefunguje pro n > 5000
library(nortest)
lillie.test(residuals(model_step))   # Lilliefors (Kolmogorov-Smirnov)
qqnorm(residuals(model_step)); qqline(residuals(model_step))

# Heteroskedasticita
library(lmtest)
bptest(model_step)  # Breusch-Pagan test

# Mapa reziduí
data$residuals_ols <- residuals(model_step)
tm_shape(data) + tm_fill("residuals_ols", style = "jenks", midpoint = 0, palette = "RdBu")
```

#### 3.5 Test autokorelace reziduí (klíčový krok)
```r
library(spdep)

# Vytvoření matice sousednosti
nb <- poly2nb(data, queen = TRUE)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

# Moran's I test reziduí
moran.test(data$residuals_ols, lw, zero.policy = TRUE)

# Moran's I Monte Carlo test (robustnější)
moran.mc(data$residuals_ols, lw, nsim = 999, zero.policy = TRUE)

# Moran scatter plot
moran.plot(data$residuals_ols, lw, zero.policy = TRUE)
```

**Očekávaný výsledek**: Statisticky významná pozitivní prostorová autokorelace reziduí → model zanedbává prostorovou strukturu → zdůvodnění pro GWR.

---

### FÁZE 4: GWR model (R — balíček GWmodel)

#### 4.1 Příprava dat pro GWR
```r
library(GWmodel)
library(sp)

# GWmodel vyžaduje Spatial*DataFrame (sp), ne sf
data_sp <- as(data, "Spatial")

# Definice souřadnic (GWR potřebuje bodová data → centroidy)
coords <- coordinates(data_sp)

# Matice vzdáleností
dMat <- gw.dist(dp.locat = coords)
```

#### 4.2 Výběr bandwidth

```r
# Adaptive kernel (počet sousedů) — doporučeno pro nerovnoměrně rozložené obce
bw_adaptive <- bw.gwr(pirati_pct ~ podil_vs + podil_mladi + podil_najem +
                         hustota + mira_nezam,
                       data = data_sp,
                       approach = "AICc",      # optimalizace přes AICc
                       kernel = "bisquare",    # typ kernelu
                       adaptive = TRUE,        # adaptive = počet sousedů
                       dMat = dMat)

# Fixed kernel (pevná vzdálenost v metrech)
bw_fixed <- bw.gwr(pirati_pct ~ podil_vs + podil_mladi + podil_najem +
                      hustota + mira_nezam,
                    data = data_sp,
                    approach = "AICc",
                    kernel = "bisquare",
                    adaptive = FALSE,
                    dMat = dMat)
```

#### 4.3 Porovnání kernelů

Testovat kombinace:
- **adaptive** vs. **fixed**
- **bisquare** vs. **gaussian** vs. **exponential**
- Optimalizace: **AICc** (doporučeno) vs. **CV** (cross-validation)

```r
# Tabulka porovnání
kernels <- c("gaussian", "bisquare", "exponential")
results <- data.frame()

for (k in kernels) {
  bw <- bw.gwr(formula, data = data_sp, approach = "AICc",
                kernel = k, adaptive = TRUE, dMat = dMat)
  gwr <- gwr.basic(formula, data = data_sp, bw = bw,
                    kernel = k, adaptive = TRUE, dMat = dMat)
  results <- rbind(results, data.frame(
    kernel = k, bandwidth = bw,
    AICc = gwr$GW.diagnostic$AICc,
    R2 = gwr$GW.diagnostic$gw.R2,
    adjR2 = gwr$GW.diagnostic$gwR2.adj
  ))
}
print(results)
```

**Doporučení**: bisquare + adaptive je nejběžnější a nejrobustnější volba.

#### 4.4 Fitování GWR modelu

```r
gwr_model <- gwr.basic(
  pirati_pct ~ podil_vs + podil_mladi + podil_najem + hustota + mira_nezam,
  data = data_sp,
  bw = bw_adaptive,
  kernel = "bisquare",
  adaptive = TRUE,
  dMat = dMat
)

# Diagnostika
print(gwr_model)
# Zobrazí: AICc, R², adj. R², bandwidth, ...
```

#### 4.5 Extrakce výsledků

```r
# GWR výsledky jsou v SpatialDataFrame
gwr_results <- as.data.frame(gwr_model$SDF)
data$local_R2 <- gwr_results$Local_R2

# Lokální koeficienty pro 3 nejvýznamnější prediktory
data$coef_podil_vs <- gwr_results$podil_vs
data$coef_podil_mladi <- gwr_results$podil_mladi
data$coef_podil_najem <- gwr_results$podil_najem
```

#### 4.6 Porovnání OLS vs. GWR

| Metrika         | OLS         | GWR          |
|-----------------|-------------|--------------|
| AICc            | `AIC(model_step)` | `gwr_model$GW.diagnostic$AICc` |
| R²              | hodnota     | hodnota      |
| Adj. R²         | hodnota     | hodnota      |
| Moran's I rezid.| hodnota (sig.) | hodnota (sig.) |

```r
# Moran's I reziduí GWR
data$residuals_gwr <- gwr_results$residual
moran.test(data$residuals_gwr, lw, zero.policy = TRUE)
```

**Klíčové**: Moran's I by se měl snížit (blíže k nule) → GWR zachytil prostorovou nestacionaritu.

---

### FÁZE 5: Vizualizace a export (R + ArcGIS Pro)

#### 5.1 Export do GPKG pro ArcGIS Pro
```r
# Export kompletních výsledků
st_write(data, "data/processed/pirati_gwr_results.gpkg",
         layer = "gwr_results", delete_layer = TRUE)
```

#### 5.2 Mapy v R (tmap) — pracovní verze
```r
# Mapa volebního úspěchu
m1 <- tm_shape(data) +
  tm_fill("pirati_pct", style = "quantile", n = 7,
          palette = "YlOrRd", title = "Piráti (%)") +
  tm_borders(alpha = 0.1) + tm_layout(title = "Volební úspěch Pirátů 2025")

# Mapa lokálního R²
m2 <- tm_shape(data) +
  tm_fill("local_R2", style = "quantile", palette = "Greens",
          title = "Lokální R²") +
  tm_borders(alpha = 0.1)

# Mapy lokálních koeficientů (3 nejvýznamnější)
m3 <- tm_shape(data) +
  tm_fill("coef_podil_vs", style = "jenks", midpoint = 0,
          palette = "RdBu", title = "Koeficient: podíl VŠ") +
  tm_borders(alpha = 0.1)

# Mapa reziduí OLS
m4 <- tm_shape(data) +
  tm_fill("residuals_ols", style = "jenks", midpoint = 0,
          palette = "RdBu", title = "Rezidua OLS") +
  tm_borders(alpha = 0.1)
```

#### 5.3 Finální mapy v ArcGIS Pro
Importovat `data/processed/pirati_gwr_results.gpkg` do ArcGIS Pro a vytvořit:
1. Layout mapy volebního úspěchu
2. Layout lokálního R²
3. Layout 3 lokálních koeficientů (multi-map layout nebo 3 samostatné)
4. Volitelně: mapa reziduí OLS + GWR vedle sebe

---

### FÁZE 6: Prezentace

#### Osnova prezentace (10 minut)

| # | Slide                              | Čas   | Obsah                                         |
|---|------------------------------------|-------|-----------------------------------------------|
| 1 | Titulní slide                      | 0:00  | Název, autoři, datum                          |
| 2 | Česká pirátská strana              | 0:30  | Ideologie, cílová skupina, založení 2009      |
| 3 | Volební historie                   | 1:30  | Tabulka/graf výsledků 2013–2025               |
| 4 | Mapa volebního úspěchu 2025       | 2:30  | Choropleth mapa                               |
| 5 | Data a metodika                    | 3:30  | Zdroje dat, výběr proměnných, pracovní postup |
| 6 | Neprostorový model (OLS)           | 4:30  | Koeficienty, R², VIF, významné prediktory     |
| 7 | Diagnostika OLS                    | 5:30  | Normalita, heterosked., Moran's I, mapa rezid.|
| 8 | GWR — nastavení                    | 6:30  | Kernel, bandwidth, porovnání AICc             |
| 9 | GWR — výsledky                     | 7:30  | Lokální R², tabulka OLS vs. GWR               |
| 10| Lokální koeficienty (3 mapy)       | 8:30  | Interpretace prostorových vzorců              |
| 11| Závěr                              | 9:30  | Shrnutí, limity, zjištění                     |

---

## B) Seznam balíčků v R

| Balíček     | Účel                                              |
|-------------|---------------------------------------------------|
| `sf`        | Načtení GPKG, prostorové operace, export          |
| `sp`        | Konverze pro GWmodel (vyžaduje Spatial*)           |
| `spdep`     | Matice sousednosti, Moran's I                     |
| `GWmodel`   | GWR: bw.gwr, gwr.basic                            |
| `car`       | VIF (vif())                                        |
| `lmtest`    | Breusch-Pagan test (bptest())                      |
| `nortest`   | Lilliefors test normality                          |
| `corrplot`  | Korelační matice vizualizace                       |
| `tmap`      | Tematické mapy (choropleth)                        |
| `dplyr`     | Manipulace s daty                                  |
| `readr`     | Načtení CSV (SLDB data)                            |
| `ggplot2`   | Grafy (histogramy, scatterploty)                   |
| `tidyr`     | Pivotování dat                                     |

Instalace:
```r
install.packages(c("sf", "sp", "spdep", "GWmodel", "car", "lmtest",
                    "nortest", "corrplot", "tmap", "dplyr", "readr",
                    "ggplot2", "tidyr"))
```

---

## C) Struktura projektu

```
Pogeo2026/
├── data/
│   ├── raw/                          # Originální data (neupravovat)
│   │   ├── csu_geodb_sde_...gpkg     # Volební data
│   │   ├── sldb_obce.csv             # Census data (stáhnout z ČSÚ)
│   │   └── doplnkova_data.csv        # Mzdy, internet, ...
│   └── processed/
│       └── pirati_gwr_results.gpkg   # Výsledky pro ArcGIS Pro
├── R/
│   └── 01_gwr_analyza.R             # Hlavní analytický skript
├── output/
│   ├── figures/                      # PNG/PDF grafy z R
│   ├── tables/                       # CSV tabulky výsledků
│   └── maps/                         # Mapy z R (pracovní verze)
├── arcgis/                           # ArcGIS Pro projekt
├── prezentace/                       # PPTX
├── zadani_volby.html                 # Zadání
└── WORKFLOW.md                       # Tento soubor
```

---

## D) Kostra R skriptu

Viz soubor `R/01_gwr_analyza.R`

---

## E) Seznam finálních výstupů

### Mapy (ArcGIS Pro — finální layout)
1. **Mapa volebního úspěchu Pirátů 2025** — choropleth, kvantily, 7 tříd
2. **Mapa reziduí OLS** — divergentní paleta, střed v nule
3. **Mapa lokálního R² (GWR)** — sekvenční paleta (zelená)
4. **Mapa lokálního koeficientu #1** (např. podíl VŠ) — divergentní
5. **Mapa lokálního koeficientu #2** (např. podíl mladých) — divergentní
6. **Mapa lokálního koeficientu #3** (např. hustota) — divergentní

### Grafy (R → PNG/PDF)
1. **Histogram** závislé proměnné
2. **Korelační matice** kandidátních prediktorů (corrplot)
3. **Q-Q plot** reziduí OLS
4. **Moran scatter plot** reziduí OLS
5. **Sloupcový graf** VIF hodnot
6. **Box plot / violin plot** lokálních koeficientů GWR vs. globální OLS

### Tabulky
1. **Tabulka volební historie** Pirátů (2013, 2017, 2021, 2025)
2. **Korelační matice** (numerická) + rozhodnutí o vyřazení
3. **Souhrn OLS modelu** — koeficienty, p-hodnoty, VIF
4. **Diagnostika OLS** — R², Shapiro/Lilliefors, BP test, Moran's I
5. **Porovnání kernelů/bandwidth** GWR
6. **Porovnání OLS vs. GWR** — AICc, R², Moran's I reziduí

---

## F) Metodická rizika a časté chyby

### 1. Ekologický klam (ecological fallacy)
- Data jsou za obce, ne za jednotlivce
- **Nikdy** neinterpretovat jako: "vzdělaní lidé volí Piráty"
- Správně: "v obcích s vyšším podílem VŠ vzdělaných je vyšší podpora Pirátů"

### 2. MAUP (Modifiable Areal Unit Problem)
- Výsledky závisí na zvoleném měřítku (obce vs. ORP vs. okresy)
- Zmínit v prezentaci jako limit

### 3. Multikolinearita v GWR
- GWR je citlivější na multikolinearitu než OLS
- Pokud condition number > 30 v některých lokalitách → problém
- Řešení: odstranit korelované prediktory, snížit počet proměnných
- `gwr.basic()` vrací lokální condition numbers → zkontrolovat

### 4. Malé obce
- Obec s 20 voliči: 1 hlas = 5% → extrémní variabilita
- Řešení: filtrovat obce pod 50–100 voličů, nebo vážit počtem voličů

### 5. Nestabilní podíly
- Nízký základ (málo obyvatel v kategorii) → nestabilní procenta
- Platí i pro prediktory ze SLDB

### 6. Volba bandwidth
- Příliš malá → overfitting (lokální šum)
- Příliš velká → blíží se OLS (ztráta lokální informace)
- Vždy používat AICc nebo CV, neodhadovat ručně

### 7. Interpretace lokálních koeficientů
- Záporný koeficient ≠ "proměnná škodí"
- Záporný koeficient = "v této lokalitě je vztah záporný"
- Porovnat s mapou samotného prediktoru pro kontext

### 8. CRS a vzdálenosti
- GWR počítá vzdálenosti → musí být v metrickém CRS (S-JTSK, ne WGS84)
- Pokud data v WGS84 → `st_transform(data, 5514)`

### 9. Normalita reziduí
- Shapiro-Wilk nefunguje pro n > 5000 (vždy zamítne)
- Použít Lilliefors test nebo vizuální kontrolu (Q-Q plot)
- U 6258 obcí bude test skoro vždy signifikantní → Q-Q plot je důležitější

### 10. Prostorová sousednost
- Některé obce nemají sousedy (ostrovy v poly2nb)
- `zero.policy = TRUE` řeší, ale zkontrolovat, zda nejde o chybu dat
