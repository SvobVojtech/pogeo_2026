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
