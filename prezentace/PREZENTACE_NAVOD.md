# PREZENTACE — Kompletní návod (10 minut)

## STRUKTURA: 11 slidů

---

## SLIDE 1: TITULNÍ (15 sekund)

### Na slide:
```
ANALÝZA VOLEBNÍHO ÚSPĚCHU PIRÁTSKÉ STRANY
Parlamentní volby 2025

Geographically Weighted Regression (GWR)

[Vaše jméno]
POGEO | Duben 2026
```

### Co říct:
> "Dobrý den, představím vám analýzu volebního úspěchu Pirátské strany 
> ve volbách do Poslanecké sněmovny 2025 s využitím geograficky vážené regrese."

---

## SLIDE 2: O PIRÁTSKÉ STRANĚ (1 minuta)

### Na slide:
**Česká pirátská strana**
- Založena: 2009
- Ideologie: liberalismus, transparentnost, digitální práva
- Cílová skupina: mladí, vzdělaní, městští voliči

**Klíčové body programu:**
- Digitalizace státní správy
- Boj proti korupci
- Liberální společenská politika

### Obrázek:
Logo Pirátů (stáhni z pirati.cz)

### Co říct:
> "Česká pirátská strana vznikla v roce 2009 jako součást mezinárodního 
> pirátského hnutí. Zaměřuje se na transparentnost, digitalizaci a liberální 
> hodnoty. Jejich voličská základna jsou typicky mladí, vzdělaní lidé 
> ve velkých městech — což uvidíme i v našich datech."

---

## SLIDE 3: VOLEBNÍ HISTORIE (1 minuta)

### Na slide — TABULKA:

| Volby | Výsledek | Poznámka |
|-------|----------|----------|
| 2013 | 2.66% | Nepřekročili 5% práh |
| 2017 | 10.79% | 22 mandátů — průlom |
| 2021 | ~15% | Koalice PirSTAN |
| 2025 | **8.97%** | Sami, 18 mandátů |

### Co říct:
> "Piráti zažili vzestup mezi 2017 a 2021, kdy v koalici se STAN získali 
> přes 15 procent. V roce 2025 kandidovali samostatně a získali necelých 
> 9 procent — 18 poslanců. Právě tyto volby 2025 analyzujeme."

---

## SLIDE 4: MAPA VOLEBNÍHO ÚSPĚCHU (1 minuta)

### Na slide:
**Obrázek:** `output/maps/01_mapa_pirati_uspech.png`

**Textbox (vpravo dole):**
- Praha: 16.8%
- Brno: 14.2%  
- Průměr obcí: 6.8%

### Co říct:
> "Mapa ukazuje prostorové rozložení volebního úspěchu. Vidíme jasný 
> metropolitní vzorec — Praha má skoro 17 procent, Brno přes 14. 
> Naopak venkovské oblasti, zejména severní Morava a příhraničí, 
> mají výrazně nižší podporu. Průměr za všechny obce je necelých 7 procent."

---

## SLIDE 5: DATA A METODIKA (1 minuta)

### Na slide:
**Zdroje dat:**
- Volební data: ČSÚ (PSP 2025)
- Prediktory: SLDB 2021

**Dataset:**
- n = 6 157 obcí
- Závislá proměnná: podíl hlasů pro Piráty (%)

**6 prediktorů:**
| Prediktor | Očekávaný směr |
|-----------|----------------|
| VŠ vzdělání | + |
| Vyučení bez maturity | − |
| Neprac. důchodci | − |
| Podnikatelé | + |
| Nezaměstnanost | − |
| Věřící | − |

### Co říct:
> "Analyzujeme 6157 obcí. Data o volbách jsou z ČSÚ, prediktory pochází 
> ze Sčítání lidu 2021. Vybrali jsme 6 prediktorů, které pokrývají vzdělání, 
> ekonomickou aktivitu a hodnotovou orientaci. U každého máme hypotézu 
> o směru vztahu — například očekáváme, že vyšší vzdělání zvyšuje 
> pravděpodobnost volby Pirátů."

---

## SLIDE 6: OLS MODEL — VÝSLEDKY (1 minuta)

### Na slide:
**Obrázek:** `output/figures/12_ols_forest_plot.png`

**Nebo tabulka:**
| Prediktor | Koeficient | p-hodnota |
|-----------|------------|-----------|
| VŠ vzdělání | +0.112 | *** |
| Vyučení | −0.079 | *** |
| Důchodci | −0.022 | ** |
| Podnikatelé | +0.071 | *** |
| Nezaměstnanost | −0.037 | ** |
| Věřící | −0.020 | *** |

**R² = 18.8%**

### Co říct:
> "Nejprve jsme sestavili klasický OLS model. Všechny prediktory jsou 
> statisticky významné a mají očekávaný směr. Nejsilnější efekt má 
> VŠ vzdělání — nárůst o 1 procentní bod zvyšuje podporu Pirátů o 0.11 bodu.
> 
> ALE — model vysvětluje jen 19 procent variability. To je málo. 
> Nabízí se otázka: je vztah všude stejný, nebo se liší regionálně?"

---

## SLIDE 7: DIAGNOSTIKA — PROSTOROVÁ AUTOKORELACE (1 minuta)

### Na slide:
**Obrázek:** `output/figures/08_moran_scatterplot_ols.png`
NEBO `output/maps/02_mapa_rezidua_ols.png`

**Výsledek Moran's I testu:**
- I = 0.080
- p = 0.001 ***
- → Statisticky významná autokorelace

### Co říct:
> "Testovali jsme prostorovou autokorelaci reziduí pomocí Moranova I.
> Hodnota 0.08 s p-hodnotou 0.001 znamená, že rezidua NEJSOU náhodně 
> rozmístěna — sousední obce mají podobné chyby předpovědi.
> 
> To indikuje prostorovou nestacionaritu — vztahy mezi prediktory 
> a závislou proměnnou se liší v různých částech republiky. 
> Proto přecházíme na GWR."

---

## SLIDE 8: GWR — NASTAVENÍ A POROVNÁNÍ (1 minuta)

### Na slide:
**Porovnání kernelů:**
| Kernel | Bandwidth | AICc | R² |
|--------|-----------|------|-----|
| Bisquare | 270 | 28777 | 0.334 |
| Gaussian | 44 | 28742 | 0.347 |
| **Exponential** | **23** | **28601** | **0.445** |

**Vybraný model:** Exponential, BW = 23 sousedů

**Srovnání OLS vs GWR:**
| | OLS | GWR |
|---|---|---|
| R² | 0.188 | 0.445 |
| Adj. R² | 0.188 | 0.300 |
| Moran's I | 0.080*** | −0.002 (ns) |

### Co říct:
> "Testovali jsme tři typy kernelů. Nejlepší výsledky má exponenciální 
> kernel s adaptivní šířkou 23 sousedů.
> 
> GWR výrazně zlepšuje model — R² roste z 19 na 44 procent, 
> adjusted R² z 19 na 30. A hlavně — Moran's I klesá prakticky na nulu, 
> autokorelace je eliminována."

---

## SLIDE 9: LOKÁLNÍ R² (1 minuta)

### Na slide:
**Obrázek:** `output/maps/03_mapa_local_R2.png`

**Statistiky:**
- Min: 0.24
- Max: 0.84
- Průměr: 0.43

### Co říct:
> "Mapa lokálního R² ukazuje, kde model funguje lépe a kde hůře.
> 
> Tmavé oblasti — Praha, Brno, západní Čechy — tam model vysvětluje 
> až 80 procent variability. Model tam dobře zachycuje vztahy.
> 
> Světlejší oblasti ve středních Čechách a na Vysočině mají nižší R² 
> kolem 25-30 procent — tam pravděpodobně působí faktory, které 
> v modelu nemáme."

---

## SLIDE 10: LOKÁLNÍ KOEFICIENTY (1.5 minuty)

### Na slide:
**3 mapy vedle sebe** (nebo pod sebou):
- `output/maps/04_coef_VZDELANI_VYSOKO.png`
- `output/maps/05_coef_VZDELANI_STR_BEZ.png`  
- `output/maps/06_coef_PODNIKATELE.png`

**Tabulka srovnání:**
| Prediktor | Globální OLS | Lokální rozsah |
|-----------|--------------|----------------|
| VŠ vzdělání | +0.112 | −0.21 až +0.43 |
| Vyučení | −0.079 | −0.19 až +0.11 |
| Podnikatelé | +0.071 | −0.12 až +0.27 |

### Co říct:
> "Tady je KLÍČOVÉ zjištění. Podívejte se na mapu VŠ vzdělání.
> 
> Globální OLS říká: 'VŠ vzdělání má pozitivní efekt plus 0.11'.
> Ale lokální koeficienty se pohybují od MÍNUS 0.21 do PLUS 0.43!
> 
> Růžové oblasti — střední Čechy, okolí Prahy, sever — tam je efekt 
> ZÁPORNÝ. VŠ vzdělaní tam volí jiné strany, asi SPOLU nebo TOP09.
> 
> Zelené oblasti — menší města na jihozápadě — tam je efekt SILNĚ pozitivní.
> 
> Tohle by OLS nikdy neodhalil. GWR ukazuje, že vztahy nejsou univerzální."

---

## SLIDE 11: ZÁVĚR (30 sekund)

### Na slide:
**Hlavní zjištění:**
1. ✓ GWR výrazně zlepšuje fit (R² +26 p.p.)
2. ✓ Prostorová autokorelace eliminována
3. ✓ Vztahy mezi prediktory a volbou se regionálně liší
4. ✓ Piráti = metropolitní fenomén, ale ne uniformně

**Limity:**
- Ekologický klam (data za obce, ne jednotlivce)
- Malý bandwidth (23 sousedů = velmi lokální)

**Závěrečná věta:**
> "Volební chování není všude stejné — GWR to dokáže zachytit."

### Co říct:
> "Shrnutí: GWR výrazně zlepšuje model oproti OLS a eliminuje 
> prostorovou autokorelaci. Hlavní zjištění je, že vztahy mezi 
> sociodemografickými charakteristikami a volbou Pirátů se regionálně liší.
> 
> Je třeba zmínit limity — pracujeme s agregovanými daty za obce, 
> nemůžeme dělat závěry o jednotlivcích.
> 
> Děkuji za pozornost."

---

## SOUBORY K POUŽITÍ

| Slide | Soubor |
|-------|--------|
| 4 | `output/maps/01_mapa_pirati_uspech.png` |
| 6 | `output/figures/12_ols_forest_plot.png` |
| 7 | `output/figures/08_moran_scatterplot_ols.png` nebo `output/maps/02_mapa_rezidua_ols.png` |
| 9 | `output/maps/03_mapa_local_R2.png` |
| 10 | `output/maps/04_coef_VZDELANI_VYSOKO.png` |
| 10 | `output/maps/05_coef_VZDELANI_STR_BEZ.png` |
| 10 | `output/maps/06_coef_PODNIKATELE.png` |

---

## TIPY PRO PREZENTOVÁNÍ

1. **Nečti ze slidu** — slidy mají být stručné, ty vysvětluješ
2. **Ukazuj na mapách** — "tady vidíme...", "tato oblast..."
3. **Zdůrazni překvapení** — záporné koeficienty jsou WOW moment
4. **Čísla zaokrouhluj** — říkej "19 procent", ne "18.84 procent"
5. **Čas** — 10 minut = ~1 minuta na slide, neklikej rychle

---

## MOŽNÉ OTÁZKY A ODPOVĚDI

**Q: Proč tak malý bandwidth (23)?**
> "Optimalizace AICc vybrala tento bandwidth jako nejlepší kompromis 
> mezi bias a variance. Exponenciální kernel navíc váhy snižuje postupně, 
> takže i vzdálenější obce mají malý vliv."

**Q: Proč je někde koeficient záporný?**
> "To je klíčový výsledek GWR — ukazuje prostorovou heterogenitu. 
> V těch oblastech VŠ vzdělaní pravděpodobně preferují jiné strany, 
> typicky pravicové jako SPOLU nebo TOP09."

**Q: Co je ekologický klam?**
> "Nelze vztahy zjištěné na úrovni obcí interpretovat jako vztahy 
> platné pro jednotlivce. Například když obec s více VŠ vzdělanými 
> volí více Piráty, neznamená to, že VŠ vzdělaní volí Piráty — 
> mohou to být jiní lidé v té obci."

**Q: Proč OLS má tak nízké R²?**
> "Volební chování je komplexní jev ovlivněný mnoha faktory — 
> kampaň, mediální obraz, lokální kandidáti, historické tradice. 
> Sociodemografické proměnné vysvětlují jen část."
