# =============================================================================
# Vizualizace — Analýza volebního úspěchu Pirátů (PSP 2025)
# Spustit PO dokončení 01_gwr_analyza.R (objekt 'data' musí být v paměti)
# =============================================================================

library(sf)
library(ggplot2)
library(dplyr)
library(tmap)

# Pirátská barva (černá/šedá — stranická)
COL_PIRATI <- "#3d3d3d"

# Palety
PAL_PIRATI  <- "YlOrRd"          # výsledky voleb
PAL_DIV     <- "brewer.rd_bu"    # divergentní (koeficienty, rezidua)
PAL_R2      <- "brewer.bu_pu"    # lokální R²
PAL_GREY    <- "grey90"          # bez dat

tmap_mode("plot")

# =============================================================================
# MAP 1: Hlavní mapa volebního úspěchu Pirátů
# =============================================================================
m1 <- tm_shape(data) +
  tm_polygons(
    fill        = "pirati_pct",
    fill.scale  = tm_scale_intervals(
      style  = "quantile",
      n      = 7,
      values = PAL_PIRATI,
      labels = c("nejnižší", "", "", "průměr", "", "", "nejvyšší")
    ),
    fill.legend = tm_legend(
      title    = "Podíl hlasů (%)",
      position = tm_pos_in("right", "bottom")
    ),
    col       = NA,
    col_alpha = 0
  ) +
  tm_title(
    "Volební úspěch Pirátů — PSP ČR 2025",
    position = tm_pos_in("left", "top"),
    size     = 1.1
  ) +
  tm_compass(position = tm_pos_in("right", "top"), size = 1.5) +
  tm_scalebar(
    breaks   = c(0, 50, 100),
    position = tm_pos_in("left", "bottom"),
    text.size = 0.6
  ) +
  tm_credits(
    "Zdroj: ČSÚ (GPKG volby 2025)\nn = 6 157 obcí (≥ 50 voličů)",
    position = tm_pos_in("left", "bottom"),
    size = 0.55
  )

tmap_save(m1, "output/maps/01_mapa_pirati_uspech.png",
          width = 12, height = 8, dpi = 300)
cat("✓ 01_mapa_pirati_uspech.png\n")

# =============================================================================
# MAP 2: Rezidua OLS — agregovaný pohled (průměr přes okresy / plynulejší)
# =============================================================================
# Smoothed přes quantile breaks, méně zašuměné
m2 <- tm_shape(data) +
  tm_polygons(
    fill        = "resid_ols",
    fill.scale  = tm_scale_intervals(
      style    = "quantile",
      n        = 7,
      midpoint = 0,
      values   = PAL_DIV
    ),
    fill.legend = tm_legend(
      title    = "Rezidua OLS",
      position = tm_pos_in("right", "bottom")
    ),
    col = NA, col_alpha = 0
  ) +
  tm_title(
    "Rezidua neprostorového modelu (OLS)\nModré = podhodnoceno | Červené = nadhodnoceno",
    position = tm_pos_in("left", "top"),
    size = 0.9
  ) +
  tm_compass(position = tm_pos_in("right", "top"), size = 1.5) +
  tm_scalebar(breaks = c(0, 50, 100),
              position = tm_pos_in("left", "bottom"), text.size = 0.6)

tmap_save(m2, "output/maps/02_mapa_rezidua_ols.png",
          width = 12, height = 8, dpi = 300)
cat("✓ 02_mapa_rezidua_ols.png\n")

# =============================================================================
# MAP 3: Lokální R² (GWR)
# =============================================================================
m3 <- tm_shape(data) +
  tm_polygons(
    fill        = "local_R2",
    fill.scale  = tm_scale_intervals(
      style  = "quantile",
      n      = 7,
      values = PAL_R2
    ),
    fill.legend = tm_legend(
      title    = "Lokální R²",
      position = tm_pos_in("right", "bottom")
    ),
    col = NA, col_alpha = 0
  ) +
  tm_title(
    "GWR — lokální kvalita modelu (R²)\nGlobální OLS R² = 0.188 | Průměr GWR R² = 0.433",
    position = tm_pos_in("left", "top"),
    size = 0.9
  ) +
  tm_compass(position = tm_pos_in("right", "top"), size = 1.5) +
  tm_scalebar(breaks = c(0, 50, 100),
              position = tm_pos_in("left", "bottom"), text.size = 0.6)

tmap_save(m3, "output/maps/03_mapa_local_R2.png",
          width = 12, height = 8, dpi = 300)
cat("✓ 03_mapa_local_R2.png\n")

# Pomocná funkce pro mapy koeficientů
mapa_koef <- function(col, titul, podtitul, soubor) {
  m <- tm_shape(data) +
    tm_polygons(
      fill        = col,
      fill.scale  = tm_scale_intervals(
        style    = "jenks",
        n        = 7,
        midpoint = 0,
        values   = PAL_DIV
      ),
      fill.legend = tm_legend(
        title    = "Lokální koeficient",
        position = tm_pos_in("right", "bottom")
      ),
      col = NA, col_alpha = 0
    ) +
    tm_title(
      paste0("GWR — lokální koeficient: ", titul, "\n", podtitul),
      position = tm_pos_in("left", "top"),
      size = 0.9
    ) +
    tm_compass(position = tm_pos_in("right", "top"), size = 1.5) +
    tm_scalebar(breaks = c(0, 50, 100),
                position = tm_pos_in("left", "bottom"), text.size = 0.6)
  tmap_save(m, soubor, width = 12, height = 8, dpi = 300)
  cat("✓", basename(soubor), "\n")
}

# =============================================================================
# MAP 4–6: Lokální koeficienty (top 3 prediktory)
# =============================================================================

# OLS globální hodnoty pro podtitulek
ols_vv  <- round(coef(model_ols)["VZDELANI_VYSOKO"], 3)
ols_sb  <- round(coef(model_ols)["VZDELANI_STR_BEZ"], 3)
ols_pod <- round(coef(model_ols)["PODNIKATELE"], 3)

mapa_koef(
  col      = "coef_VZDELANI_VYSOKO",
  titul    = "podíl VŠ vzdělaných",
  podtitul = paste0("Globální OLS koef. = ", ols_vv,
                    "  |  Modré = silnější efekt"),
  soubor   = "output/maps/04_coef_VZDELANI_VYSOKO.png"
)

mapa_koef(
  col      = "coef_VZDELANI_STR_BEZ",
  titul    = "vyučení bez maturity",
  podtitul = paste0("Globální OLS koef. = ", ols_sb,
                    "  |  Červené = silnější negativní efekt"),
  soubor   = "output/maps/05_coef_VZDELANI_STR_BEZ.png"
)

mapa_koef(
  col      = "coef_PODNIKATELE",
  titul    = "podnikatelé / OSVČ",
  podtitul = paste0("Globální OLS koef. = ", ols_pod,
                    "  |  Modré = silnější pozitivní efekt"),
  soubor   = "output/maps/06_coef_PODNIKATELE.png"
)

# =============================================================================
# FIGURE 10: Souhrnný srovnávací panel OLS vs GWR (do prezentace)
# =============================================================================
library(ggplot2)
library(tidyr)

comp_df <- data.frame(
  Metrika    = c("R²", "Adjusted R²", "AIC / AICc", "Moran's I reziduí"),
  OLS        = c(0.1884,  0.1877,  29130.3, 0.0800),
  GWR        = c(0.4447,  0.2999,  28601.1, -0.0017),
  lepsi_GWR  = c(TRUE,    TRUE,    TRUE,    TRUE)
)

comp_long <- comp_df %>%
  pivot_longer(c(OLS, GWR), names_to = "Model", values_to = "Hodnota")

# Barevné panely pro 4 metriky
p_comp <- ggplot(comp_long, aes(x = Model, y = Hodnota, fill = Model)) +
  geom_col(width = 0.55) +
  geom_text(aes(label = round(Hodnota, 3)),
            vjust = -0.4, size = 3.5, fontface = "bold") +
  facet_wrap(~Metrika, scales = "free_y", ncol = 2) +
  scale_fill_manual(values = c("OLS" = "#b2b2b2", "GWR" = "#2b8cbe")) +
  labs(
    title    = "OLS vs. GWR — srovnání modelů",
    subtitle = "GWR (exponential kernel, BW=23) výrazně zlepšuje všechny metriky",
    x        = NULL,
    y        = "Hodnota",
    fill     = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position  = "top",
    strip.text       = element_text(face = "bold", size = 11),
    plot.title       = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )
ggsave("output/figures/10_ols_vs_gwr_srovnani.png", p_comp,
       width = 9, height = 7, dpi = 300)
cat("✓ 10_ols_vs_gwr_srovnani.png\n")

# =============================================================================
# FIGURE 11: Moran's I OLS vs GWR — vizualizace eliminace autokorelace
# =============================================================================
moran_plot_df <- data.frame(
  Model   = c("OLS rezidua", "GWR rezidua"),
  I       = c(0.0800, -0.0017),
  signif  = c("p = 0.001 ***", "p = 0.574 (ns)")
)

p_moran <- ggplot(moran_plot_df, aes(x = Model, y = I, fill = I > 0)) +
  geom_col(width = 0.45) +
  geom_hline(yintercept = 0, linewidth = 0.7, color = "black") +
  geom_text(aes(label = paste0("I = ", round(I, 4), "\n", signif)),
            vjust = ifelse(moran_plot_df$I > 0, -0.3, 1.3),
            size = 4, fontface = "bold") +
  scale_fill_manual(values = c("FALSE" = "#74a9cf", "TRUE" = "#e34a33"),
                    guide  = "none") +
  scale_y_continuous(limits = c(-0.02, 0.12)) +
  labs(
    title    = "Prostorová autokorelace reziduí: OLS → GWR",
    subtitle = "GWR eliminovalo autokorelaci reziduí (I ≈ 0, p = 0.574)",
    x        = NULL,
    y        = "Moran's I"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))
ggsave("output/figures/11_moran_ols_vs_gwr.png", p_moran,
       width = 7, height = 5, dpi = 300)
cat("✓ 11_moran_ols_vs_gwr.png\n")

# =============================================================================
# FIGURE 12: Koeficienty OLS s konfidenčními intervaly (forest plot)
# =============================================================================
ols_ci <- as.data.frame(confint(model_ols))
ols_ci$prediktor <- rownames(ols_ci)
ols_ci$koef <- coef(model_ols)
ols_ci <- ols_ci[ols_ci$prediktor != "(Intercept)", ]
names(ols_ci)[1:2] <- c("low", "high")

# Pěkné české popisky
ols_ci$label <- c(
  "VŠ vzdělání",
  "Vyučení bez mat.",
  "Neprac. důchodci",
  "Podnikatelé/OSVČ",
  "Nezaměstnaní",
  "Věřící"
)

p_forest <- ggplot(ols_ci, aes(x = reorder(label, koef),
                                 y = koef, ymin = low, ymax = high,
                                 color = koef > 0)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(size = 0.8, linewidth = 1) +
  scale_color_manual(values = c("TRUE" = "#2166ac", "FALSE" = "#d73027"),
                     guide = "none") +
  coord_flip() +
  labs(
    title    = "OLS koeficienty s 95% konfidenčními intervaly",
    subtitle = "Modrá = pozitivní vliv | Červená = negativní vliv na podíl hlasů Pirátů",
    x        = NULL,
    y        = "Koeficient (p.p. hlasů na 1 p.p. prediktoru)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))
ggsave("output/figures/12_ols_forest_plot.png", p_forest,
       width = 8, height = 5, dpi = 300)
cat("✓ 12_ols_forest_plot.png\n")

# =============================================================================
# EXPORT GPKG (opravená verze)
# =============================================================================
cat("\n--- Export do GPKG ---\n")
export_cols <- c("kod_obce", "nazev_obce", "pirati_pct",
                  "resid_ols", "fitted_ols",
                  "local_R2", "resid_gwr",
                  "coef_VZDELANI_VYSOKO", "coef_VZDELANI_STR_BEZ",
                  "coef_PODNIKATELE",
                  prediktory)

data_export <- data[, export_cols]   # sf zachová geometrii automaticky
st_write(data_export,
         "data/processed/pirati_gwr_results.gpkg",
         layer = "gwr_results", delete_layer = TRUE)
cat("✓ data/processed/pirati_gwr_results.gpkg\n")

# =============================================================================
# PŘEHLED VŠECH VÝSTUPŮ
# =============================================================================
cat("\n========================================\n")
cat("VŠECHNY VÝSTUPY\n")
cat("========================================\n")
cat("\nMAPS (output/maps/):\n")
cat("  01_mapa_pirati_uspech.png  — hlavní mapa Y\n")
cat("  02_mapa_rezidua_ols.png   — rezidua OLS\n")
cat("  03_mapa_local_R2.png      — lokální R² GWR\n")
cat("  04_coef_VZDELANI_VYSOKO.png\n")
cat("  05_coef_VZDELANI_STR_BEZ.png\n")
cat("  06_coef_PODNIKATELE.png\n")
cat("\nFIGURES (output/figures/):\n")
cat("  01_histogram_pirati.png\n")
cat("  02_korelacni_matice.png\n")
cat("  04_scatterploty_Y_vs_prediktory.png\n")
cat("  05_vif.png\n")
cat("  07_qq_plot_ols.png\n")
cat("  08_moran_scatterplot_ols.png\n")
cat("  09_boxplot_gwr_vs_ols.png\n")
cat("  10_ols_vs_gwr_srovnani.png  ← NOVÉ\n")
cat("  11_moran_ols_vs_gwr.png     ← NOVÉ\n")
cat("  12_ols_forest_plot.png      ← NOVÉ\n")
cat("\nTABLES (output/tables/):\n")
cat("  02_korelace_s_Y.csv\n")
cat("  03_ols_koeficienty.csv\n")
cat("  05_kernel_comparison.csv\n")
cat("  06_moran_ols_vs_gwr.csv\n")
cat("\nGPKG (data/processed/):\n")
cat("  pirati_gwr_results.gpkg   → import do ArcGIS Pro\n")
