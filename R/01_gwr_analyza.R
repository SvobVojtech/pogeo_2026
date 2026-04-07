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
