# =============================================================================
# GWR analýza volebního úspěchu Pirátů — PSP ČR 2025
# Krok 1: Načtení dat a základní kontrola
# =============================================================================

# --- 0. Balíčky ----
library(sf)
library(dplyr)

# =============================================================================
# KROK 1: NAČTENÍ A PŘÍPRAVA DAT
# =============================================================================

# --- 1.1 Načtení volebních dat z GPKG ----
gpkg_path <- "csu_geodb_sde_CISOB_volbypspdvacetpet_etl_20240701.gpkg"
volby_raw <- st_read(gpkg_path)

cat("Rozměry:", nrow(volby_raw), "obcí,", ncol(volby_raw), "sloupců\n")
head(volby_raw)

# --- 1.2 Přejmenování kryptických sloupců ----
# Kódy ČSÚ → srozumitelné názvy
# gis22483000X = absolutní hlasy pro stranu X
# gis22485000X = podíl hlasů strany X (% z platných)

volby <- volby_raw %>%
  rename(
    kod_obce       = kod,
    nazev_obce     = nazev,
    volici_seznam  = gis224950001,   # voliči v seznamu (registrovaní)
    vydane_obalky  = gis224960001,   # vydané obálky
    ucast_pct      = gis224970001,   # volební účast (%)
    platne_hlasy   = gis224830000,   # platné hlasy celkem
    # Absolutní hlasy pro strany
    strana2_abs    = gis224830002,
    strana3_abs    = gis224830003,
    strana5_abs    = gis224830005,
    strana6_abs    = gis224830006,
    strana7_abs    = gis224830007,
    strana8_abs    = gis224830008,
    strana9_abs    = gis224830009,
    # Podíly stran (% z platných hlasů)
    strana2_pct    = gis224850002,
    strana3_pct    = gis224850003,
    strana5_pct    = gis224850005,
    strana6_pct    = gis224850006,
    strana7_pct    = gis224850007,
    strana8_pct    = gis224850008,
    strana9_pct    = gis224850009
  )

# --- 1.3 Identifikace Pirátů ----
# Zobrazíme výsledky pro Prahu — snadno se identifikuje, která strana je která
praha <- volby %>%
  st_drop_geometry() %>%
  filter(nazev_obce == "Praha") %>%
  select(nazev_obce, ends_with("_pct")) %>%
  tidyr::pivot_longer(-nazev_obce, names_to = "strana", values_to = "pct") %>%
  arrange(desc(pct))

cat("\n=== Výsledky v Praze (%) — pro identifikaci stran ===\n")
print(praha)

# Celkové průměry za ČR
prumery <- volby %>%
  st_drop_geometry() %>%
  summarise(across(ends_with("_pct"), ~ mean(.x, na.rm = TRUE))) %>%
  tidyr::pivot_longer(everything(), names_to = "strana", values_to = "prumer_cr") %>%
  arrange(desc(prumer_cr))

cat("\n=== Průměrné výsledky za ČR (%) ===\n")
print(prumery)

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# !!! ZKONTROLUJTE VÝŠE A DOPLŇTE: Které číslo odpovídá Pirátům?       !!!
# !!! Pak upravte řádek níže.                                           !!!
# !!! Tip: Piráti mají silný urban bias (Praha >> průměr ČR)            !!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

PIRATI_CISLO <- "6"  # <-- ZMĚŇTE dle skutečnosti

# Vytvoření závislé proměnné
pirati_pct_col <- paste0("strana", PIRATI_CISLO, "_pct")
pirati_abs_col <- paste0("strana", PIRATI_CISLO, "_abs")

volby$pirati_pct   <- volby[[pirati_pct_col]]
volby$pirati_hlasy <- volby[[pirati_abs_col]]

cat("\nZávislá proměnná: pirati_pct (podíl hlasů Pirátů v %)\n")
cat("Zdroj sloupec:", pirati_pct_col, "\n")
summary(volby$pirati_pct)

# --- 1.4 Načtení SLDB 2021 dat ----
sldb <- read.csv("sldb2021_obce_indikatory.csv", encoding = "UTF-8")

cat("\nSLDB rozměry:", nrow(sldb), "obcí,", ncol(sldb), "sloupců\n")
cat("Sloupce SLDB:\n")
print(names(sldb))

# Kontrola: jsou všechny hodnoty v procentech?
cat("\nRozsahy hodnot SLDB (min-max):\n")
sldb_ranges <- sapply(sldb[, -1], range, na.rm = TRUE)
print(round(sldb_ranges, 2))

# --- 1.5 Spojení volebních dat se SLDB ----
# Klíč: kod_obce (GPKG) = uzemi_kod (SLDB)
# Oba jsou 6místné LAU2 kódy, ale v GPKG je TEXT, v SLDB numeric
volby$kod_obce <- as.character(volby$kod_obce)
sldb$uzemi_kod <- as.character(sldb$uzemi_kod)

data <- volby %>%
  left_join(sldb, by = c("kod_obce" = "uzemi_kod"))

cat("\nPo spojení:", nrow(data), "obcí\n")
cat("Nespojené obce (NA ve SLDB):",
    sum(is.na(data$VZDELANI_VYSOKO)), "\n")

# --- 1.6 Kontrola CRS ----
cat("\n=== Souřadnicový systém ===\n")
cat("EPSG:", st_crs(data)$epsg, "\n")
cat("Proj4:", st_crs(data)$proj4string, "\n")

# GWR potřebuje metrický CRS → S-JTSK (EPSG:5514)
if (!is.na(st_crs(data)$epsg) && st_crs(data)$epsg == 5514) {
  cat("OK: Data jsou v S-JTSK (EPSG:5514) — vhodné pro GWR.\n")
} else {
  cat("TRANSFORMACE: Převádím na S-JTSK (EPSG:5514)...\n")
  data <- st_transform(data, 5514)
  cat("Nový EPSG:", st_crs(data)$epsg, "\n")
}

# --- 1.7 Kontrola chybějících hodnot ----
cat("\n=== Chybějící hodnoty ===\n")
na_counts <- sapply(st_drop_geometry(data), function(x) sum(is.na(x)))
na_counts <- na_counts[na_counts > 0]
if (length(na_counts) > 0) {
  print(na_counts)
} else {
  cat("Žádné chybějící hodnoty.\n")
}

# --- 1.8 Filtrace ----
# Odstranit vojenské újezdy (nemají voliče ani SLDB data)
cat("\nObce bez voličů nebo bez SLDB dat:\n")
problemy <- data %>%
  st_drop_geometry() %>%
  filter(is.na(volici_seznam) | is.na(VZDELANI_VYSOKO)) %>%
  select(kod_obce, nazev_obce, volici_seznam)
print(problemy)

n_pred <- nrow(data)
data <- data %>% filter(!is.na(volici_seznam) & !is.na(VZDELANI_VYSOKO))
cat("Odstraněno:", n_pred - nrow(data), "obcí\n")

# Filtr: minimálně 50 voličů (stabilita podílů)
n_pred <- nrow(data)
data <- data %>% filter(volici_seznam >= 50)
cat("Odstraněno (< 50 voličů):", n_pred - nrow(data), "obcí\n")
cat("Finální dataset:", nrow(data), "obcí\n")

# --- 1.9 Shrnutí ----
cat("\n=== SHRNUTÍ KROKU 1 ===\n")
cat("Závislá proměnná: pirati_pct (Piráti, % z platných hlasů)\n")
cat("Počet obcí:", nrow(data), "\n")
cat("CRS: EPSG", st_crs(data)$epsg, "\n")
cat("SLDB prediktory (kandidátní):\n")
sldb_cols <- names(sldb)[-1]  # bez uzemi_kod
cat(" ", paste(sldb_cols, collapse = ", "), "\n")
cat("\nPoznámka: SLDB hodnoty jsou v procentech (podíly).\n")

# =============================================================================
# KROK 2: EXPLORATORNÍ ANALÝZA DAT (EDA)
# =============================================================================
# Cíl: poznat rozložení závislé proměnné, korelace mezi prediktory,
#       identifikovat multikolinearitu a outlieery PŘED modelováním.

library(ggplot2)
library(corrplot)

# --- 2.1 Popisná statistika závislé proměnné ----
cat("\n=== KROK 2: EDA ===\n")
cat("\n--- 2.1 Závislá proměnná: pirati_pct ---\n")
summary(data$pirati_pct)
cat("Směrodatná odchylka:", sd(data$pirati_pct), "\n")
cat("Šikmost (skewness):", moments::skewness(data$pirati_pct), "\n")
cat("Špičatost (kurtosis):", moments::kurtosis(data$pirati_pct), "\n")

# --- 2.2 Histogram závislé proměnné ----
p_hist <- ggplot(data, aes(x = pirati_pct)) +
  geom_histogram(bins = 50, fill = "#2b8cbe", color = "white", linewidth = 0.2) +
  geom_vline(xintercept = mean(data$pirati_pct), color = "red",
             linetype = "dashed", linewidth = 0.8) +
  labs(title = "Rozložení volebního úspěchu Pirátů (PSP 2025)",
       subtitle = paste0("n = ", nrow(data), " obcí | průměr = ",
                         round(mean(data$pirati_pct), 2), " %"),
       x = "Podíl hlasů Pirátů (%)", y = "Počet obcí") +
  theme_minimal(base_size = 12)
ggsave("output/figures/01_histogram_pirati.png", p_hist,
       width = 8, height = 5, dpi = 300)
cat("Uloženo: output/figures/01_histogram_pirati.png\n")

# --- 2.3 Popisné statistiky všech kandidátních prediktorů ----
# Definice kandidátních prediktorů ze SLDB
# (MUZI a ZENY vynecháme — jsou komplementární, součet ~100 %)
prediktory_kandidatni <- c(
  "VEK0_14", "VEK15_64", "VEK65",
  "VZDELANI_BEZ", "VZDELANI_ZAKLAD", "VZDELANI_STR_BEZ",
  "VZDELANI_STR_S", "VZDELANI_VOS", "VZDELANI_VYSOKO",
  "ROMOVE", "VERICI",
  "ZAMESTNANCI", "ZAMESTNAVATELE", "PODNIKATELE",
  "NEZAMEST", "PRAC_DUCH", "NEPRAC_DUCH"
)

cat("\n--- 2.3 Popisné statistiky prediktorů ---\n")
stats_df <- data %>%
  st_drop_geometry() %>%
  select(all_of(prediktory_kandidatni)) %>%
  summarise(across(everything(), list(
    prumer = ~ round(mean(.x, na.rm = TRUE), 2),
    median = ~ round(median(.x, na.rm = TRUE), 2),
    sd     = ~ round(sd(.x, na.rm = TRUE), 2),
    min    = ~ round(min(.x, na.rm = TRUE), 2),
    max    = ~ round(max(.x, na.rm = TRUE), 2)
  ))) %>%
  tidyr::pivot_longer(everything(),
                      names_to = c("prediktor", "stat"),
                      names_sep = "_(?=[^_]+$)") %>%
  tidyr::pivot_wider(names_from = stat, values_from = value)

print(stats_df, n = 30)
write.csv(stats_df, "output/tables/01_popisne_statistiky.csv", row.names = FALSE)

# --- 2.4 Korelace prediktorů se závislou proměnnou ----
cat("\n--- 2.4 Korelace prediktorů s pirati_pct ---\n")
cor_s_y <- data %>%
  st_drop_geometry() %>%
  select(pirati_pct, all_of(prediktory_kandidatni)) %>%
  cor(use = "complete.obs")

# Výpis korelací s Y, seřazeno podle absolutní hodnoty
cor_y_vec <- cor_s_y[1, -1]
cor_y_sorted <- sort(abs(cor_y_vec), decreasing = TRUE)
cor_y_df <- data.frame(
  prediktor = names(cor_y_sorted),
  korelace_s_Y = round(cor_y_vec[names(cor_y_sorted)], 3),
  abs_korelace = round(cor_y_sorted, 3)
)
print(cor_y_df, row.names = FALSE)
write.csv(cor_y_df, "output/tables/02_korelace_s_Y.csv", row.names = FALSE)

# --- 2.5 Korelační matice mezi prediktory ----
cat("\n--- 2.5 Korelační matice mezi prediktory ---\n")
cor_pred <- cor(
  st_drop_geometry(data)[, prediktory_kandidatni],
  use = "complete.obs"
)

# Identifikace silně korelovaných párů (|r| > 0.7)
cat("Páry s |r| > 0.7:\n")
high_cor <- which(abs(cor_pred) > 0.7 & upper.tri(cor_pred), arr.ind = TRUE)
if (nrow(high_cor) > 0) {
  for (i in seq_len(nrow(high_cor))) {
    r <- high_cor[i, ]
    cat(sprintf("  %s <-> %s : r = %.3f\n",
                prediktory_kandidatni[r[1]],
                prediktory_kandidatni[r[2]],
                cor_pred[r[1], r[2]]))
  }
} else {
  cat("  Žádné.\n")
}

# Vizualizace korelační matice
png("output/figures/02_korelacni_matice.png", width = 1000, height = 1000, res = 120)
corrplot(cor_pred, method = "color", type = "lower",
         addCoef.col = "black", number.cex = 0.55,
         tl.cex = 0.7, tl.col = "black",
         col = colorRampPalette(c("#b2182b", "white", "#2166ac"))(200),
         title = "Korelační matice — kandidátní prediktory",
         mar = c(0, 0, 2, 0))
dev.off()
cat("Uloženo: output/figures/02_korelacni_matice.png\n")

# --- 2.6 Boxploty vybraných prediktorů ----
# Top 6 prediktorů dle korelace s Y
top6 <- head(cor_y_df$prediktor, 6)

p_box <- data %>%
  st_drop_geometry() %>%
  select(all_of(top6)) %>%
  tidyr::pivot_longer(everything(), names_to = "prediktor", values_to = "hodnota") %>%
  ggplot(aes(x = prediktor, y = hodnota)) +
  geom_boxplot(fill = "#a6bddb", outlier.size = 0.5, outlier.alpha = 0.3) +
  labs(title = "Boxploty — 6 nejvíce korelovaných prediktorů",
       x = NULL, y = "Hodnota (%)") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
ggsave("output/figures/03_boxploty_top6.png", p_box, width = 9, height = 5, dpi = 300)
cat("Uloženo: output/figures/03_boxploty_top6.png\n")

# --- 2.7 Scatterploty: Y vs. top prediktory ----
p_scatter <- data %>%
  st_drop_geometry() %>%
  select(pirati_pct, all_of(top6)) %>%
  tidyr::pivot_longer(-pirati_pct, names_to = "prediktor", values_to = "hodnota") %>%
  ggplot(aes(x = hodnota, y = pirati_pct)) +
  geom_point(alpha = 0.15, size = 0.5, color = "#2b8cbe") +
  geom_smooth(method = "lm", color = "red", linewidth = 0.7, se = FALSE) +
  facet_wrap(~prediktor, scales = "free_x", ncol = 3) +
  labs(title = "Závislá proměnná vs. top prediktory",
       x = "Prediktor (%)", y = "Piráti (%)") +
  theme_minimal(base_size = 10)
ggsave("output/figures/04_scatterploty_Y_vs_prediktory.png", p_scatter,
       width = 10, height = 7, dpi = 300)
cat("Uloženo: output/figures/04_scatterploty_Y_vs_prediktory.png\n")

# --- 2.8 Shrnutí EDA ----
cat("\n=== SHRNUTÍ KROKU 2 ===\n")
cat("Závislá proměnná: pirati_pct\n")
cat("  průměr:", round(mean(data$pirati_pct), 2), "%\n")
cat("  medián:", round(median(data$pirati_pct), 2), "%\n")
cat("  rozsah:", round(min(data$pirati_pct), 2), "–",
    round(max(data$pirati_pct), 2), "%\n")
cat("\nTop 6 prediktorů (dle |r| s Y):\n")
for (i in 1:6) {
  cat(sprintf("  %d. %s (r = %.3f)\n", i,
              cor_y_df$prediktor[i], cor_y_df$korelace_s_Y[i]))
}
cat("\nSilně korelované páry prediktorů (|r| > 0.7):",
    nrow(high_cor), "párů\n")
cat("Výstupy: output/figures/ a output/tables/\n")

# =============================================================================
# KROK 3: GLOBÁLNÍ REGRESNÍ MODEL (OLS)
# =============================================================================
# Lineární model odhaduje průměrný vztah platný pro celé území ČR naráz.
# Je to výchozí bod — pokud rezidua budou prostorově autokorelovaná,
# bude to zdůvodnění pro přechod na GWR.

library(car)      # VIF
library(ggplot2)

cat("\n=== KROK 3: OLS MODEL ===\n")

# --- 3.1 Definice prediktorů ----
# Výběr na základě EDA:
# - pokrývají 3 dimenze: vzdělání, demografii, ekonomiku + hodnoty
# - vyřazeny: VEK skupiny (suma=100%), vzdělání nadbytečná (suma=100%),
#             VEK65 (koreluje s NEPRAC_DUCH), vše s |r|<0.06
prediktory <- c(
  "VZDELANI_VYSOKO",   # % VŠ vzdělaných          (+)
  "VZDELANI_STR_BEZ",  # % vyučených bez maturity  (-)
  "NEPRAC_DUCH",       # % nepracujících důchodců  (-)
  "PODNIKATELE",       # % OSVČ/podnikatelů        (+)
  "NEZAMEST",          # % nezaměstnaných          (-)
  "VERICI"             # % věřících                (-)
)

# --- 3.2 Sestavení modelu ----
formula_ols <- as.formula(
  paste("pirati_pct ~", paste(prediktory, collapse = " + "))
)
cat("Formule:", deparse(formula_ols), "\n\n")

model_ols <- lm(formula_ols, data = st_drop_geometry(data))

# --- 3.3 Výsledky modelu ----
cat("--- Výsledky OLS ---\n")
print(summary(model_ols))

# Přehledná tabulka koeficientů
coef_tbl <- as.data.frame(summary(model_ols)$coefficients)
coef_tbl$prediktor <- rownames(coef_tbl)
coef_tbl <- coef_tbl[, c("prediktor", "Estimate", "Std. Error", "t value", "Pr(>|t|)")]
names(coef_tbl) <- c("prediktor", "koeficient", "std_chyba", "t", "p_hodnota")
coef_tbl[, 2:5] <- round(coef_tbl[, 2:5], 4)
write.csv(coef_tbl, "output/tables/03_ols_koeficienty.csv", row.names = FALSE)
cat("\nKoeficienty uloženy: output/tables/03_ols_koeficienty.csv\n")

# --- 3.4 R² a Adjusted R² ----
r2     <- summary(model_ols)$r.squared
r2_adj <- summary(model_ols)$adj.r.squared
cat(sprintf("\nR²:         %.4f  (model vysvětluje %.1f %% variability)\n",
            r2, r2 * 100))
cat(sprintf("Adjusted R²: %.4f\n", r2_adj))
cat(sprintf("AIC:         %.2f\n", AIC(model_ols)))

# --- 3.5 VIF — kontrola multikolinearity ----
cat("\n--- VIF (Variance Inflation Factor) ---\n")
vif_vals <- vif(model_ols)
print(round(vif_vals, 3))
cat("\nPravidlo: VIF < 5 = OK, 5–10 = pozor, > 10 = problém\n")

# Graficky
vif_df <- data.frame(
  prediktor = names(vif_vals),
  VIF = as.numeric(vif_vals)
)
p_vif <- ggplot(vif_df, aes(x = reorder(prediktor, VIF), y = VIF,
                             fill = VIF > 5)) +
  geom_col(width = 0.6) +
  geom_hline(yintercept = 5,  linetype = "dashed", color = "orange", linewidth = 0.8) +
  geom_hline(yintercept = 10, linetype = "dashed", color = "red",    linewidth = 0.8) +
  scale_fill_manual(values = c("FALSE" = "#2b8cbe", "TRUE" = "#e34a33"),
                    guide = "none") +
  coord_flip() +
  labs(title = "VIF — multikolinearita prediktorů",
       subtitle = "Oranžová čára = 5, červená = 10",
       x = NULL, y = "VIF") +
  theme_minimal(base_size = 12)
ggsave("output/figures/05_vif.png", p_vif, width = 7, height = 4, dpi = 300)
cat("Uloženo: output/figures/05_vif.png\n")

# --- 3.6 Uložení reziduí do datasetu ----
data$resid_ols    <- residuals(model_ols)
data$fitted_ols   <- fitted(model_ols)

cat("\n--- Shrnutí reziduí ---\n")
cat(sprintf("  Min:    %.3f\n", min(data$resid_ols)))
cat(sprintf("  Max:    %.3f\n", max(data$resid_ols)))
cat(sprintf("  Průměr: %.6f  (měl by být ~0)\n", mean(data$resid_ols)))

# --- 3.7 Diagnostické grafy reziduí ----
# Fitted vs. Residuals (kontrola heteroskedasticity)
p_fvr <- ggplot(data, aes(x = fitted_ols, y = resid_ols)) +
  geom_point(alpha = 0.2, size = 0.6, color = "#2b8cbe") +
  geom_hline(yintercept = 0, color = "red", linewidth = 0.8) +
  geom_smooth(method = "loess", color = "orange", linewidth = 0.7, se = FALSE) +
  labs(title = "Fitted vs. Residuals",
       subtitle = "Ideál: rovnoměrně rozptýleno kolem nuly",
       x = "Fitted hodnoty", y = "Rezidua") +
  theme_minimal(base_size = 12)
ggsave("output/figures/06_fitted_vs_residuals.png", p_fvr,
       width = 7, height = 5, dpi = 300)

# Q-Q plot (normalita reziduí)
p_qq <- ggplot(data, aes(sample = resid_ols)) +
  stat_qq(alpha = 0.3, size = 0.5, color = "#2b8cbe") +
  stat_qq_line(color = "red", linewidth = 0.8) +
  labs(title = "Q-Q plot reziduí OLS",
       subtitle = "Ideál: body leží na červené přímce",
       x = "Teoretické kvantily", y = "Výběrové kvantily") +
  theme_minimal(base_size = 12)
ggsave("output/figures/07_qq_plot_ols.png", p_qq,
       width = 6, height = 6, dpi = 300)
cat("Uloženy diagnostické grafy (05–07)\n")

# --- 3.8 Shrnutí Kroku 3 ----
cat("\n=== SHRNUTÍ KROKU 3 ===\n")
cat(sprintf("Model: pirati_pct ~ %s\n", paste(prediktory, collapse = " + ")))
cat(sprintf("R² = %.4f | Adj. R² = %.4f | AIC = %.1f\n",
            r2, r2_adj, AIC(model_ols)))
cat("Všechny VIF < 5?", all(vif_vals < 5), "\n")
sig <- coef_tbl$prediktor[coef_tbl$p_hodnota < 0.05 &
                            coef_tbl$prediktor != "(Intercept)"]
cat("Statisticky významné prediktory (p<0.05):", paste(sig, collapse = ", "), "\n")

# =============================================================================
# KROK 4: DIAGNOSTIKA REZIDUÍ + PROSTOROVÁ AUTOKORELACE (MORAN'S I)
# =============================================================================
# OLS předpokládá, že rezidua jsou prostorově nezávislá.
# Moran's I test ověří, zda jsou rezidua náhodně rozmístěna v prostoru,
# nebo zda sousední obce mají podobné chyby předpovědi (= autokorelace).
# Statisticky významný Moran's I → GWR je metodicky zdůvodněné.

library(spdep)
library(tmap)

cat("\n=== KROK 4: MORAN'S I REZIDUÍ OLS ===\n")

# --- 4.1 Matice prostorové sousednosti ----
# Queen adjacency: sdílení hrany nebo rohu = soused
cat("Vytvářím matici sousednosti (queen contiguity)...\n")
nb <- poly2nb(data, queen = TRUE)

# Kontrola "osamělých" obcí (bez sousedů)
no_nb <- sum(card(nb) == 0)
cat("Obce bez sousedů:", no_nb, "\n")
if (no_nb > 0) {
  cat("  Exklávní obce bez kontaktu (ostrovy) — neovlivní výsledek.\n")
}

# Váhová matice (row-standardized: každý soused váha 1/n_sousedů)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)
cat("Průměrný počet sousedů:", mean(card(nb)), "\n")

# --- 4.2 Globální Moran's I test ----
cat("\n--- Globální Moran's I (analytický test) ---\n")
moran_test <- moran.test(data$resid_ols, lw, zero.policy = TRUE)
print(moran_test)

# --- 4.3 Monte Carlo permutační test (robustnější) ----
# Dle POGEO skript: 999 permutací, pseudo p = (R+1)/(M+1)
cat("\n--- Moran's I Monte Carlo (999 permutací) ---\n")
set.seed(42)
moran_mc <- moran.mc(data$resid_ols, lw, nsim = 999, zero.policy = TRUE)
print(moran_mc)

cat(sprintf("\nVýsledek: I = %.4f | p-value = %.4f\n",
            moran_mc$statistic, moran_mc$p.value))
cat("Práh ze skript: |I| >= 0.3 = silná autokorelace\n")
if (moran_mc$p.value < 0.05) {
  cat("ZÁVĚR: Rezidua jsou PROSTOROVĚ AUTOKORELOVANÁ → GWR je zdůvodněné!\n")
} else {
  cat("ZÁVĚR: Prostorová autokorelace není statisticky průkazná.\n")
}

# --- 4.4 Moran scatterplot ----
png("output/figures/08_moran_scatterplot_ols.png",
    width = 700, height = 700, res = 120)
moran.plot(data$resid_ols, lw, zero.policy = TRUE,
           main = "Moran scatterplot — rezidua OLS",
           xlab = "Rezidua OLS",
           ylab = "Prostorově zpožděná rezidua (Wy)",
           pch = 20, cex = 0.4, col = "#2b8cbe80")
dev.off()
cat("Uloženo: output/figures/08_moran_scatterplot_ols.png\n")

# --- 4.5 Mapa reziduí OLS ----
# Vizuálně ukáže, zda jsou velká rezidua prostorově shlukovaná
tmap_mode("plot")
m_resid <- tm_shape(data) +
  tm_fill("resid_ols",
          style   = "jenks",
          n       = 7,
          midpoint = 0,
          palette = "RdBu",
          title   = "Rezidua OLS") +
  tm_borders(alpha = 0.08) +
  tm_layout(
    title          = "Rezidua neprostorového modelu (OLS)",
    legend.outside = TRUE,
    frame          = FALSE
  )
tmap_save(m_resid, "output/maps/02_mapa_rezidua_ols.png",
          width = 10, height = 7, dpi = 300)
cat("Uloženo: output/maps/02_mapa_rezidua_ols.png\n")

# --- 4.6 Uložení výsledků Moran's I ----
moran_df <- data.frame(
  test       = c("OLS rezidua"),
  moran_I    = round(moran_mc$statistic, 4),
  p_value    = round(moran_mc$p.value, 4),
  signifikant = moran_mc$p.value < 0.05
)
write.csv(moran_df, "output/tables/04_moran_ols.csv", row.names = FALSE)

# --- 4.7 Shrnutí Kroku 4 ----
cat("\n=== SHRNUTÍ KROKU 4 ===\n")
cat(sprintf("Moran's I (OLS rezidua): %.4f\n", moran_mc$statistic))
cat(sprintf("p-value (Monte Carlo):   %.4f\n", moran_mc$p.value))
cat(sprintf("Počet permutací:         %d\n", moran_mc$parameter))
cat("Závěr: prostorová autokorelace reziduí →",
    ifelse(moran_mc$p.value < 0.05, "GWR ZDŮVODNĚNO", "GWR méně potřebné"), "\n")

# =============================================================================
# KROK 5: ROZHODNUTÍ — OLS vs GWR
# =============================================================================
# Moran's I reziduí OLS = 0.08, p = 0.001 → statisticky průkazná
# prostorová autokorelace reziduí → globální koeficienty nejsou v celém
# území stejné → přechod na GWR je metodicky zdůvodněný.
cat("\n=== KROK 5: ROZHODNUTÍ ===\n")
cat("I = 0.0800 (střední intenzita, |I| < 0.3 ze skript = 'silná')\n")
cat("Ale p = 0.001 → autokorelace statisticky PRŮKAZNÁ.\n")
cat("Závěr: OLS model je NESTACIONÁRNÍ → GWR umožní lokální koeficienty.\n")

# =============================================================================
# KROK 6: GWR MODEL (GWmodel)
# =============================================================================
# GWR fituje n lokálních OLS modelů (jeden per obec), kde každý pozorování
# dostane váhu dle vzdálenosti od fokálního bodu (kernel funkce).
# Výstupem jsou lokální koeficienty β(u,v), lokální R² a rezidua.

library(GWmodel)
library(sp)

cat("\n=== KROK 6: GWR MODEL ===\n")

# --- 6.1 Převod na sp objekt (GWmodel vyžaduje Spatial*) ----
data_sp <- as(data, "Spatial")
coords  <- coordinates(data_sp)
cat("Převod na sp: OK |", nrow(data_sp), "obcí\n")

# Formule GWR — stejná jako OLS
# (VIF všechny < 3 → multikolinearita není problém)
formula_gwr <- formula_ols

# --- 6.2 Předvýpočet matice vzdáleností ----
# Pro 6157 obcí je to velká matice (~300 MB) — buďme trpěliví
cat("Počítám matici vzdáleností (může trvat 1–3 minuty)...\n")
dMat <- gw.dist(dp.locat = coords)
cat("dMat: OK\n")

# --- 6.3 Výběr bandwidth — porovnání adaptive vs fixed ----
cat("\n--- 6.3a Bandwidth: ADAPTIVE kernel (bisquare, AICc) ---\n")
bw_adapt <- bw.gwr(
  formula  = formula_gwr,
  data     = data_sp,
  approach = "AICc",
  kernel   = "bisquare",
  adaptive = TRUE,         # počet sousedů (ne vzdálenost)
  dMat     = dMat
)
cat("Optimální bandwidth (adaptive, počet sousedů):", bw_adapt, "\n")

cat("\n--- 6.3b Bandwidth: FIXED kernel (bisquare, AICc) ---\n")
bw_fixed <- bw.gwr(
  formula  = formula_gwr,
  data     = data_sp,
  approach = "AICc",
  kernel   = "bisquare",
  adaptive = FALSE,        # vzdálenost v metrech
  dMat     = dMat
)
cat("Optimální bandwidth (fixed, metry):", round(bw_fixed / 1000, 1), "km\n")

# --- 6.4 Porovnání typů kernelů ----
cat("\n--- 6.4 Porovnání kernelů (adaptive, AICc) ---\n")
kernels <- c("bisquare", "gaussian", "exponential")
kernel_tbl <- data.frame()

for (k in kernels) {
  cat("  Testuji kernel:", k, "...\n")
  bw_tmp <- bw.gwr(formula_gwr, data = data_sp, approach = "AICc",
                    kernel = k, adaptive = TRUE, dMat = dMat)
  gwr_tmp <- gwr.basic(formula_gwr, data = data_sp, bw = bw_tmp,
                        kernel = k, adaptive = TRUE, dMat = dMat)
  kernel_tbl <- rbind(kernel_tbl, data.frame(
    kernel    = k,
    bandwidth = bw_tmp,
    AICc      = round(gwr_tmp$GW.diagnostic$AICc, 2),
    R2_gwr    = round(gwr_tmp$GW.diagnostic$gw.R2, 4),
    adjR2_gwr = round(gwr_tmp$GW.diagnostic$gwR2.adj, 4)
  ))
}
cat("\nPorovnání kernelů:\n")
print(kernel_tbl)
write.csv(kernel_tbl, "output/tables/05_kernel_comparison.csv", row.names = FALSE)

# Výběr nejlepšího kernelu (nejnižší AICc)
best_kernel <- kernel_tbl$kernel[which.min(kernel_tbl$AICc)]
best_bw     <- kernel_tbl$bandwidth[which.min(kernel_tbl$AICc)]
cat("\nNejlepší kernel (min AICc):", best_kernel,
    "| bandwidth:", best_bw, "\n")

# --- 6.5 Finální GWR model ----
cat("\n--- 6.5 Finální GWR model ---\n")
gwr_model <- gwr.basic(
  formula  = formula_gwr,
  data     = data_sp,
  bw       = best_bw,
  kernel   = best_kernel,
  adaptive = TRUE,
  dMat     = dMat
)
cat("\n")
print(gwr_model)

# --- 6.6 Extrakce výsledků ----
gwr_res <- as.data.frame(gwr_model$SDF)

data$local_R2        <- gwr_res$Local_R2
data$resid_gwr       <- gwr_res$residual
# Lokální koeficienty — top 3 dle t-hodnot z OLS
# OLS pořadí: VZDELANI_VYSOKO (t=10.8) > VZDELANI_STR_BEZ (t=10.0) > PODNIKATELE (t=9.3)
data$coef_VZDELANI_VYSOKO  <- gwr_res$VZDELANI_VYSOKO
data$coef_VZDELANI_STR_BEZ <- gwr_res$VZDELANI_STR_BEZ
data$coef_PODNIKATELE      <- gwr_res$PODNIKATELE

cat("\n--- Souhrn lokálního R² ---\n")
cat(sprintf("  Min:    %.4f\n", min(data$local_R2, na.rm = TRUE)))
cat(sprintf("  Medián: %.4f\n", median(data$local_R2, na.rm = TRUE)))
cat(sprintf("  Max:    %.4f\n", max(data$local_R2, na.rm = TRUE)))
cat(sprintf("  Průměr: %.4f\n", mean(data$local_R2, na.rm = TRUE)))
cat(sprintf("  Globální OLS R²: %.4f\n", r2))

# --- 6.7 Moran's I reziduí GWR (porovnání s OLS) ----
cat("\n--- Moran's I reziduí GWR ---\n")
moran_gwr <- moran.mc(data$resid_gwr, lw, nsim = 999, zero.policy = TRUE)
print(moran_gwr)
cat(sprintf("OLS rezidua: I = %.4f | p = %.4f\n",
            moran_mc$statistic, moran_mc$p.value))
cat(sprintf("GWR rezidua: I = %.4f | p = %.4f\n",
            moran_gwr$statistic, moran_gwr$p.value))
cat("Snížení autokorelace:",
    round(moran_mc$statistic - moran_gwr$statistic, 4), "\n")

# Uložení Moran srovnání
moran_both <- data.frame(
  model   = c("OLS", "GWR"),
  moran_I = round(c(moran_mc$statistic, moran_gwr$statistic), 4),
  p_value = round(c(moran_mc$p.value, moran_gwr$p.value), 4)
)
write.csv(moran_both, "output/tables/06_moran_ols_vs_gwr.csv", row.names = FALSE)

# --- 6.8 Mapy výsledků GWR (tmap v4 syntax) ----
tmap_mode("plot")

# Mapa lokálního R²
m_r2 <- tm_shape(data) +
  tm_polygons(
    fill        = "local_R2",
    fill.scale  = tm_scale_intervals(style = "quantile", n = 7,
                                      values = "brewer.greens"),
    fill.legend = tm_legend(title = "Lokální R²"),
    col         = NA,
    col_alpha   = 0
  ) +
  tm_title("GWR — lokální kvalita modelu (R²)")
tmap_save(m_r2, "output/maps/03_mapa_local_R2.png",
          width = 10, height = 7, dpi = 300)
cat("Uloženo: output/maps/03_mapa_local_R2.png\n")

# Mapa koeficientu VZDELANI_VYSOKO
m_c1 <- tm_shape(data) +
  tm_polygons(
    fill        = "coef_VZDELANI_VYSOKO",
    fill.scale  = tm_scale_intervals(style = "jenks", n = 7, midpoint = 0,
                                      values = "brewer.rd_bu"),
    fill.legend = tm_legend(title = "Lok. koef.\nVZDELANI_VYSOKO"),
    col = NA, col_alpha = 0
  ) +
  tm_title("GWR — lokální koeficient: podíl VŠ")
tmap_save(m_c1, "output/maps/04_coef_VZDELANI_VYSOKO.png",
          width = 10, height = 7, dpi = 300)

# Mapa koeficientu VZDELANI_STR_BEZ
m_c2 <- tm_shape(data) +
  tm_polygons(
    fill        = "coef_VZDELANI_STR_BEZ",
    fill.scale  = tm_scale_intervals(style = "jenks", n = 7, midpoint = 0,
                                      values = "brewer.rd_bu"),
    fill.legend = tm_legend(title = "Lok. koef.\nVZDELANI_STR_BEZ"),
    col = NA, col_alpha = 0
  ) +
  tm_title("GWR — lokální koeficient: vyučení bez maturity")
tmap_save(m_c2, "output/maps/05_coef_VZDELANI_STR_BEZ.png",
          width = 10, height = 7, dpi = 300)

# Mapa koeficientu PODNIKATELE
m_c3 <- tm_shape(data) +
  tm_polygons(
    fill        = "coef_PODNIKATELE",
    fill.scale  = tm_scale_intervals(style = "jenks", n = 7, midpoint = 0,
                                      values = "brewer.rd_bu"),
    fill.legend = tm_legend(title = "Lok. koef.\nPODNIKATELE"),
    col = NA, col_alpha = 0
  ) +
  tm_title("GWR — lokální koeficient: podnikatelé/OSVČ")
tmap_save(m_c3, "output/maps/06_coef_PODNIKATELE.png",
          width = 10, height = 7, dpi = 300)
cat("Uloženy mapy koeficientů (04–06)\n")

# --- 6.9 Boxplot: lokální GWR koeficienty vs globální OLS ----
ols_coefs <- coef(model_ols)
top3 <- c("VZDELANI_VYSOKO", "VZDELANI_STR_BEZ", "PODNIKATELE")

box_data <- data.frame()
for (v in top3) {
  box_data <- rbind(box_data, data.frame(
    prediktor = v,
    hodnota   = data[[paste0("coef_", v)]]
  ))
}

ols_lines <- data.frame(
  prediktor = top3,
  ols_val   = ols_coefs[top3]
)

p_box_coef <- ggplot(box_data, aes(x = prediktor, y = hodnota)) +
  geom_boxplot(fill = "#a6bddb", outlier.size = 0.4, outlier.alpha = 0.3) +
  geom_point(data = ols_lines, aes(x = prediktor, y = ols_val),
             color = "red", size = 3, shape = 18) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "gray40") +
  labs(
    title    = "Lokální koeficienty GWR vs. globální OLS (červený diamant)",
    subtitle = "Šíře boxplotu = prostorová variabilita vztahu",
    x        = NULL,
    y        = "Hodnota koeficientu"
  ) +
  theme_minimal(base_size = 12)
ggsave("output/figures/09_boxplot_gwr_vs_ols.png", p_box_coef,
       width = 8, height = 5, dpi = 300)
cat("Uloženo: output/figures/09_boxplot_gwr_vs_ols.png\n")

# --- 6.10 Shrnutí Kroku 6 ----
cat("\n=== SHRNUTÍ KROKU 6 ===\n")
cat(sprintf("Kernel: %s | Adaptive bandwidth: %d sousedů\n",
            best_kernel, best_bw))
cat(sprintf("GWR R²:       %.4f | OLS R²:  %.4f\n",
            gwr_model$GW.diagnostic$gw.R2, r2))
cat(sprintf("GWR adj. R²:  %.4f | OLS adj.R²: %.4f\n",
            gwr_model$GW.diagnostic$gwR2.adj, r2_adj))
cat(sprintf("GWR AICc:     %.2f  | OLS AIC:  %.2f\n",
            gwr_model$GW.diagnostic$AICc, AIC(model_ols)))
cat(sprintf("Moran I GWR:  %.4f  | OLS: %.4f\n",
            moran_gwr$statistic, moran_mc$statistic))

# =============================================================================
# KROK 7: EXPORT DO GPKG (pro ArcGIS Pro)
# =============================================================================
cat("\n=== KROK 7: EXPORT DO GPKG ===\n")

# Ponechat jen relevantní sloupce
export_cols <- c("kod_obce", "nazev_obce", "pirati_pct",
                  "resid_ols", "fitted_ols",
                  "local_R2", "resid_gwr",
                  "coef_VZDELANI_VYSOKO", "coef_VZDELANI_STR_BEZ",
                  "coef_PODNIKATELE",
                  prediktory)

# sf automaticky přenáší geometrii — stačí vybrat atributové sloupce
# (není třeba explicitně přidávat geometry sloupec)
data_export <- data[, export_cols]   # sf zachová geometrii automaticky

# Ověření: obsahuje geometrii?
cat("Geometry type:", class(st_geometry(data_export)), "\n")
cat("Počet sloupců:", ncol(data_export), "\n")

st_write(data_export,
         "data/processed/pirati_gwr_results.gpkg",
         layer        = "gwr_results",
         delete_layer = TRUE)
cat("Exportováno: data/processed/pirati_gwr_results.gpkg\n")
cat("Obsah: volební data + OLS rezidua + GWR koeficienty + lokální R²\n")
cat("→ Načtěte v ArcGIS Pro pro finální mapové výstupy.\n")

cat("\n=== CELÝ WORKFLOW DOKONČEN ===\n")
cat("Shrnutí výsledků:\n")
cat(sprintf("  OLS R² = %.4f  |  GWR R² = %.4f  (+%.1f p.p.)\n",
            r2, gwr_model$GW.diagnostic$gw.R2,
            (gwr_model$GW.diagnostic$gw.R2 - r2) * 100))
cat(sprintf("  OLS AIC = %.1f  |  GWR AICc = %.1f\n",
            AIC(model_ols), gwr_model$GW.diagnostic$AICc))
cat(sprintf("  Moran's I: OLS = %.4f → GWR = %.4f (eliminováno)\n",
            moran_mc$statistic, moran_gwr$statistic))
