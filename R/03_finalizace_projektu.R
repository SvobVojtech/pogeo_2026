# =============================================================================
# 03_finalizace_projektu.R
# Finální kompletace projektu — Analýza volebního úspěchu Pirátů (PSP 2025)
# =============================================================================
# Předpoklad: objekty 'data', 'model_ols', 'prediktory' jsou v paměti
#             (po spuštění 01_gwr_analyza.R a kroku GWR)
# =============================================================================

library(sf)
library(ggplot2)
library(dplyr)
library(tmap)

# =============================================================================
# A) KONTROLA EXISTENCE OBJEKTŮ
# =============================================================================
cat("=== KONTROLA OBJEKTŮ ===\n")

stopifnot("Objekt 'data' neexistuje — spusť nejdřív 01_gwr_analyza.R" =
            exists("data"))
stopifnot("Objekt 'model_ols' neexistuje — spusť nejdřív 01_gwr_analyza.R" =
            exists("model_ols"))
stopifnot("Objekt 'prediktory' neexistuje — spusť nejdřív 01_gwr_analyza.R" =
            exists("prediktory"))

# Kontrola požadovaných sloupců
required_cols <- c("kod_obce", "nazev_obce", "pirati_pct",
                   "fitted_ols", "resid_ols", "resid_gwr",
                   "local_R2", "coef_VZDELANI_VYSOKO",
                   "coef_VZDELANI_STR_BEZ", "coef_PODNIKATELE")
missing_cols <- setdiff(required_cols, names(data))
if (length(missing_cols) > 0) {
  stop("Chybí sloupce: ", paste(missing_cols, collapse = ", "))
}
cat("OK: všechny požadované objekty a sloupce existují\n")
cat("    n =", nrow(data), "obcí\n")
cat("    CRS: EPSG", st_crs(data)$epsg, "\n")

# Vytvoření adresáře pro processed data (pokud neexistuje)
if (!dir.exists("data/processed")) dir.create("data/processed", recursive = TRUE)

# =============================================================================
# B) FINÁLNÍ GPKG EXPORT
# =============================================================================
cat("\n=== B) EXPORT GPKG ===\n")

export_cols <- c(required_cols, prediktory)

# sf zachová geometrii automaticky při subsettingu přes sloupce
data_export <- data[, export_cols]

st_write(data_export,
         dsn          = "data/processed/pirati_final.gpkg",
         layer        = "gwr_final",
         delete_layer = TRUE,
         quiet        = FALSE)

cat("✓ data/processed/pirati_final.gpkg — vrstva 'gwr_final'\n")
cat("  Sloupce:", paste(export_cols, collapse = ", "), "\n")

# =============================================================================
# C) FINÁLNÍ CSV TABULKY
# =============================================================================
cat("\n=== C) CSV TABULKY ===\n")

# --- C1: model_summary.csv ---
model_summary <- data.frame(
  metrika    = c("R2", "adj_R2", "AICc", "Moran_I_rezidua", "Moran_p_value",
                 "RSS", "eff_parameters", "n_observations"),
  OLS        = c(0.1884, 0.1877, 29130.33, 0.0800, 0.001,
                 40787.03, 7, 6157),
  GWR        = c(0.4447, 0.2999, 28601.14, -0.0017, 0.574,
                 27910.42, 1272.81, 6157),
  GWR_lepsi  = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, NA, NA),
  poznamka   = c(
    "GWR: +25.6 p.p.",
    "GWR: +11.2 p.p.; penalizace za složitost",
    "Srovnatelné (oba AICc); snížení o 529",
    "OLS: průkazná; GWR: eliminována",
    "OLS: p=0.001***; GWR: p=0.574 (ns)",
    "Snížení RSS o 31.6 %",
    "OLS: 7 (1 intercept + 6); GWR: 1272.8 efektivních",
    "Po filtraci (vojenskeújezdy + obce <50 voličů)"
  )
)
write.csv(model_summary, "output/tables/07_model_summary.csv", row.names = FALSE)
cat("✓ output/tables/07_model_summary.csv\n")

# --- C2: map_variables_overview.csv ---
map_vars <- data.frame(
  variable = c("pirati_pct", "resid_ols", "local_R2",
               "coef_VZDELANI_VYSOKO", "coef_VZDELANI_STR_BEZ",
               "coef_PODNIKATELE"),
  description_cz = c(
    "Podíl hlasů Pirátů (% z platných)",
    "Rezidua OLS modelu",
    "Lokální R² GWR modelu",
    "Lok. koef. — podíl VŠ vzdělaných",
    "Lok. koef. — vyučení bez maturity",
    "Lok. koef. — podnikatelé/OSVČ"
  ),
  map_type = c("choropleth", "choropleth_diverging", "choropleth",
               "choropleth_diverging", "choropleth_diverging",
               "choropleth_diverging"),
  recommended_classification = c(
    "Quantile, 7 tříd",
    "Quantile, 7 tříd",
    "Quantile, 7 tříd",
    "Jenks, 7 tříd",
    "Jenks, 7 tříd",
    "Jenks, 7 tříd"
  ),
  color_scheme = c(
    "YlOrRd (sekvenční)",
    "RdBu divergentní (červená=podhodnoceno, modrá=nadhodnoceno)",
    "BuPu nebo Greens (sekvenční)",
    "RdBu divergentní",
    "RdBu divergentní",
    "RdBu divergentní"
  ),
  midpoint = c(NA, 0, NA, 0, 0, 0),
  ols_global_coef = c(NA, NA, 0.1884, 0.1125, -0.0795, 0.0711),
  lok_median = c(NA, NA, 0.4055, 0.0891, -0.0749, 0.0447),
  lok_min = c(NA, NA, 0.2428, -0.2063, -0.3736, -0.1770),
  lok_max = c(NA, NA, 0.8380, 0.4263, 0.1671, 0.2369),
  interpretace = c(
    "Průměr obcí 6.77 %; max 24.11 %; silný urban bias (Praha 16.85 %)",
    "Průměr ~0; shluky pozit./negat. reziduí → zdůvodnění GWR",
    "Průměr 0.433; silnější vysvětlení v pohraničí a Praze",
    "Silnější efekt VŠ v Praze a větších městech; v části venkova záporný",
    "Efekt vyučení negativnější v průmyslových oblastech",
    "Efekt podnikatelů variabilní; silnější v turistických oblastech"
  )
)
write.csv(map_vars, "output/tables/08_map_variables_overview.csv",
          row.names = FALSE)
cat("✓ output/tables/08_map_variables_overview.csv\n")

# --- C3: project_checklist.csv ---
checklist <- data.frame(
  pozadavek = c(
    "Představení strany Piráti",
    "Volební výsledky v minulých volbách",
    "Mapa současného volebního úspěchu",
    "Neprostorový (OLS) model",
    "Výběr prediktorů — zdokumentování",
    "Využití dat ze SLDB",
    "Popis kvality OLS (R², testy)",
    "Test autokorelace reziduí (Moran's I)",
    "GWR model",
    "Testování kernelu a bandwidth",
    "Vizualizace lokálního R²",
    "Vizualizace 3 lokálních koeficientů",
    "Porovnání lokální vs globální hodnoty",
    "Ověření snížení nestacionarity",
    "GPKG export pro ArcGIS Pro",
    "Prezentace ~10 minut"
  ),
  status = c(
    "CHYBÍ", "CHYBÍ", "SPLNĚNO", "SPLNĚNO",
    "SPLNĚNO", "SPLNĚNO", "SPLNĚNO", "SPLNĚNO",
    "SPLNĚNO", "SPLNĚNO", "SPLNĚNO", "SPLNĚNO",
    "SPLNĚNO", "SPLNĚNO", "SPLNĚNO", "CHYBÍ"
  ),
  kde_v_projektu = c(
    "Pouze do prezentace — připravit samostatně",
    "Pouze do prezentace — připravit samostatně",
    "output/maps/01_mapa_pirati_uspech.png",
    "01_gwr_analyza.R Krok 3; output/tables/03_ols_koeficienty.csv",
    "01_gwr_analyza.R Krok 2; ANALYZA_POSTUP_FINAL.txt",
    "sldb2021_obce_indikatory.csv; 6 prediktorů v modelu",
    "R²=0.188, adj.R²=0.188, VIF<3, Q-Q plot; output/figures/05-07",
    "I=0.0800, p=0.001; output/figures/08; output/tables/04",
    "exponential kernel, BW=23, R²=0.445; output/tables/05",
    "3 kernely porovnány (bisquare/gaussian/exponential); output/tables/05",
    "output/maps/03_mapa_local_R2.png",
    "output/maps/04-06_coef_*.png",
    "output/figures/09_boxplot_gwr_vs_ols.png; output/tables/07",
    "Moran's I: OLS=0.08 → GWR=-0.002; output/tables/06",
    "data/processed/pirati_final.gpkg",
    "Obsah v ANALYZA_POSTUP_FINAL.txt; vizuály v output/"
  ),
  poznamka = c(
    "Ideologie, cílová skupina, 2009–2025 vývoj",
    "Tabulka: 2013 (2.66%), 2017 (10.79%), 2021 (Pirstan 15.62%), 2025 (8.97%)",
    "Vytvořena v 03_finalizace_projektu.R",
    "Všechny prediktory sig. p<0.05; VIF max 2.71",
    "Korelace s Y, kompoziční data, VIF, zpětná eliminace zdokumentovány",
    "SLDB 2021, 6 prediktorů ze 17 kandidátů",
    "R² nízké (18.8 %) — indikátor prostorové nestacionarity",
    "Střední I (0.08), ale statisticky průkazné → GWR zdůvodněno",
    "BW=23 adaptive exponential — nejnižší AICc ze 3 kernelů",
    "AICc: bisquare 28777 > gaussian 28742 > exponential 28601",
    "Průměr R²=0.433; max 0.838; min 0.243",
    "VZDELANI_VYSOKO, VZDELANI_STR_BEZ, PODNIKATELE (dle |t| z OLS)",
    "Globální OLS koef. jako referenční bod v boxplotu",
    "OLS I=0.080 (p=0.001) → GWR I=-0.002 (p=0.574)",
    "Vrstva 'gwr_final' v GPKG",
    "~10 min dle osnovy v ANALYZA_POSTUP_FINAL.txt"
  )
)
write.csv(checklist, "output/tables/09_project_checklist.csv",
          row.names = FALSE)
cat("✓ output/tables/09_project_checklist.csv\n")

# =============================================================================
# D) CHYBĚJÍCÍ VIZUALIZACE (z 02_vizualizace.R)
# =============================================================================
cat("\n=== D) CHYBĚJÍCÍ VIZUALIZACE ===\n")

tmap_mode("plot")

# --- Mapa 1: Volební úspěch Pirátů (CHYBĚLA) ---
m_pirati <- tm_shape(data) +
  tm_polygons(
    fill        = "pirati_pct",
    fill.scale  = tm_scale_intervals(
      style  = "quantile", n = 7, values = "YlOrRd"
    ),
    fill.legend = tm_legend(
      title    = "Podíl hlasů (%)",
      position = tm_pos_in("right", "bottom")
    ),
    col = NA, col_alpha = 0
  ) +
  tm_title("Volební úspěch Pirátů — PSP ČR 2025",
           position = tm_pos_in("left", "top"), size = 1.1) +
  tm_compass(position = tm_pos_in("right", "top"), size = 1.5) +
  tm_scalebar(breaks = c(0, 50, 100),
              position = tm_pos_in("left", "bottom"), text.size = 0.6) +
  tm_credits("Zdroj: ČSÚ (GPKG volby 2025) | n = 6 157 obcí",
             position = tm_pos_in("left", "bottom"), size = 0.55)
tmap_save(m_pirati, "output/maps/01_mapa_pirati_uspech.png",
          width = 12, height = 8, dpi = 300)
cat("✓ output/maps/01_mapa_pirati_uspech.png\n")

# --- Figure 10: OLS vs GWR srovnání (4 metriky) ---
library(tidyr)
comp_df <- data.frame(
  Metrika = c("R²", "Adjusted R²", "AICc", "Moran's I reziduí"),
  OLS     = c(0.1884,  0.1877, 29130.33,  0.0800),
  GWR     = c(0.4447,  0.2999, 28601.14, -0.0017)
)
comp_long <- pivot_longer(comp_df, c(OLS, GWR),
                          names_to = "Model", values_to = "Hodnota")

p10 <- ggplot(comp_long, aes(x = Model, y = Hodnota, fill = Model)) +
  geom_col(width = 0.55) +
  geom_text(aes(label = round(Hodnota, 3)),
            vjust = ifelse(comp_long$Hodnota >= 0, -0.4, 1.3),
            size = 3.5, fontface = "bold") +
  facet_wrap(~Metrika, scales = "free_y", ncol = 2) +
  scale_fill_manual(values = c("OLS" = "#b2b2b2", "GWR" = "#2b8cbe")) +
  labs(title    = "OLS vs. GWR — srovnání modelů",
       subtitle = "Kernel: exponential | Adaptive BW = 23 | Optimalizace: AICc",
       x = NULL, y = "Hodnota", fill = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top",
        strip.text = element_text(face = "bold"),
        plot.title = element_text(face = "bold"))
ggsave("output/figures/10_ols_vs_gwr_srovnani.png", p10,
       width = 9, height = 7, dpi = 300)
cat("✓ output/figures/10_ols_vs_gwr_srovnani.png\n")

# --- Figure 11: Moran's I eliminace ---
p11 <- ggplot(
  data.frame(Model = c("OLS rezidua", "GWR rezidua"),
             I     = c(0.0800, -0.0017),
             sig   = c("p = 0.001 ***", "p = 0.574 (ns)")),
  aes(x = Model, y = I, fill = I > 0)) +
  geom_col(width = 0.45) +
  geom_hline(yintercept = 0, linewidth = 0.7) +
  geom_text(aes(label = paste0("I = ", round(I, 4), "\n", sig)),
            vjust = c(-0.3, 1.3), size = 4, fontface = "bold") +
  scale_fill_manual(values = c("FALSE" = "#74a9cf", "TRUE" = "#e34a33"),
                    guide = "none") +
  scale_y_continuous(limits = c(-0.03, 0.13)) +
  labs(title    = "Prostorová autokorelace reziduí: OLS → GWR",
       subtitle = "GWR eliminovalo autokorelaci reziduí",
       x = NULL, y = "Moran's I") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))
ggsave("output/figures/11_moran_ols_vs_gwr.png", p11,
       width = 7, height = 5, dpi = 300)
cat("✓ output/figures/11_moran_ols_vs_gwr.png\n")

# --- Figure 12: Forest plot OLS koeficientů s CI ---
ols_ci <- as.data.frame(confint(model_ols))
ols_ci$prediktor <- rownames(ols_ci)
ols_ci$koef      <- coef(model_ols)
ols_ci           <- ols_ci[ols_ci$prediktor != "(Intercept)", ]
names(ols_ci)[1:2] <- c("low", "high")
ols_ci$label <- c("VŠ vzdělání", "Vyučení bez mat.",
                   "Neprac. důchodci", "Podnikatelé/OSVČ",
                   "Nezaměstnaní", "Věřící")

p12 <- ggplot(ols_ci, aes(x = reorder(label, koef), y = koef,
                            ymin = low, ymax = high, color = koef > 0)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(linewidth = 1, size = 0.8) +
  scale_color_manual(values = c("TRUE" = "#2166ac", "FALSE" = "#d73027"),
                     guide = "none") +
  coord_flip() +
  labs(title    = "OLS — koeficienty s 95% konfidenčními intervaly",
       subtitle = "Závislá proměnná: podíl hlasů Pirátů (%)",
       x = NULL, y = "Koeficient (p.p. Pirátů / 1 p.p. prediktoru)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))
ggsave("output/figures/12_ols_forest_plot.png", p12,
       width = 8, height = 5, dpi = 300)
cat("✓ output/figures/12_ols_forest_plot.png\n")

# =============================================================================
# E) ARCGIS PRO INSTRUKCE
# =============================================================================
cat("\n=== E) ARCGIS INSTRUKCE ===\n")

arcgis_txt <- '
ArcGIS Pro — Instrukce pro mapování výsledků GWR
=================================================
Soubor: data/processed/pirati_final.gpkg
Vrstva: gwr_final

--------------------------------------------------
1. IMPORT DAT
--------------------------------------------------
a) Otevřít ArcGIS Pro → nový projekt
b) Insert → Add Data → Add Data...
   Navigovat na: data/processed/pirati_final.gpkg
   Vybrat vrstvu: gwr_final
c) Data se načtou jako polygon vrstva (CRS: S-JTSK EPSG:5514)
   — nutno NEMĚNIT projekci, ponechat S-JTSK

--------------------------------------------------
2. NASTAVENÍ SYMBOLOGIE — OBECNÝ POSTUP
--------------------------------------------------
Right-click na vrstvě → Symbology
  Symbology type: Graduated Colors
  Field: [viz tabulka níže]
  Method: [viz tabulka níže]
  Classes: 7
  Color scheme: [viz tabulka níže]

--------------------------------------------------
3. TABULKA SYMBOLIZACE PRO KAŽDOU MAPU
--------------------------------------------------

MAPA 1: Volební úspěch Pirátů
  Field:      pirati_pct
  Method:     Quantile
  Classes:    7
  Color:      Yellow to Red (YlOrRd) — sekvenční
  Midpoint:   ne
  Poznámka:   Zobrazuje absolutní podíl hlasů; světlá = nízký, tmavá = vysoký

MAPA 2: Rezidua OLS
  Field:      resid_ols
  Method:     Quantile
  Classes:    7
  Color:      Red-Blue Diverging (divergentní)
  Midpoint:   0 (ručně nastavit v "Edit Color Scheme")
  Poznámka:   Červená = model nadhodnotil (Pirátů méně než predikováno)
              Modrá = model podhodnotil (Pirátů více než predikováno)

MAPA 3: Lokální R² (GWR)
  Field:      local_R2
  Method:     Quantile
  Classes:    7
  Color:      Blue-Purple (BuPu) nebo Green (Greens) — sekvenční
  Midpoint:   ne
  Poznámka:   Tmavá = oblast kde model dobře vysvětluje; světlá = horší vysvětlení

MAPA 4: Lokální koeficient — VŠ vzdělání
  Field:      coef_VZDELANI_VYSOKO
  Method:     Natural Breaks (Jenks)
  Classes:    7
  Color:      Red-Blue Diverging
  Midpoint:   0 (přidat ručně: pravý klik na škálu → "Set Midpoint Value" = 0)
  Glob. OLS:  +0.112
  Poznámka:   Modrá = silný pozitivní efekt VŠ; červená = záporný
              V Praze a větších městech očekávejte tmavě modrá

MAPA 5: Lokální koeficient — Vyučení bez maturity
  Field:      coef_VZDELANI_STR_BEZ
  Method:     Natural Breaks (Jenks)
  Classes:    7
  Color:      Red-Blue Diverging
  Midpoint:   0
  Glob. OLS:  -0.079
  Poznámka:   Červená = silný negativní efekt; modrá = záporný koeficient méně výrazný
              Průmyslové regiony (severní Čechy, Ostravsko) → očekávejte červenou

MAPA 6: Lokální koeficient — Podnikatelé/OSVČ
  Field:      coef_PODNIKATELE
  Method:     Natural Breaks (Jenks)
  Classes:    7
  Color:      Red-Blue Diverging
  Midpoint:   0
  Glob. OLS:  +0.071
  Poznámka:   Modrá = oblasti kde podnikatelé silně volí Piráty
              (turistické oblasti, Praha okolí, Jizerské hory?)

--------------------------------------------------
4. KARTOGRAFICKÉ ELEMENTY (každý layout)
--------------------------------------------------
a) North Arrow:
   Insert → North Arrow → vybrat typ (North Arrow 1)
   Umístění: pravý horní roh

b) Scale Bar:
   Insert → Scale Bar → Metric Scale Bar
   Nastavit: km, délka ~100–200 km
   Umístění: levý dolní roh

c) Legenda:
   Insert → Legend
   Upravit název = název mapy (viz výše)
   Doporučeno: zaokrouhlit hodnoty na 2 des. místa

d) Titulek:
   Insert → Text → napsat název mapy
   Doporučená velikost: 18–22 pt, bold

e) Zdroje:
   Insert → Text (small):
   "Zdroj: ČSÚ — volby PSP 2025, SLDB 2021 | Analýza: R 4.5.2, GWmodel"

--------------------------------------------------
5. EXPORT
--------------------------------------------------
Share → Export Map
  Format: PNG (300 dpi pro tisk) nebo PDF (pro prezentaci)
  Resolution: 300 dpi
  Width: 10 in, Height: 7 in

--------------------------------------------------
6. LAYOUT DOPORUČENÍ PRO PREZENTACI
--------------------------------------------------
Data frame: 16:9 (standardní prezentace)
Pozadí: bílé (#FFFFFF)
Fonty: Arial nebo Calibri
Hranice obcí: velmi tenké (0.1–0.2 pt), světle šedé
Doporučit: 1 mapa per slide, ne 4 mapy na jednom slidu
'

writeLines(arcgis_txt, "ARC_GIS_INSTRUKCE.txt")
cat("✓ ARC_GIS_INSTRUKCE.txt\n")

# =============================================================================
# F) CO JE JEŠTĚ POTŘEBA UDĚLAT RUČNĚ
# =============================================================================
todo_txt <- '
CO JE JEŠTĚ POTŘEBA UDĚLAT RUČNĚ
==================================
Vygenerováno: 2026-04
Projekt: Analýza volebního úspěchu Pirátů — PSP 2025

KRITICKÉ (bez toho nemáš hotový projekt):
------------------------------------------
1. PREZENTACE
   Vytvoř prezentaci (PPTX / Google Slides):
   Osnova (10 minut):
   Slide 1 (0:00): Titulní slide — název, autoři
   Slide 2 (0:30): Česká pirátská strana — krátce
     - Ideologie: digitální svobody, transparentnost, přímá demokracie
     - Cílová skupina: mladí, vzdělaní, urbanizovaní voliči
     - Krátce: EU, pirátské hnutí
   Slide 3 (1:30): Volební výsledky v čase
     - Tabulka: 2013 (2.66%), 2017 (10.79%), 2021 (Pirstan 15.62%,
       samostatní 4.65%), 2025 (8.97%, 18 mandátů)
     - Trendy: vzestup, koalice s STAN v 2021, rozchod, obnovení
   Slide 4 (2:30): Mapa volebního úspěchu 2025
     - output/maps/01_mapa_pirati_uspech.png
   Slide 5 (3:30): Data a metodika
     - Zdroje: ČSÚ volby, SLDB 2021
     - n = 6 157 obcí
     - Závislá: pirati_pct; Prediktory: 6 ze SLDB
   Slide 6 (4:30): OLS model
     - output/figures/12_ols_forest_plot.png
     - R² = 18.8 %; všechny prediktory sig.
   Slide 7 (5:30): Diagnostika OLS
     - output/figures/11_moran_ols_vs_gwr.png (Moran část)
     - output/maps/02_mapa_rezidua_ols.png
     - I = 0.08, p = 0.001 → prostorová nestacionarita
   Slide 8 (6:30): GWR — nastavení a porovnání
     - output/tables/05_kernel_comparison.csv → jako tabulka na slide
     - Exponential, BW=23, AICc=28601
   Slide 9 (7:30): GWR — výsledky
     - output/figures/10_ols_vs_gwr_srovnani.png
     - output/maps/03_mapa_local_R2.png
   Slide 10 (8:30): Lokální koeficienty (3 mapy)
     - output/maps/04_coef_VZDELANI_VYSOKO.png
     - output/maps/05_coef_VZDELANI_STR_BEZ.png
     - output/maps/06_coef_PODNIKATELE.png
     - + output/figures/09_boxplot_gwr_vs_ols.png
   Slide 11 (9:30): Závěr
     - Shrnutí výsledků
     - Limity: ekologický klam, MAUP, malý BW

2. ARCGIS PRO — FINÁLNÍ MAPY
   Otevřít: data/processed/pirati_final.gpkg
   Vytvořit 6 map dle ARC_GIS_INSTRUKCE.txt
   Exportovat jako PNG 300 dpi

NEPOVINNÉ (doporučené pro lepší hodnocení):
--------------------------------------------
3. VOLEBNÍ MAPA V KONTEXTU
   Přidat do mapy volebního úspěchu textové anotace
   pro Praha, Brno, Ostrava

4. DODATEČNÁ INTERPRETACE MAP
   Pro každou mapu koeficientu napsat 2-3 věty
   "V oblasti X je koeficient záporný, protože..."

5. KERNEL COMPARISON TABULKA
   Upravit output/tables/05_kernel_comparison.csv
   jako pěknou tabulku na slide (případně screenshot z R)
'

writeLines(todo_txt, "CO_JE_JESTE_POTREBA_DODELAT.txt")
cat("✓ CO_JE_JESTE_POTREBA_DODELAT.txt\n")

# =============================================================================
# ZÁVĚREČNÝ PŘEHLED
# =============================================================================
cat("\n========================================\n")
cat("FINALIZACE DOKONČENA\n")
cat("========================================\n")
cat("\nNové soubory:\n")
new_files <- c(
  "data/processed/pirati_final.gpkg",
  "output/maps/01_mapa_pirati_uspech.png",
  "output/figures/10_ols_vs_gwr_srovnani.png",
  "output/figures/11_moran_ols_vs_gwr.png",
  "output/figures/12_ols_forest_plot.png",
  "output/tables/07_model_summary.csv",
  "output/tables/08_map_variables_overview.csv",
  "output/tables/09_project_checklist.csv",
  "ARC_GIS_INSTRUKCE.txt",
  "CO_JE_JESTE_POTREBA_DODELAT.txt",
  "ANALYZA_POSTUP_FINAL.txt"
)
for (f in new_files) cat(" ", ifelse(file.exists(f), "✓", "?"), f, "\n")
cat("\nPodle zadání chybí jen: PREZENTACE + ArcGIS Pro mapy\n")
cat("Vše analytické je HOTOVO.\n")
