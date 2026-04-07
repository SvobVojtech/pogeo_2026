# =============================================================================
# GWR analýza volebního úspěchu Pirátů — PSP ČR 2025
# =============================================================================
# Autor:  [vaše jméno]
# Datum:  2026-04
# Popis:  Kompletní workflow od načtení dat po GWR model
# =============================================================================

# --- 0. Balíčky ----
library(sf)          # prostorová data, GPKG I/O
library(sp)          # konverze pro GWmodel
library(spdep)       # Moran's I, matice sousednosti
library(GWmodel)     # GWR
library(car)         # VIF
library(lmtest)      # Breusch-Pagan test
library(nortest)     # Lilliefors test
library(corrplot)    # korelační matice
library(tmap)        # mapy
library(dplyr)       # data wrangling
library(ggplot2)     # grafy

# --- 1. Načtení volebních dat ----

gpkg_path <- "data/raw/csu_geodb_sde_CISOB_volbypspdvacetpet_etl_20240701.gpkg"
volby_raw <- st_read(gpkg_path)

# Ověření CRS
st_crs(volby_raw)

# Transformace na S-JTSK (metrický systém, nutný pro GWR)
# Pokud je ve WGS84 (EPSG:4326), transformovat:
# volby <- st_transform(volby_raw, 5514)
# Pokud už je v S-JTSK:
volby <- volby_raw

# Přejmenování sloupců
# !!! DŮLEŽITÉ: Ověřte, které číslo (X) odpovídá Pirátům !!!
# Podle analýzy dat: entity 6 má silný urban bias (Praha 16.85 %, průměr 6.78 %)
#   → s vysokou pravděpodobností Piráti
# OVĚŘTE na volby.cz a upravte níže:

PIRATI_KOD <- "6"  # <-- ZMĚNIT dle skutečného čísla na kandidátce

volby <- volby_raw %>%
  rename(
    kod_obce       = kod,
    nazev_obce     = nazev,
    volici_seznam  = gis224950001,   # voliči v seznamu
    vydane_obalky  = gis224960001,   # vydané obálky
    ucast_pct      = gis224970001,   # volební účast (%)
    platne_hlasy   = gis224830000    # platné hlasy celkem
  )

# Dynamické přejmenování sloupce Pirátů
pirati_abs_col <- paste0("gis22483000", PIRATI_KOD)
pirati_pct_col <- paste0("gis22485000", PIRATI_KOD)

volby$pirati_hlasy <- volby[[pirati_abs_col]]
volby$pirati_pct   <- volby[[pirati_pct_col]]

cat("Piráti — průměr:", mean(volby$pirati_pct, na.rm = TRUE), "%\n")
cat("Piráti — Praha:", volby$pirati_pct[volby$nazev_obce == "Praha"], "%\n")
cat("Počet obcí:", nrow(volby), "\n")

# --- 2. Načtení dat ze SLDB 2021 ----

# Stáhněte data z ČSÚ Veřejné databáze (vdb.czso.cz) po obcích:
# - věková struktura, vzdělání, zaměstnanost, bydlení, ...
# Uložte jako CSV do data/raw/

# sldb <- read.csv("data/raw/sldb_obce.csv", encoding = "UTF-8")
#
# Příklad struktury SLDB dat (sloupce = podíly v %):
# kod_obce | podil_vs | podil_18_34 | podil_65plus | podil_najem |
# hustota  | mira_nezam | podil_tercier | podil_cizincu | podil_osvc |
# podil_bez_vyznani
#
# DŮLEŽITÉ: všechny prediktory jako PODÍLY (%), ne absolutní čísla!

# --- 3. Spojení dat ----

# data <- volby %>%
#   left_join(sldb, by = "kod_obce")

# Prozatím: placeholder — nahraďte skutečnými daty
# Pokud máte SLDB data přímo v GPKG z hodiny, upravte načtení výše
data <- volby  # <-- nahradit spojeným datasetem

# --- 4. Příprava a filtrace ----

# Vyloučení obcí s velmi malým počtem voličů (nestabilní podíly)
cat("Obcí před filtrací:", nrow(data), "\n")
data <- data %>% filter(volici_seznam >= 50)
cat("Obcí po filtraci (>= 50 voličů):", nrow(data), "\n")

# Kontrola NA
# sapply(st_drop_geometry(data), function(x) sum(is.na(x)))

# Transformace CRS (pokud ještě ne v S-JTSK)
if (st_crs(data)$epsg != 5514) {
  data <- st_transform(data, 5514)
  cat("CRS transformováno na S-JTSK (EPSG:5514)\n")
}

# --- 5. Explorační analýza ----

# 5.1 Popisná statistika závislé proměnné
summary(data$pirati_pct)

# 5.2 Histogram
ggplot(data, aes(x = pirati_pct)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "white") +
  labs(title = "Distribuce volebního úspěchu Pirátů",
       x = "Podíl hlasů (%)", y = "Počet obcí") +
  theme_minimal()
ggsave("output/figures/01_histogram_pirati.png", width = 8, height = 5)

# 5.3 Mapa volebního úspěchu
tmap_mode("plot")
m_volby <- tm_shape(data) +
  tm_fill("pirati_pct",
          style = "quantile", n = 7,
          palette = "YlOrRd",
          title = "Piráti (%)") +
  tm_borders(alpha = 0.1) +
  tm_layout(title = "Volební úspěch Pirátů — PSP 2025",
            legend.outside = TRUE)
tmap_save(m_volby, "output/maps/01_mapa_pirati_uspech.png",
          width = 10, height = 7, dpi = 300)

# 5.4 Korelační matice kandidátních prediktorů
# ODKOMENTOVAT po načtení SLDB dat:
# prediktory <- c("podil_vs", "podil_18_34", "podil_65plus", "podil_najem",
#                  "hustota", "mira_nezam", "podil_tercier", "podil_cizincu",
#                  "podil_osvc", "podil_bez_vyznani")
#
# cor_mat <- cor(st_drop_geometry(data[, c("pirati_pct", prediktory)]),
#                use = "complete.obs")
#
# png("output/figures/02_korelacni_matice.png", width = 800, height = 800)
# corrplot(cor_mat, method = "color", type = "lower",
#          addCoef.col = "black", tl.cex = 0.8, number.cex = 0.7,
#          title = "Korelační matice")
# dev.off()

# --- 6. Neprostorový regresní model (OLS) ----

# 6.1 Plný model
# formula_full <- pirati_pct ~ podil_vs + podil_18_34 + podil_65plus +
#   podil_najem + hustota + mira_nezam + podil_tercier +
#   podil_cizincu + podil_osvc + podil_bez_vyznani
#
# model_full <- lm(formula_full, data = data)
# summary(model_full)

# 6.2 VIF — kontrola multikolinearity
# vif_full <- vif(model_full)
# print(vif_full)
# barplot(vif_full, main = "VIF — plný model",
#         col = ifelse(vif_full > 7.5, "red", "steelblue"),
#         las = 2, cex.names = 0.8)
# abline(h = 7.5, lty = 2, col = "red")

# 6.3 Backward stepwise výběr
# model_step <- step(model_full, direction = "backward")
# summary(model_step)

# 6.4 VIF finálního modelu
# vif_final <- vif(model_step)
# print(vif_final)
# cat("Všechny VIF < 7.5:", all(vif_final < 7.5), "\n")

# --- 7. Diagnostika OLS modelu ----

# 7.1 R² a Adjusted R²
# cat("R²:    ", summary(model_step)$r.squared, "\n")
# cat("Adj R²:", summary(model_step)$adj.r.squared, "\n")

# 7.2 Normalita reziduí
# # Shapiro-Wilk (pro n < 5000; u 6000+ obcí použít Lilliefors)
# if (nrow(data) < 5000) {
#   shapiro.test(residuals(model_step))
# }
# lillie.test(residuals(model_step))  # Lilliefors (K-S)
#
# # Q-Q plot
# png("output/figures/03_qq_plot_ols.png", width = 600, height = 600)
# par(mfrow = c(1, 1))
# qqnorm(residuals(model_step), main = "Q-Q plot reziduí OLS")
# qqline(residuals(model_step), col = "red", lwd = 2)
# dev.off()

# 7.3 Heteroskedasticita
# bptest(model_step)  # Breusch-Pagan

# 7.4 Mapa reziduí OLS
# data$resid_ols <- residuals(model_step)
#
# m_resid <- tm_shape(data) +
#   tm_fill("resid_ols", style = "jenks", midpoint = 0,
#           palette = "RdBu", title = "Rezidua OLS") +
#   tm_borders(alpha = 0.1) +
#   tm_layout(title = "Rezidua neprostorového modelu")
# tmap_save(m_resid, "output/maps/02_mapa_rezidua_ols.png",
#           width = 10, height = 7, dpi = 300)

# --- 8. Test prostorové autokorelace reziduí ----

# 8.1 Matice sousednosti
# nb <- poly2nb(data, queen = TRUE)
# summary(nb)
#
# # Kontrola: jsou obce bez sousedů?
# no_neighbors <- which(card(nb) == 0)
# if (length(no_neighbors) > 0) {
#   cat("Obce bez sousedů:", length(no_neighbors), "\n")
#   cat("Názvy:", data$nazev_obce[no_neighbors], "\n")
# }
#
# lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

# 8.2 Moran's I test
# moran_ols <- moran.test(data$resid_ols, lw, zero.policy = TRUE)
# print(moran_ols)
#
# # Monte Carlo verze (robustnější)
# moran_mc_ols <- moran.mc(data$resid_ols, lw, nsim = 999,
#                           zero.policy = TRUE)
# print(moran_mc_ols)
# cat("Moran's I:", moran_mc_ols$statistic, "\n")
# cat("p-value:", moran_mc_ols$p.value, "\n")

# 8.3 Moran scatter plot
# png("output/figures/04_moran_scatterplot.png", width = 600, height = 600)
# moran.plot(data$resid_ols, lw, zero.policy = TRUE,
#            main = "Moran scatter plot — rezidua OLS",
#            xlab = "Rezidua", ylab = "Prostorově zpožděná rezidua")
# dev.off()

# --- 9. GWR model (GWmodel) ----

# 9.1 Konverze na sp objekt (GWmodel vyžaduje SpatialPolygonsDataFrame)
# data_sp <- as(data, "Spatial")
#
# # Matice vzdáleností (centroidy)
# coords <- coordinates(data_sp)
# dMat <- gw.dist(dp.locat = coords)

# 9.2 Formule pro GWR (použít FINÁLNÍ prediktory z OLS)
# formula_gwr <- pirati_pct ~ podil_vs + podil_18_34 + podil_najem +
#                  hustota + mira_nezam
# # Méně prediktorů než OLS — GWR citlivější na multikolinearitu!

# 9.3 Výběr bandwidth — adaptive kernel
# cat("Hledání optimální bandwidth (adaptive, bisquare, AICc)...\n")
# bw_adapt <- bw.gwr(
#   formula = formula_gwr,
#   data    = data_sp,
#   approach = "AICc",
#   kernel  = "bisquare",
#   adaptive = TRUE,
#   dMat    = dMat
# )
# cat("Optimální bandwidth (počet sousedů):", bw_adapt, "\n")

# 9.4 Porovnání kernelů (volitelné, ale doporučené)
# kernel_comparison <- data.frame()
# for (k in c("gaussian", "bisquare", "exponential")) {
#   bw_tmp <- bw.gwr(formula_gwr, data = data_sp, approach = "AICc",
#                     kernel = k, adaptive = TRUE, dMat = dMat)
#   gwr_tmp <- gwr.basic(formula_gwr, data = data_sp, bw = bw_tmp,
#                         kernel = k, adaptive = TRUE, dMat = dMat)
#   kernel_comparison <- rbind(kernel_comparison, data.frame(
#     kernel    = k,
#     bandwidth = bw_tmp,
#     AICc      = gwr_tmp$GW.diagnostic$AICc,
#     R2        = gwr_tmp$GW.diagnostic$gw.R2,
#     adjR2     = gwr_tmp$GW.diagnostic$gwR2.adj
#   ))
# }
# print(kernel_comparison)
# write.csv(kernel_comparison, "output/tables/kernel_comparison.csv",
#           row.names = FALSE)

# 9.5 Fitování GWR
# gwr_model <- gwr.basic(
#   formula  = formula_gwr,
#   data     = data_sp,
#   bw       = bw_adapt,
#   kernel   = "bisquare",
#   adaptive = TRUE,
#   dMat     = dMat
# )
# print(gwr_model)

# 9.6 Diagnostika GWR
# cat("=== Porovnání OLS vs GWR ===\n")
# cat("OLS  — R²:", summary(model_step)$r.squared,
#     "  AIC:", AIC(model_step), "\n")
# cat("GWR  — R²:", gwr_model$GW.diagnostic$gw.R2,
#     "  AICc:", gwr_model$GW.diagnostic$AICc, "\n")
# cat("GWR  — Adj R²:", gwr_model$GW.diagnostic$gwR2.adj, "\n")

# --- 10. Extrakce a vizualizace výsledků GWR ----

# 10.1 Přiřazení výsledků zpět do sf objektu
# gwr_sf <- st_as_sf(gwr_model$SDF)
#
# # Nebo ruční přiřazení:
# gwr_res <- as.data.frame(gwr_model$SDF)
# data$local_R2        <- gwr_res$Local_R2
# data$resid_gwr       <- gwr_res$residual
# data$coef_podil_vs   <- gwr_res$podil_vs
# data$coef_podil_18_34 <- gwr_res$podil_18_34
# data$coef_podil_najem <- gwr_res$podil_najem
# data$coef_hustota    <- gwr_res$hustota
# data$coef_mira_nezam <- gwr_res$mira_nezam

# 10.2 Moran's I reziduí GWR (porovnání s OLS)
# moran_gwr <- moran.test(data$resid_gwr, lw, zero.policy = TRUE)
# cat("Moran's I OLS reziduí:", moran_ols$estimate[1], "\n")
# cat("Moran's I GWR reziduí:", moran_gwr$estimate[1], "\n")

# 10.3 Mapa lokálního R²
# m_r2 <- tm_shape(data) +
#   tm_fill("local_R2", style = "quantile", palette = "Greens",
#           title = "Lokální R²") +
#   tm_borders(alpha = 0.1) +
#   tm_layout(title = "GWR — lokální kvalita modelu")
# tmap_save(m_r2, "output/maps/03_mapa_local_R2.png",
#           width = 10, height = 7, dpi = 300)

# 10.4 Mapy 3 nejvýznamnějších lokálních koeficientů
# # Koeficient 1: podíl VŠ
# m_c1 <- tm_shape(data) +
#   tm_fill("coef_podil_vs", style = "jenks", n = 7,
#           midpoint = 0, palette = "RdBu",
#           title = "Lok. koef.: podíl VŠ") +
#   tm_borders(alpha = 0.1) +
#   tm_layout(title = "GWR — lokální koeficient: podíl VŠ")
# tmap_save(m_c1, "output/maps/04_coef_podil_vs.png",
#           width = 10, height = 7, dpi = 300)
#
# # Koeficient 2: podíl mladých
# m_c2 <- tm_shape(data) +
#   tm_fill("coef_podil_18_34", style = "jenks", n = 7,
#           midpoint = 0, palette = "RdBu",
#           title = "Lok. koef.: podíl 18-34") +
#   tm_borders(alpha = 0.1)
# tmap_save(m_c2, "output/maps/05_coef_podil_mladi.png",
#           width = 10, height = 7, dpi = 300)
#
# # Koeficient 3: podíl nájemního bydlení
# m_c3 <- tm_shape(data) +
#   tm_fill("coef_podil_najem", style = "jenks", n = 7,
#           midpoint = 0, palette = "RdBu",
#           title = "Lok. koef.: podíl nájemní bydlení") +
#   tm_borders(alpha = 0.1)
# tmap_save(m_c3, "output/maps/06_coef_podil_najem.png",
#           width = 10, height = 7, dpi = 300)

# 10.5 Boxplot: lokální koeficienty GWR vs. globální OLS
# # Příprava dat pro porovnávací graf
# coef_names <- c("podil_vs", "podil_18_34", "podil_najem",
#                  "hustota", "mira_nezam")
# ols_coefs <- coef(model_step)[coef_names]
#
# coef_long <- data.frame()
# for (cn in coef_names) {
#   col_name <- paste0("coef_", cn)
#   coef_long <- rbind(coef_long, data.frame(
#     prediktor = cn,
#     hodnota = data[[col_name]],
#     typ = "GWR (lokální)"
#   ))
# }
#
# ggplot(coef_long, aes(x = prediktor, y = hodnota)) +
#   geom_boxplot(fill = "lightblue") +
#   geom_hline(data = data.frame(prediktor = coef_names,
#                                 ols = ols_coefs),
#              aes(yintercept = ols), color = "red", linewidth = 1) +
#   facet_wrap(~prediktor, scales = "free_y") +
#   labs(title = "Lokální koeficienty GWR vs. globální OLS (červená)",
#        y = "Hodnota koeficientu") +
#   theme_minimal()
# ggsave("output/figures/05_boxplot_coef_gwr_vs_ols.png",
#        width = 12, height = 8)

# --- 11. Export pro ArcGIS Pro ----

# st_write(data, "data/processed/pirati_gwr_results.gpkg",
#          layer = "gwr_results", delete_layer = TRUE)
# cat("Data exportována do GPKG pro ArcGIS Pro.\n")

# --- 12. Souhrnné tabulky ----

# Tabulka OLS
# ols_summary <- data.frame(
#   prediktor = names(coef(model_step)),
#   koeficient = coef(model_step),
#   p_hodnota = summary(model_step)$coefficients[, 4],
#   VIF = c(NA, vif_final)  # NA pro intercept
# )
# write.csv(ols_summary, "output/tables/ols_summary.csv", row.names = FALSE)

# Tabulka porovnání OLS vs GWR
# comparison <- data.frame(
#   Metrika = c("R²", "Adj. R²", "AIC/AICc", "Moran's I reziduí",
#               "p-value Moran"),
#   OLS = c(
#     round(summary(model_step)$r.squared, 4),
#     round(summary(model_step)$adj.r.squared, 4),
#     round(AIC(model_step), 2),
#     round(moran_ols$estimate[1], 4),
#     format.pval(moran_ols$p.value)
#   ),
#   GWR = c(
#     round(gwr_model$GW.diagnostic$gw.R2, 4),
#     round(gwr_model$GW.diagnostic$gwR2.adj, 4),
#     round(gwr_model$GW.diagnostic$AICc, 2),
#     round(moran_gwr$estimate[1], 4),
#     format.pval(moran_gwr$p.value)
#   )
# )
# write.csv(comparison, "output/tables/ols_vs_gwr.csv", row.names = FALSE)
# print(comparison)

cat("\n=== HOTOVO ===\n")
cat("Odkomentujte bloky postupně, jak budete mít data ze SLDB.\n")
cat("Výsledky najdete v output/ a data/processed/\n")
