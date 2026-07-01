
# ==============================================================================
# iNaturalist Bioblitz Slideshow Generator - Core Script
# ==============================================================================
# This script fetches observations from an iNaturalist bioblitz project,
# downloads photos and creates maps, then composes a reveal.js HTML slideshow.
#
# USAGE:
#   - Run directly in RStudio by editing the CONFIGURATION section below, OR
#   - Run via the companion Shiny app (bioblitz_shiny_app.R) which passes
#     parameters automatically and provides a live progress dashboard.
#
# CHANGES IN V2:
#   - Added bioblitz_name parameter (replaces hardcoded "Walpole Wilderness")
#   - Welcome slide is now a single slide: logo top-right, title + date range
#   - Year is appended automatically to bioblitz title from observation dates
#   - Date range shown below welcome text (derived from data or set manually)
#
# CHANGES IN V3:
#   - HQ map label doubled in size
#   - Scale bar text and symbols enlarged (~2x); thicker bar
#   - Tracks now drawn dashed and at 75% saturation
#   - Collage polaroid borders halved in width
#   - Collage title omits the word "Bioblitz" (e.g. "Isn't the Walpole
#     Wilderness Amazing?")
#   - Four rusty-red statistic circles added along the bottom of the collage
#     (participants, days, observations, species) with white text
#   - Statistic circles overlay the photos (photos fill the full canvas); circle
#     text is truly centred with a wider gap between number and label
#   - Taxon label and a Track/Watercourse legend now sit BELOW the map,
#     left-aligned to the map and lined up with the photo caption rows for
#     left/right symmetry; legend enlarged (~3x)
#   - Taxon label and legend are now BAKED into each slide image (not HTML
#     overlays), so they always align with the photo captions. The taxon icon
#     is a simple drawn marker (leaf, mushroom, bird, fish, spider, paw, etc.)
#     instead of an emoji; legend shows the actual dashed/solid line styles.
#   - Photos always scale to COVER the 880x600 cell (undersized ones enlarged),
#     so every photo fills its frame at a consistent size.
#   - Maps now use a fixed 880:600 window centred on the HQ-observation midpoint,
#     snapped to a few quantised zoom levels, so every map fills its cell at a
#     consistent size while still zooming out for distant observations. The base
#     map covers every observation in the project, so any random sample is fully
#     covered and the cached base map stays valid across runs.
#   - Taxon icons can use cached PhyloPic silhouettes (fetched once, then reused
#     from taxon_icon_dir with no API call; drop-in PNGs also supported). Drawn
#     markers remain the automatic fallback when an icon isn't available.
# ==============================================================================

cat("=== SCRIPT STARTING ===\n\n")

# ==============================================================================
# CONFIGURATION - EDIT THESE SETTINGS
# ==============================================================================

# --- Project Settings ---
project_slug <- "walpole-wilderness-bioblitz-2025"  # Your iNaturalist project slug
n_photos     <- 50                                  # Number of photos in slideshow
bioblitz_logo <- "Walpole-Wilderness-bioblitz.jpg"  # Logo filename (in project root folder)

# --- Bioblitz Identity ---
bioblitz_name <- "Walpole Wilderness Bioblitz"
# The name of your bioblitz as you want it to appear on the welcome slide.
# The year will be appended automatically from the observation data
# (e.g. "Walpole Wilderness Bioblitz 2025").

# --- Date Display Settings ---
bioblitz_dates_auto  <- TRUE   # TRUE = derive date range from observation data (recommended)
                               # FALSE = use the manual dates set below
bioblitz_dates_start <- NULL   # Manual start date string, e.g. "2025-11-15"
                               # Only used when bioblitz_dates_auto = FALSE
bioblitz_dates_end   <- NULL   # Manual end date string, e.g. "2025-11-17"
                               # Only used when bioblitz_dates_auto = FALSE
# NOTE on manual dates: useful when the project contains outlier observations
# (e.g. old records added after the event) that would otherwise skew the
# automatically-derived date range shown on the welcome slide.

# --- HQ Location (for maps) ---
hq_lon <- 116.634398  # Headquarters longitude
hq_lat <- -34.992854  # Headquarters latitude

# --- Diversity Settings ---
max_obs_per_observer_pct <- 0.15  # Max 15% of photos from any single observer
max_obs_per_observer_abs <- 5     # Absolute max photos per observer (takes precedence if lower)
max_plants_pct           <- 0.40  # Max 50% of photos can be plants (Plantae)

# --- Random Seed Settings ---
use_random_seed <- TRUE   # TRUE = different selection each run, FALSE = use R's random state
random_seed     <- NULL   # Set to a number (e.g., 42) for reproducible results, NULL for random

# --- Run Mode ---
fresh_run             <- FALSE   # TRUE = delete all old artifacts and start fresh
fetch_all_observations <- TRUE  # TRUE = fetch all obs from project, FALSE = fetch subset
cache_observations    <- TRUE   # TRUE = cache fetched observations for faster reruns
use_incremental_fetch <- TRUE   # TRUE = only fetch NEW observations since last run (much faster!)
# NOTE: For daily updates, set fresh_run=FALSE to use incremental fetch

# --- Force Rebuild Options ---
# See the Shiny app Advanced Options panel for detailed explanations of each.
force_rebuild_base_map <- FALSE  #TRUE = rebuild satellite base map even if cached
force_rebuild_maps     <- TRUE  # TRUE = rebuild all individual observation maps
force_rebuild_slides   <- FALSE  # TRUE = rebuild all slide compositions
force_rebuild_collage  <- TRUE   # TRUE = rebuild the polaroid collage image
skip_osm_overlays      <- FALSE  # TRUE = skip OpenStreetMap roads/waterways (faster)

# --- Map Settings ---
base_map_zoom   <- 14    # Zoom level for satellite imagery (13-15 recommended)
default_dist_m  <- 4000  # Minimum map half-width (m) = the closest/most-zoomed-in level.
                         # Each map is an 880:600 window centred on the HQ-observation
                         # midpoint, sized so both are visible; this is the floor size.
map_zoom_n      <- 4     # Number of discrete (quantised) zoom levels. Each map snaps to
                         # the smallest level that still frames both HQ and the observation,
                         # so the scale steps in buckets instead of varying continuously.
map_pad_m       <- 1000  # Margin (m) kept between HQ/observation and the window edge.
map_margin_frac <- 0.20  # Fractional edge margin (0-0.4): keep HQ and the observation
                         # within the inner (1 - this) of the window so neither sits on
                         # the very edge. Higher = more margin = slightly more zoomed out.

# --- Slideshow Settings ---
auto_advance_ms      <- 7000   # Auto-advance time in milliseconds (7000 = 7 seconds)
auto_slide_stoppable <- TRUE   # Allow user to stop auto-advance
slideshow_loop       <- TRUE   # Loop slideshow when it reaches the end
max_collage          <- 25     # Maximum photos in final collage
create_pdf           <- FALSE  # Set to FALSE to skip PDF creation (useful for large slideshows)
pdf_size_limit_mb    <- 50     # Skip PDF if estimated size exceeds this (0 = no limit)

# --- Taxon Icon Settings ---
# Palette, icon-cache config, and silhouette functions are shared with the
# Data Dive via the style file (Wes Anderson palette; PhyloPic silhouettes).
# It self-installs wesanderson/magick. Override any icon setting AFTER this
force_rebuild_icons <- TRUE # line if needed (e.g. once after a palette change).
source("bioblitz_style.R")

# --- Output Settings ---
out_dir        <- "outputs/walpole_wilderness_bioblitz_2025_slideshow"  # Output directory
diagnostic_mode <- TRUE  # Print detailed progress messages

# ==============================================================================
# END OF CONFIGURATION - DO NOT EDIT BELOW THIS LINE
# ==============================================================================

cat("=== CONFIGURATION LOADED ===\n")
cat("Project:", project_slug, "\n")
cat("Bioblitz name:", bioblitz_name, "\n")
cat("Target photos:", n_photos, "\n")
cat("Observer diversity: max", max_obs_per_observer_pct * 100, "% per observer\n")
cat("Plant diversity: max", max_plants_pct * 100, "% plants\n")
cat("Run mode:", if(fresh_run) "FRESH" else "INCREMENTAL", "\n")
cat("Fetch mode:", if(use_incremental_fetch && !fresh_run) "INCREMENTAL (new obs only)" else "FULL", "\n")

# Handle NA passed from Shiny numeric input (empty field = NA, not NULL)
if (!is.null(random_seed) && !is.na(random_seed) && random_seed == "NULL") random_seed <- NULL
if (identical(random_seed, NA) || identical(random_seed, NA_real_) || identical(random_seed, NA_integer_)) random_seed <- NULL

# Generate a random seed if requested but none provided
if (use_random_seed && is.null(random_seed)) {
  # Keep within safe integer range (1 to 2^31 - 1) to avoid as.integer() overflow
  random_seed <- sample.int(.Machine$integer.max, 1)
  cat("Generated random seed:", random_seed, "\n")
}

if (!is.null(random_seed)) {
  set.seed(random_seed)
  cat("Random seed set to:", random_seed, "\n")
} else {
  cat("No random seed (using R's current state)\n")
}
cat("\n")

# Setup directories
photos_dir   <- file.path(out_dir, "photos")
maps_dir     <- file.path(out_dir, "maps")
compo_dir    <- file.path(out_dir, "slides")
base_map_dir <- file.path(out_dir, "base_map_cache")

dir.create(out_dir,        TRUE, FALSE)
dir.create(photos_dir,     TRUE, FALSE)
dir.create(maps_dir,       TRUE, FALSE)
dir.create(compo_dir,      TRUE, FALSE)
dir.create(base_map_dir,   TRUE, FALSE)

# Clean up if fresh run requested
if (fresh_run) {
  cat("FRESH RUN: Cleaning up old artifacts...\n")
  if (dir.exists(photos_dir)) unlink(photos_dir, recursive = TRUE)
  if (dir.exists(maps_dir))   unlink(maps_dir,   recursive = TRUE)
  if (dir.exists(compo_dir))  unlink(compo_dir,  recursive = TRUE)

  collage_file_cleanup <- file.path(out_dir, "collage.png")
  if (file.exists(collage_file_cleanup)) unlink(collage_file_cleanup)

  obs_cache_file      <- file.path(out_dir, "observations_cache.rds")
  photo_manifest_file <- file.path(out_dir, "photo_manifest.rds")
  if (file.exists(obs_cache_file))      unlink(obs_cache_file)
  if (file.exists(photo_manifest_file)) unlink(photo_manifest_file)

  if (!force_rebuild_base_map && dir.exists(base_map_dir)) {
    cat("  Keeping base map cache\n")
  }

  dir.create(photos_dir, TRUE, FALSE)
  dir.create(maps_dir,   TRUE, FALSE)
  dir.create(compo_dir,  TRUE, FALSE)
  cat("  Old artifacts removed\n\n")
}

# ==============================================================================
# LOAD PACKAGES
# ==============================================================================

cat("Loading packages...\n")
req <- c("httr2","jsonlite","dplyr","purrr","tidyr","stringr","lubridate",
         "janitor","glue","readr","tibble","ggplot2","sf",
         "maptiles","terra","tidyterra","osmdata","magick","ggspatial","wesanderson")
opt <- c("quarto","pagedown","rstudioapi")

to_install <- setdiff(c(req, opt), rownames(installed.packages()))
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")
invisible(lapply(req, library, character.only = TRUE))
cat("Packages loaded\n\n")

# rphylopic is only needed if we are fetching taxon silhouette icons. Install it
# lazily so users who don't want it (or are offline) aren't forced to.
if (isTRUE(use_taxon_icons) && isTRUE(fetch_taxon_icons) &&
    !requireNamespace("rphylopic", quietly = TRUE)) {
  cat("Installing rphylopic (for taxon silhouette icons)...\n")
  tryCatch(install.packages("rphylopic", repos = "https://cloud.r-project.org"),
           error = function(e) cat("  rphylopic install failed; drawn markers will be used.\n"))
}

`%||%` <- function(a, b) if (is.null(a)) b else a
url_path <- function(...) gsub("\\\\", "/", file.path(...))
options(terra.memfrac = 0.8)
if (isTRUE(sf::sf_use_s2())) sf::sf_use_s2(FALSE)

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

cat("Defining helper functions...\n")

inat_get <- function(path, query_list = list()) {
  req <- request(paste0("https://api.inaturalist.org/v1/", path))
  for (name in names(query_list)) {
    value <- query_list[[name]]
    if (grepl("\\[\\]$", name)) {
      req <- req_url_query(req, !!name := value, .multi = "comma")
    } else {
      req <- req_url_query(req, !!name := value)
    }
  }
  req |>
    req_user_agent("bioblitz-slideshow") |>
    req_perform() |>
    resp_body_json(simplifyVector = FALSE)
}

best_photo_url <- function(photo_obj, size = c("large","medium")) {
  u <- if (!is.null(photo_obj$url)) photo_obj$url else NA_character_
  if (is.null(u) || is.na(u)) return(NA_character_)
  sub("/[A-Za-z]+\\.(jpg|png)$", paste0("/", size[1], ".\\1"), u)
}

flatten_obs <- function(o) {
  tax    <- if (!is.null(o$taxon))  o$taxon  else list()
  user   <- if (!is.null(o$user))   o$user   else list()
  phot   <- if (!is.null(o$photos)) o$photos else list()
  coords <- if (!is.null(o$geojson) && !is.null(o$geojson$coordinates))
              o$geojson$coordinates else c(NA_real_, NA_real_)

  tibble::tibble(
    obs_id       = if (!is.null(o$id))          o$id          else NA_integer_,
    observed_on  = if (!is.null(o$observed_on)) o$observed_on else NA_character_,
    observer     = if (!is.null(user$name))     user$name     else
                   if (!is.null(user$login))    user$login    else NA_character_,
    sci_name     = if (!is.null(tax$name))                     tax$name                     else NA_character_,
    common_name  = if (!is.null(tax$preferred_common_name))    tax$preferred_common_name    else NA_character_,
    iconic_taxon = if (!is.null(tax$iconic_taxon_name))        tax$iconic_taxon_name        else NA_character_,
    longitude    = suppressWarnings(as.numeric(coords[[1]])),
    latitude     = suppressWarnings(as.numeric(coords[[2]])),
    photos_list  = list(phot)
  )
}

dl_file <- function(url, path) {
  try({
    resp <- request(url) |> req_user_agent("bioblitz-slideshow") |> req_perform()
    writeBin(resp_body_raw(resp), path)
    TRUE
  }, silent = TRUE)
}

fetch_obs <- function(fetch_all = TRUE) {
  page     <- 1
  per_page <- 200
  obs_pool <- list()

  cat("Fetching", if(fetch_all) "ALL" else "subset of", "observations...\n")

  if (fetch_all) {
    q_count <- list(project_id = project_slug, per_page = 1, fields = "id")
    q_count[["has[]"]] <- "photos"

    res_count    <- inat_get("observations", q_count)
    total_results <- res_count$total_results
    n_pages       <- ceiling(total_results / per_page)

    cat("  Total observations:", total_results, "\n")
    cat("  Pages to fetch:", n_pages, "\n")

    for (page in 1:n_pages) {
      if (page %% 5 == 1 || page == n_pages)
        cat("  Fetching pages", page, "to", min(page + 4, n_pages), "of", n_pages, "...\n")

      q <- list(
        project_id = project_slug, per_page = per_page, page = page,
        order = "desc", order_by = "id",
        fields = paste0("id,observed_on,geojson,user.login,user.name,",
                        "taxon.name,taxon.preferred_common_name,taxon.iconic_taxon_name,photos.url")
      )
      q[["has[]"]] <- "photos"

      res   <- inat_get("observations", q)
      if (!length(res$results)) break

      chunk <- purrr::map_dfr(res$results, flatten_obs)
      if (nrow(chunk) > 0) obs_pool[[length(obs_pool) + 1]] <- chunk
    }
  } else {
    repeat {
      q <- list(
        project_id = project_slug, per_page = per_page, page = page,
        order = "desc", order_by = "id",
        fields = paste0("id,observed_on,geojson,user.login,user.name,",
                        "taxon.name,taxon.preferred_common_name,taxon.iconic_taxon_name,photos.url")
      )
      q[["has[]"]] <- "photos"

      if (page %% 5 == 1) cat("  Page", page, "...\n")

      res   <- inat_get("observations", q)
      if (!length(res$results)) break

      chunk <- purrr::map_dfr(res$results, flatten_obs)
      if (!nrow(chunk)) break

      obs_pool[[length(obs_pool) + 1]] <- chunk

      if (length(res$results) < per_page) break
      if (!fetch_all && page >= 3) break
      page <- page + 1
      if (page > 100) break
    }
  }

  obs <- dplyr::bind_rows(obs_pool) |> janitor::clean_names()
  cat("  Fetched", nrow(obs), "observations\n")
  obs
}

cat("Helper functions defined\n\n")

# ==============================================================================
# FETCH OBSERVATIONS
# ==============================================================================

cat("=== FETCHING OBSERVATIONS ===\n")

obs_cache_file  <- file.path(out_dir, "observations_cache.rds")
fetch_state_file <- file.path(out_dir, "fetch_state.rds")

existing_obs    <- NULL
last_fetch_time <- NULL

if (cache_observations && file.exists(obs_cache_file) && !fresh_run) {
  existing_obs <- readRDS(obs_cache_file)
  cat("Loaded", nrow(existing_obs), "cached observations\n")

  if (file.exists(fetch_state_file)) {
    fetch_state     <- readRDS(fetch_state_file)
    last_fetch_time <- fetch_state$last_fetch_time
    cat("Last fetch:", last_fetch_time, "\n")
  }
}

do_incremental <- use_incremental_fetch && !fresh_run &&
                  !is.null(existing_obs) && !is.null(last_fetch_time)

if (do_incremental) {
  cat("\n=== INCREMENTAL FETCH (new observations only) ===\n")
  cat("This will be much faster than a full fetch!\n")

  new_obs <- tryCatch({
    page     <- 1
    per_page <- 200
    obs_pool <- list()
    cat("Fetching observations updated since", last_fetch_time, "...\n")

    repeat {
      q <- list(
        project_id    = project_slug, per_page = per_page, page = page,
        order         = "desc", order_by = "created_at",
        updated_since = last_fetch_time,
        fields        = paste0("id,observed_on,geojson,user.login,user.name,",
                               "taxon.name,taxon.preferred_common_name,taxon.iconic_taxon_name,photos.url")
      )
      q[["has[]"]] <- "photos"

      res <- inat_get("observations", q)
      if (!length(res$results)) break

      chunk <- purrr::map_dfr(res$results, flatten_obs)
      if (nrow(chunk) > 0) obs_pool[[length(obs_pool) + 1]] <- chunk

      if (length(res$results) < per_page) break
      page <- page + 1
      if (page > 50) break
    }

    if (length(obs_pool) > 0)
      dplyr::bind_rows(obs_pool) |> janitor::clean_names()
    else
      data.frame()
  }, error = function(e) {
    cat("Incremental fetch failed:", conditionMessage(e), "\n")
    cat("Falling back to full fetch...\n")
    NULL
  })

  if (!is.null(new_obs) && nrow(new_obs) > 0) {
    cat("  Found", nrow(new_obs), "new/updated observations\n")
    obs <- bind_rows(existing_obs, new_obs) %>% distinct(obs_id, .keep_all = TRUE)
    cat("  Total after merge:", nrow(obs), "observations\n")
    cat("  Time saved: Did not re-download", nrow(existing_obs) - nrow(new_obs), "existing observations!\n")
  } else if (!is.null(new_obs)) {
    cat("  No new observations found\n")
    obs <- existing_obs
  } else {
    obs <- fetch_obs(fetch_all = fetch_all_observations)
  }

} else {
  if (fresh_run || is.null(existing_obs)) {
    cat("\n=== FULL FETCH ===\n")
  } else {
    cat("\n=== USING CACHED OBSERVATIONS (set use_incremental_fetch=TRUE to update) ===\n")
  }

  if (!is.null(existing_obs) && !fresh_run) {
    obs <- existing_obs
    cat("Using", nrow(obs), "cached observations\n")
  } else {
    obs <- fetch_obs(fetch_all = fetch_all_observations)
  }
}

if (cache_observations && nrow(obs) > 0) {
  saveRDS(obs, obs_cache_file)
  fetch_state <- list(
    last_fetch_time = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    total_obs       = nrow(obs)
  )
  saveRDS(fetch_state, fetch_state_file)
  cat("Cache updated\n")
}

if (nrow(obs) > 0) {
  cat("\nRandomizing observation pool")
  if (!is.null(random_seed)) cat(" (seed:", random_seed, ")")
  cat("...\n")
  obs <- obs[sample(nrow(obs)), ]
}

if (!nrow(obs)) stop("No observations found")

cat("\n=== POOL STATISTICS ===\n")
cat("Total:", nrow(obs), "\n")
observer_counts <- obs %>% count(observer) %>% arrange(desc(n))
cat("Unique observers:", nrow(observer_counts), "\n")
cat("Top 10:\n")
print(head(observer_counts, 10))

obs_photos <- obs %>%
  mutate(photo_url = purrr::map_chr(photos_list, function(pl) {
    if (length(pl)) best_photo_url(pl[[1]]) else NA_character_
  })) %>%
  filter(!is.na(photo_url)) %>%
  mutate(iconic_taxon = ifelse(is.na(iconic_taxon) | iconic_taxon == "", "Unknown", iconic_taxon))

cat("With photos:", nrow(obs_photos), "\n\n")

# ==============================================================================
# SAMPLING WITH DIVERSITY
# ==============================================================================

cat("=== SAMPLING ===\n")

n_target <- min(n_photos, nrow(obs_photos))

max_obs_per_observer_pct_calc <- max(1, floor(n_target * max_obs_per_observer_pct))
max_obs_per_observer          <- min(max_obs_per_observer_pct_calc, max_obs_per_observer_abs)
max_plants                    <- floor(n_target * max_plants_pct)

cat("Target:", n_target, "\n")
cat("Observer limits:\n")
cat("  - Percentage-based:", max_obs_per_observer_pct_calc, "(", max_obs_per_observer_pct * 100, "% of", n_target, ")\n")
cat("  - Absolute maximum:", max_obs_per_observer_abs, "\n")
cat("  - ACTUAL LIMIT USED:", max_obs_per_observer, "(using the lower of the two)\n")
cat("Max plants:", max_plants, "\n")
cat("Random seed being used:", if(!is.null(random_seed)) random_seed else "none", "\n\n")

plants_df <- dplyr::filter(obs_photos, iconic_taxon == "Plantae")
other_df  <- dplyr::filter(obs_photos, iconic_taxon != "Plantae")
all_df    <- bind_rows(plants_df, other_df)

observer_counts <- all_df %>% count(observer) %>% arrange(n)
cat("Observer processing order before randomization:\n")
print(head(observer_counts, 5))
observer_counts <- observer_counts[sample(nrow(observer_counts)), ]
cat("\nObserver processing order after randomization:\n")
print(head(observer_counts, 5))

sampled_list <- list()
n_sampled    <- 0

for (obs_name in observer_counts$observer) {
  if (n_sampled >= n_target) break

  obs_pool  <- all_df %>% filter(observer == obs_name)
  n_to_take <- min(nrow(obs_pool), max_obs_per_observer, n_target - n_sampled)

  if (n_to_take > 0) {
    selected <- obs_pool %>% slice_sample(n = n_to_take)
    sampled_list[[length(sampled_list) + 1]] <- selected
    n_sampled <- n_sampled + n_to_take

    if (diagnostic_mode && n_sampled <= n_target)
      cat("  Selected", n_to_take, "from", obs_name, "(total now:", n_sampled, ")\n")
  }
}

sampled <- bind_rows(sampled_list)
cat("\nSelected observation IDs (first 10):", paste(head(sampled$obs_id, 10), collapse = ", "), "\n")

n_plants <- sum(sampled$iconic_taxon == "Plantae")

if (n_plants > max_plants) {
  cat("Adjusting plants:", n_plants, "->", max_plants, "\n")

  sampled_plants <- sampled %>% filter(iconic_taxon == "Plantae") %>% slice_sample(n = max_plants)
  sampled_other  <- sampled %>% filter(iconic_taxon != "Plantae")
  sampled        <- bind_rows(sampled_other, sampled_plants)

  n_removed <- n_plants - max_plants
  if (n_removed > 0 && nrow(sampled) < n_target) {
    cat("Backfilling", n_removed, "slots with non-plants...\n")

    already_selected_ids  <- sampled$obs_id
    available_nonplants   <- other_df %>% filter(!obs_id %in% already_selected_ids)

    if (nrow(available_nonplants) > 0) {
      backfill_needed <- min(n_removed, n_target - nrow(sampled))
      backfill_list   <- list()

      for (i in 1:backfill_needed) {
        current_counts    <- sampled %>% count(observer)
        eligible_observers <- available_nonplants %>%
          left_join(current_counts, by = "observer") %>%
          mutate(n = ifelse(is.na(n), 0, n)) %>%
          filter(n < max_obs_per_observer)

        if (nrow(eligible_observers) > 0) {
          backfill_obs <- eligible_observers %>% slice_sample(n = 1)
          backfill_list[[length(backfill_list) + 1]] <- backfill_obs %>% select(-n)
          sampled <- bind_rows(sampled, backfill_obs %>% select(-n))
        }
      }

      if (length(backfill_list) > 0)
        cat("  Added", length(backfill_list), "non-plant observations\n")
    }
  }
}

cat("\nFinal sample size:", nrow(sampled), "\n")
cat("\nFinal sample:\n")
observer_breakdown <- sampled %>% count(observer) %>% arrange(desc(n))
print(observer_breakdown)
cat("\nObserver diversity check:\n")
cat("  Max photos from one observer:", max(observer_breakdown$n), "\n")
cat("  Number of unique observers:",   nrow(observer_breakdown), "\n")
cat("  Target max per observer was:",  max_obs_per_observer, "\n")
print(sampled %>% count(iconic_taxon))

# ==============================================================================
# MAP WINDOWS & QUANTISED ZOOM
# ==============================================================================
# Each observation map is a fixed-aspect (880:600) window centred on the midpoint
# between HQ and the observation, sized so both fall inside with a margin. The
# size snaps to one of a few discrete (quantised) zoom levels, so every map fills
# its cell at a consistent aspect while still zooming out for distant points.
# The base map then covers every observation in the project (not just this run's
# sample), which guarantees that every window is fully covered (no blank edges
# when cropping) and lets the cached base map be reused across runs.

cat("\n=== MAP WINDOWS & ZOOM LEVELS ===\n")

map_cell_aspect <- 880 / 600   # width:height of the map cell (must match compose_slide)

# HQ in EPSG:3857 (metres)
hq_pt_m <- sf::st_transform(sf::st_sfc(sf::st_point(c(hq_lon, hq_lat)), crs = 4326), 3857)
hq_xy   <- sf::st_coordinates(hq_pt_m)
hq_x_m  <- hq_xy[1]; hq_y_m <- hq_xy[2]

# All sampled observation coordinates in EPSG:3857
.coords_ll <- sampled %>% dplyr::filter(!is.na(longitude), !is.na(latitude))
.obs_pts_m <- sf::st_transform(
  sf::st_as_sf(.coords_ll, coords = c("longitude", "latitude"), crs = 4326), 3857)
.obs_xy    <- sf::st_coordinates(.obs_pts_m)
obs_x_all  <- .obs_xy[, 1]; obs_y_all <- .obs_xy[, 2]

# Minimum half-width needed to frame a point pair (obs + HQ) at the cell aspect.
# Both points sit at +/- dx/2, +/- dy/2 from the midpoint. We keep them inside a
# fraction (1 - map_margin_frac) of the half-extent so neither lands on the edge,
# plus a small absolute pad.
hw_needed_fun <- function(ox, oy) {
  dx <- abs(ox - hq_x_m); dy <- abs(oy - hq_y_m)
  k  <- 1 / (1 - map_margin_frac)
  max(k * (dx / 2) + map_pad_m, map_cell_aspect * (k * (dy / 2) + map_pad_m))
}

hw_min        <- default_dist_m                       # closest / most zoomed-in level
hw_needed_all <- mapply(hw_needed_fun, obs_x_all, obs_y_all)
hw_top        <- max(hw_min, max(hw_needed_all, na.rm = TRUE))

# Quantised half-width levels, log-spaced (zoom is multiplicative) from the floor
# to the size needed by the most distant observation.
if (hw_top <= hw_min * 1.0001 || map_zoom_n <= 1) {
  map_zoom_levels <- hw_min
} else {
  map_zoom_levels <- exp(seq(log(hw_min), log(hw_top), length.out = map_zoom_n))
}
cat("Zoom levels (half-width m):", paste(round(map_zoom_levels), collapse = ", "), "\n")

# Window for one observation: snap up to the smallest level that frames both points.
compute_map_window <- function(obs_x, obs_y) {
  target <- max(hw_needed_fun(obs_x, obs_y), hw_min)
  hw     <- map_zoom_levels[which(map_zoom_levels >= target - 1e-6)][1]
  if (is.na(hw)) hw <- max(map_zoom_levels)
  hh     <- hw / map_cell_aspect
  cx     <- (obs_x + hq_x_m) / 2
  cy     <- (obs_y + hq_y_m) / 2
  c(xmin = cx - hw, xmax = cx + hw, ymin = cy - hh, ymax = cy + hh)
}

# Scale-bar geometry for a map cell map_px_w pixels wide. Converts the window's
# web-mercator span to ground metres (x cos(lat)), picks a "nice" round length
# (~25% of the cell), and returns its pixel length and label. Drawn on the slide
# canvas in compose_slide, not inside the map.
map_px_w <- 880
map_scale_for <- function(lon, lat) {
  tryCatch({
    obs_m  <- sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(c(lon, lat)), crs = 4326), 3857))
    win    <- compute_map_window(obs_m[1], obs_m[2])
    span_x <- as.numeric(win["xmax"] - win["xmin"])
    lat_c  <- (lat + hq_lat) / 2
    m_per_px <- (span_x * cos(lat_c * pi / 180)) / map_px_w
    target_m <- 0.25 * map_px_w * m_per_px
    nice <- c(50, 100, 200, 250, 500, 1000, 2000, 5000, 10000, 20000, 50000)
    pick <- nice[nice <= target_m]
    nm   <- if (length(pick)) max(pick) else min(nice)
    list(px = as.integer(round(nm / m_per_px)),
         label = if (nm >= 1000) paste0(nm / 1000, " km") else paste0(nm, " m"))
  }, error = function(e) list(px = NA_integer_, label = ""))
}

# Base-map extent: cover every possible per-observation window over the WHOLE
# fetched set (not just this run's random sample), so any sample is fully covered
# and the cached base map stays valid across runs. Each window is centred on the
# HQ-observation midpoint with half-width <= the largest any sample could need, so
# we bound the union using the most distant observation in the project.
.allcoords  <- obs %>% dplyr::filter(!is.na(longitude), !is.na(latitude))
.all_m      <- sf::st_transform(
  sf::st_as_sf(.allcoords, coords = c("longitude", "latitude"), crs = 4326), 3857)
.all_xy     <- sf::st_coordinates(.all_m)
.all_ox     <- .all_xy[, 1]; .all_oy <- .all_xy[, 2]
hw_proj_all <- max(hw_min, max(mapply(hw_needed_fun, .all_ox, .all_oy), na.rm = TRUE))
hh_proj_all <- hw_proj_all / map_cell_aspect
.mids_x     <- (.all_ox + hq_x_m) / 2
.mids_y     <- (.all_oy + hq_y_m) / 2
.wpad       <- 200
windows_bbox_3857 <- c(
  xmin = min(.mids_x) - hw_proj_all - .wpad,
  ymin = min(.mids_y) - hh_proj_all - .wpad,
  xmax = max(.mids_x) + hw_proj_all + .wpad,
  ymax = max(.mids_y) + hh_proj_all + .wpad
)
cat("Base-map extent set to cover all", length(.all_ox), "project observations\n")

# ==============================================================================
# BUILD BASE MAP
# ==============================================================================

cat("\n=== BASE MAP ===\n")

base_map_file <- file.path(base_map_dir, "satellite_base.tif")
osm_data_file <- file.path(base_map_dir, "osm_overlays.rds")

if (file.exists(base_map_file) && file.exists(osm_data_file) && !force_rebuild_base_map) {
  cat("Loading cached base map\n")
  sat_raster   <- terra::rast(base_map_file)
  overlay_data <- readRDS(osm_data_file)
  roads_full      <- overlay_data$roads
  waterways_full  <- overlay_data$waterways

  ext <- terra::ext(sat_raster)
  cat("  Satellite raster loaded\n")
  cat("    Extent (EPSG:3857):\n")
  cat("      X:", ext$xmin, "to", ext$xmax, "\n")
  cat("      Y:", ext$ymin, "to", ext$ymax, "\n")
  cat("    Dimensions:", terra::nrow(sat_raster), "x", terra::ncol(sat_raster), "\n")
  cat("    Layers:", terra::nlyr(sat_raster), "\n")
  if (!is.null(roads_full))     cat("  Roads:",     nrow(roads_full),     "features\n")
  if (!is.null(waterways_full)) cat("  Waterways:", nrow(waterways_full), "features\n")

  preview_path <- file.path(base_map_dir, "preview_full_project_map.png")
  if (!file.exists(preview_path)) {
    cat("  Creating diagnostic preview map...\n")
    tryCatch({
      ext <- terra::ext(sat_raster)
      p_preview <- ggplot() +
        tidyterra::geom_spatraster_rgb(data = sat_raster) +
        coord_sf(crs = 3857, xlim = c(ext$xmin, ext$xmax), ylim = c(ext$ymin, ext$ymax), expand = FALSE) +
        {if (!is.null(waterways_full) && nrow(waterways_full) > 0) list(
           geom_sf(data = waterways_full, colour = "#4FA3FF", linewidth = 0.5, alpha = 0.7, inherit.aes = FALSE),
           annotate("text", x = ext$xmin + (ext$xmax - ext$xmin) * 0.02, y = ext$ymax - (ext$ymax - ext$ymin) * 0.05,
                    label = paste("Waterways:", nrow(waterways_full)), hjust = 0, colour = "#4FA3FF", size = 4, fontface = "bold")
        )} +
        {if (!is.null(roads_full) && nrow(roads_full) > 0) list(
           geom_sf(data = roads_full, colour = "#B0B0B0", linewidth = 0.4, alpha = 0.7, inherit.aes = FALSE),
           annotate("text", x = ext$xmin + (ext$xmax - ext$xmin) * 0.02, y = ext$ymax - (ext$ymax - ext$ymin) * 0.1,
                    label = paste("Roads:", nrow(roads_full)), hjust = 0, colour = "#B0B0B0", size = 4, fontface = "bold")
        )} +
        ggspatial::annotation_scale(location = "bl", width_hint = 0.2, style = "bar",
                                    bar_cols = c("white","white"), text_col = "white") +
        ggspatial::annotation_north_arrow(location = "tr", style = ggspatial::north_arrow_fancy_orienteering,
                                          height = unit(1.5,"cm"), width = unit(1.5,"cm")) +
        labs(title = "Project Area Base Map with OSM Overlays",
             subtitle = paste0("Satellite extent: ", round((ext$xmax-ext$xmin)/1000,1), " x ",
                               round((ext$ymax-ext$ymin)/1000,1), " km")) +
        theme_void() +
        theme(plot.title = element_text(hjust=0.5, size=16, color="white", face="bold"),
              plot.subtitle = element_text(hjust=0.5, size=12, color="white"),
              plot.background = element_rect(fill="black"), plot.margin = margin(10,10,10,10))
      ggsave(preview_path, p_preview, width=16, height=12, dpi=150, units="in")
      if (file.exists(preview_path)) cat("  Preview map saved:", basename(preview_path), "\n")
    }, error = function(e) cat("  Preview map creation failed:", conditionMessage(e), "\n"))
  } else {
    cat("  Preview map exists:", basename(preview_path), "\n")
  }
} else {
  cat("Building base map with OSM overlays...\n")

  # Base-map extent covers every project observation (computed above), so every
  # window is fully covered. Derive the 4326 bbox used by the tile/OSM APIs.
  bbox_sf       <- sf::st_transform(
    sf::st_as_sfc(sf::st_bbox(windows_bbox_3857, crs = 3857)), 4326)
  project_bbox  <- sf::st_bbox(bbox_sf)
  bbox_3857     <- sf::st_as_sfc(sf::st_bbox(windows_bbox_3857, crs = 3857))
  bbox_3857_coords <- sf::st_bbox(bbox_3857)

  cat("  Window-union extent (EPSG:3857):\n")
  cat("    X:", round(windows_bbox_3857["xmin"]), "to", round(windows_bbox_3857["xmax"]), "\n")
  cat("    Y:", round(windows_bbox_3857["ymin"]), "to", round(windows_bbox_3857["ymax"]), "\n")

  cat("  Downloading satellite imagery...\n")
  sat_raster <- maptiles::get_tiles(x = bbox_sf, provider = "Esri.WorldImagery",
                                    zoom = base_map_zoom, crop = TRUE,
                                    cachedir = tempdir(), verbose = TRUE)

  cat("  Satellite imagery downloaded\n")
  sat_crs <- terra::crs(sat_raster, describe = TRUE)$code
  if (sat_crs != "3857") {
    cat("  Reprojecting to EPSG:3857...\n")
    sat_raster <- terra::project(sat_raster, "EPSG:3857", method = "bilinear")
  }

  roads_full     <- NULL
  waterways_full <- NULL

  if (!skip_osm_overlays) {
    cat("  Fetching OSM overlays...\n")
    osmdata::set_overpass_url("https://overpass-api.de/api/interpreter")

    osm_bbox     <- as.numeric(project_bbox)
    sat_ext      <- terra::ext(sat_raster)
    sat_bbox_3857 <- c(xmin = as.numeric(sat_ext$xmin), ymin = as.numeric(sat_ext$ymin),
                       xmax = as.numeric(sat_ext$xmax), ymax = as.numeric(sat_ext$ymax))
    class(sat_bbox_3857) <- "bbox"
    attr(sat_bbox_3857, "crs") <- sf::st_crs(3857)

    cat("    Fetching roads...\n")
    roads_raw <- tryCatch({
      q <- osmdata::opq(bbox = osm_bbox, timeout = 60)
      q <- osmdata::add_osm_feature(q, key = "highway",
                                    value = c("motorway","trunk","primary","secondary","tertiary",
                                              "unclassified","residential","service","living_street",
                                              "track","path"))
      osm_data <- osmdata::osmdata_sf(q, quiet = TRUE)
      if (!is.null(osm_data$osm_lines) && nrow(osm_data$osm_lines) > 0) {
        cat("      Retrieved", nrow(osm_data$osm_lines), "road features\n")
        osm_data$osm_lines
      } else { cat("      No road features found\n"); NULL }
    }, error = function(e) { cat("      Roads fetch failed:", conditionMessage(e), "\n"); NULL })

    if (!is.null(roads_raw) && nrow(roads_raw) > 0) {
      roads_full <- tryCatch({
        r <- sf::st_transform(roads_raw, 3857)
        r <- sf::st_make_valid(r)
        r <- r[sf::st_is_valid(r) & !sf::st_is_empty(r), ]
        r_clipped <- sf::st_crop(r, sat_bbox_3857)
        cat("      Roads ready:", nrow(r_clipped), "features (clipped)\n")
        r_clipped
      }, error = function(e) { cat("      Road processing failed:", conditionMessage(e), "\n"); NULL })
    }

    cat("    Fetching waterways...\n")
    waterways_raw <- tryCatch({
      q <- osmdata::opq(bbox = osm_bbox, timeout = 60)
      q <- osmdata::add_osm_feature(q, key = "waterway",
                                    value = c("river","stream","canal","ditch","drain","tidal_channel","wadi"))
      osm_data <- osmdata::osmdata_sf(q, quiet = TRUE)
      if (!is.null(osm_data$osm_lines) && nrow(osm_data$osm_lines) > 0) {
        cat("      Retrieved", nrow(osm_data$osm_lines), "waterway features\n")
        osm_data$osm_lines
      } else { cat("      No waterway features found\n"); NULL }
    }, error = function(e) { cat("      Waterways fetch failed:", conditionMessage(e), "\n"); NULL })

    if (!is.null(waterways_raw) && nrow(waterways_raw) > 0) {
      waterways_full <- tryCatch({
        w <- sf::st_transform(waterways_raw, 3857)
        w <- sf::st_make_valid(w)
        w <- w[sf::st_is_valid(w) & !sf::st_is_empty(w), ]
        w_clipped <- sf::st_crop(w, sat_bbox_3857)
        cat("      Waterways ready:", nrow(w_clipped), "features (clipped)\n")
        w_clipped
      }, error = function(e) { cat("      Waterway processing failed:", conditionMessage(e), "\n"); NULL })
    }
    cat("  OSM fetching complete\n")
  }

  cat("  Saving base map cache...\n")
  terra::writeRaster(sat_raster, base_map_file, overwrite = TRUE, gdal = c("COMPRESS=LZW","TILED=YES"))
  saveRDS(list(roads = roads_full, waterways = waterways_full), osm_data_file)
  cat("  Base map saved\n")

  # Diagnostic preview
  preview_path <- file.path(base_map_dir, "preview_full_project_map.png")
  tryCatch({
    ext <- terra::ext(sat_raster)
    p_preview <- ggplot() +
      tidyterra::geom_spatraster_rgb(data = sat_raster) +
      coord_sf(crs = 3857, xlim = c(ext$xmin, ext$xmax), ylim = c(ext$ymin, ext$ymax), expand = FALSE) +
      {if (!is.null(waterways_full) && nrow(waterways_full) > 0) list(
         geom_sf(data = waterways_full, colour = "#4FA3FF", linewidth = 0.5, alpha = 0.7, inherit.aes = FALSE),
         annotate("text", x = ext$xmin + (ext$xmax-ext$xmin)*0.02, y = ext$ymax - (ext$ymax-ext$ymin)*0.05,
                  label = paste("Waterways:", nrow(waterways_full)), hjust=0, colour="#4FA3FF", size=4, fontface="bold")
      )} +
      {if (!is.null(roads_full) && nrow(roads_full) > 0) list(
         geom_sf(data = roads_full, colour = "#B0B0B0", linewidth = 0.4, alpha = 0.7, inherit.aes = FALSE),
         annotate("text", x = ext$xmin + (ext$xmax-ext$xmin)*0.02, y = ext$ymax - (ext$ymax-ext$ymin)*0.1,
                  label = paste("Roads:", nrow(roads_full)), hjust=0, colour="#B0B0B0", size=4, fontface="bold")
      )} +
      ggspatial::annotation_scale(location="bl", width_hint=0.2, style="bar",
                                  bar_cols=c("white","white"), text_col="white") +
      ggspatial::annotation_north_arrow(location="tr", style=ggspatial::north_arrow_fancy_orienteering,
                                        height=unit(1.5,"cm"), width=unit(1.5,"cm")) +
      labs(title = "Project Area Base Map with OSM Overlays",
           subtitle = paste0("Satellite extent: ", round((ext$xmax-ext$xmin)/1000,1), " x ",
                             round((ext$ymax-ext$ymin)/1000,1), " km")) +
      theme_void() +
      theme(plot.title = element_text(hjust=0.5, size=16, color="white", face="bold"),
            plot.subtitle = element_text(hjust=0.5, size=12, color="white"),
            plot.background = element_rect(fill="black"), plot.margin = margin(10,10,10,10))
    ggsave(preview_path, p_preview, width=16, height=12, dpi=150, units="in")
    if (file.exists(preview_path)) cat("  Preview map saved:", basename(preview_path), "\n")
  }, error = function(e) cat("  Preview map creation failed:", conditionMessage(e), "\n"))
}

# ==============================================================================
# DOWNLOAD PHOTOS
# ==============================================================================

cat("\n=== DOWNLOADING PHOTOS ===\n")

photo_manifest_file <- file.path(out_dir, "photo_manifest.rds")

if (file.exists(photo_manifest_file) && !fresh_run) {
  photo_manifest <- readRDS(photo_manifest_file)
  cat("Loaded photo manifest:", nrow(photo_manifest), "previously downloaded\n")
} else {
  photo_manifest <- data.frame(photo_url = character(), photo_file = character(), stringsAsFactors = FALSE)
}

samples <- sampled %>%
  mutate(
    ext           = ifelse(grepl("\\.png", photo_url, ignore.case = TRUE), "png", "jpg"),
    photo_file_abs = file.path(photos_dir, sprintf("obs_%s.%s", obs_id, ext))
  )

if (nrow(photo_manifest) > 0) {
  samples <- samples %>%
    left_join(photo_manifest %>% select(photo_url, photo_file_cached = photo_file), by = "photo_url")
} else {
  samples <- samples %>% mutate(photo_file_cached = NA_character_)
}

samples <- samples %>%
  mutate(
    existing_file = ifelse(!is.na(photo_file_cached) & file.exists(file.path(photos_dir, photo_file_cached)),
                           file.path(photos_dir, photo_file_cached), NA_character_),
    photo_exists  = !is.na(existing_file) | file.exists(photo_file_abs)
  )

reuse_count <- 0
for (i in 1:nrow(samples)) {
  if (!is.na(samples$existing_file[i]) && samples$existing_file[i] != samples$photo_file_abs[i]) {
    if (!file.exists(samples$photo_file_abs[i])) {
      file.copy(samples$existing_file[i], samples$photo_file_abs[i])
      reuse_count <- reuse_count + 1
    }
  }
}
if (reuse_count > 0) cat("Reused", reuse_count, "photos\n")

samples$photo_exists <- file.exists(samples$photo_file_abs)
need_download        <- !samples$photo_exists

if (any(need_download)) {
  cat("Downloading", sum(need_download), "new photos (", sum(samples$photo_exists), "available)...\n")
  for (i in which(need_download)) {
    success <- dl_file(samples$photo_url[i], samples$photo_file_abs[i])
    if (!success) cat("  Failed obs", samples$obs_id[i], "\n")
  }
  samples$photo_exists <- file.exists(samples$photo_file_abs)
} else {
  cat("All", nrow(samples), "photos available\n")
}

new_entries <- samples %>%
  filter(photo_exists) %>%
  select(photo_url, photo_file_abs) %>%
  mutate(photo_file = basename(photo_file_abs)) %>%
  select(photo_url, photo_file)

photo_manifest <- bind_rows(photo_manifest, new_entries) %>% distinct(photo_url, .keep_all = TRUE)
saveRDS(photo_manifest, photo_manifest_file)

samples <- samples %>%
  filter(photo_exists) %>%
  mutate(
    date_label = suppressWarnings(lubridate::ymd(observed_on)) %>% format("%A, %d %b %Y"),
    cap_common = ifelse(!is.na(common_name) & nzchar(common_name), common_name, ""),
    cap_sci    = ifelse(!is.na(sci_name)    & nzchar(sci_name),    sci_name,    ""),
    cap_obs    = paste0("Observed by ", ifelse(is.na(observer), "Unknown", observer))
  )

cat("Ready:", nrow(samples), "photos\n")

# ==============================================================================
# CREATE MAPS
# ==============================================================================

cat("\n=== CREATING MAPS ===\n")

safe_make_map <- function(lon, lat, out_path, obs_id = NULL) {
  tryCatch({
    if (is.na(lon) || is.na(lat)) {
      if (diagnostic_mode) cat("  Obs", obs_id, "- Missing coordinates\n")
      return(FALSE)
    }

    if (diagnostic_mode) cat("  Obs", obs_id, "- Creating map...\n")

    obs_ll <- sf::st_sfc(sf::st_point(c(lon, lat)), crs = 4326)
    hq_ll  <- sf::st_sfc(sf::st_point(c(hq_lon, hq_lat)), crs = 4326)
    obs_m  <- sf::st_transform(obs_ll, 3857)
    hq_m   <- sf::st_transform(hq_ll,  3857)
    obs_xy <- sf::st_coordinates(obs_m)

    # Fixed-aspect (880:600) window centred on the HQ-observation midpoint and
    # snapped to a quantised zoom level (see compute_map_window). The base map
    # covers every project observation, so this window is always fully covered.
    win  <- compute_map_window(obs_xy[1], obs_xy[2])
    xmin <- as.numeric(win["xmin"]); xmax <- as.numeric(win["xmax"])
    ymin <- as.numeric(win["ymin"]); ymax <- as.numeric(win["ymax"])

    bbox_m   <- sf::st_bbox(c(xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax), crs = 3857)
    crop_ext <- terra::ext(c(xmin, xmax, ymin, ymax))

    if (!exists("sat_raster")) {
      if (diagnostic_mode) cat("  Obs", obs_id, "- ERROR: Base map not loaded\n")
      return(FALSE)
    }

    # snap = "out" so the crop fully covers the window; coord_sf then shows the
    # exact window bounds, filling the cell at the 880:600 aspect.
    rast_crop <- terra::crop(sat_raster, crop_ext, snap = "out")
    if (is.null(rast_crop) || !terra::hasValues(rast_crop)) {
      if (diagnostic_mode) cat("  Obs", obs_id, "- ERROR: Failed to crop raster\n")
      return(FALSE)
    }

    roads_crop <- NULL
    if (!is.null(roads_full) && nrow(roads_full) > 0)
      roads_crop <- tryCatch({ r <- sf::st_crop(roads_full, bbox_m); if (nrow(r) > 0) r else NULL }, error = function(e) NULL)

    waterways_crop <- NULL
    if (!is.null(waterways_full) && nrow(waterways_full) > 0)
      waterways_crop <- tryCatch({ w <- sf::st_crop(waterways_full, bbox_m); if (nrow(w) > 0) w else NULL }, error = function(e) NULL)

    obs_coords <- sf::st_coordinates(obs_m)
    hq_coords  <- sf::st_coordinates(hq_m)

    # Line overlay styling (legend is drawn BELOW the map in the slide layout,
    # not inside the map, so we style the lines directly here):
    #   Track       = grey (#B0B0B0), solid   - matches the Data Dive maps
    #   Watercourse = blue (#4FA3FF), solid   - matches the Data Dive maps
    has_tracks      <- !is.null(roads_crop)     && nrow(roads_crop)     > 0
    has_watercourse <- !is.null(waterways_crop) && nrow(waterways_crop) > 0

    # --- HQ marker: a house with a flag, matching a classic house icon: a wide
    # low roof overhanging the walls (eaves), a doorway cut into the front, and a
    # flag on the right with a wavy pennant. Built from polygons and sized
    # relative to the window so it stays a constant size on screen. Drawn as a
    # white silhouette with a dark outline for visibility on the imagery. ---
    hq_w  <- xmax - xmin
    hq_cx <- hq_coords[1]; hq_cy <- hq_coords[2]
    bw <- hq_w * 0.015; bh <- hq_w * 0.017           # wall half-width, height
    rw <- hq_w * 0.026; rh <- hq_w * 0.015           # roof half-width (eaves), height
    dw <- hq_w * 0.005; dh <- hq_w * 0.010           # door half-width, height
    by <- hq_cy - (bh + rh) / 2                      # base of the walls
    # Walls with a doorway notch cut out of the bottom centre
    hq_body <- data.frame(
      x = c(hq_cx - bw, hq_cx - bw, hq_cx + bw, hq_cx + bw, hq_cx + dw, hq_cx + dw, hq_cx - dw, hq_cx - dw),
      y = c(by,         by + bh,    by + bh,    by,         by,         by + dh,    by + dh,    by))
    # Wide, low-pitch roof overhanging the walls
    hq_roof <- data.frame(
      x = c(hq_cx - rw, hq_cx + rw, hq_cx),
      y = c(by + bh,    by + bh,    by + bh + rh))
    # Flag pole on the right, emerging from the roof slope
    hq_px      <- hq_cx + hq_w * 0.010
    hq_poletop <- by + bh + rh + hq_w * 0.025
    pole_hw    <- hq_w * 0.002
    hq_pole <- data.frame(
      x = c(hq_px - pole_hw, hq_px + pole_hw, hq_px + pole_hw, hq_px - pole_hw),
      y = c(by + bh,         by + bh,         hq_poletop,      hq_poletop))
    # Wavy pennant pointing right from the top of the pole
    fh <- hq_w * 0.010; fw <- hq_w * 0.017
    hq_flag <- data.frame(
      x = c(hq_px, hq_px + fw,            hq_px + fw * 0.80,    hq_px + fw,            hq_px),
      y = c(hq_poletop, hq_poletop - fh * 0.15, hq_poletop - fh * 0.5, hq_poletop - fh * 0.85, hq_poletop - fh))

    p <- ggplot() +
      tidyterra::geom_spatraster_rgb(data = rast_crop) +
      coord_sf(crs = 3857, xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = FALSE, clip = "on") +
      {if (has_watercourse)
         geom_sf(data = waterways_crop, colour = "#4FA3FF", linewidth = 0.5, alpha = 0.7, inherit.aes = FALSE)} +
      {if (has_tracks)
         geom_sf(data = roads_crop, colour = "#B0B0B0",
                 linewidth = 0.4, alpha = 0.7, inherit.aes = FALSE)} +
      geom_polygon(data = hq_body, aes(x = x, y = y),
                   fill = "orange", colour = NA, inherit.aes = FALSE) +
      geom_polygon(data = hq_pole, aes(x = x, y = y),
                   fill = "orange", colour = NA, inherit.aes = FALSE) +
      geom_polygon(data = hq_roof, aes(x = x, y = y),
                   fill = "orange", colour = NA, inherit.aes = FALSE) +
      geom_polygon(data = hq_flag, aes(x = x, y = y),
                   fill = "orange", colour = NA, inherit.aes = FALSE) +
      geom_text(aes(x = hq_px, y = hq_poletop), label = "HQ",
                vjust = -0.5, colour = "yellow", fontface = "bold", size = 8.4, inherit.aes = FALSE) +
      geom_point(aes(x = obs_coords[1], y = obs_coords[2]),
                 colour = "white", shape = 21, size = 6.5, stroke = 2.2, alpha = 0.55, inherit.aes = FALSE) +
      geom_point(aes(x = obs_coords[1], y = obs_coords[2]),
                 colour = "#FF0000", shape = 8, size = 5.2, stroke = 1.2, inherit.aes = FALSE) +
      theme_void() +
      theme(plot.margin = margin(0, 0, 0, 0), legend.position = "none")

    # Render at the 880:600 cell aspect (matches compose_slide) so the map fills
    # its cell with no cropping or letterboxing during composition.
    ggsave(out_path, p, width = 8.8, height = 6.0, dpi = 150, units = "in")

    if (!file.exists(out_path)) {
      if (diagnostic_mode) cat("  Obs", obs_id, "- ERROR: File not created\n")
      return(FALSE)
    }
    if (diagnostic_mode) cat("  Obs", obs_id, "- Success\n")
    TRUE

  }, error = function(e) {
    if (diagnostic_mode) cat("  Obs", obs_id, "- ERROR:", conditionMessage(e), "\n")
    FALSE
  })
}

samples <- samples %>%
  mutate(map_file = file.path(maps_dir, sprintf("map_%s.png", obs_id)),
         map_ok   = file.exists(map_file))

need_map <- !samples$map_ok | force_rebuild_maps
if (any(need_map)) {
  cat("Creating", sum(need_map), "maps (", sum(samples$map_ok & !force_rebuild_maps), "exist)...\n")
  map_results <- rep(FALSE, nrow(samples))
  for (i in which(need_map))
    map_results[i] <- safe_make_map(samples$longitude[i], samples$latitude[i], samples$map_file[i], samples$obs_id[i])

  samples$map_ok <- file.exists(samples$map_file)
  n_success  <- sum(map_results)
  n_failed   <- sum(need_map) - n_success
  cat("Maps created:", n_success, "successful,", n_failed, "failed\n")
  if (n_failed > 0 && diagnostic_mode)
    cat("Failed observation IDs:", paste(samples$obs_id[which(need_map)[!map_results]], collapse = ", "), "\n")
} else {
  cat("All", nrow(samples), "maps exist\n")
}

# ==============================================================================
# COMPOSE SLIDES
# ==============================================================================

cat("\n=== COMPOSING SLIDES ===\n")

# ------------------------------------------------------------------------------
# Taxon silhouette icons (cached). Each iconic taxon maps to a PNG in
# taxon_icon_dir. Icons are fetched once from PhyloPic, recoloured, and cached;
# thereafter they are reused with no API call. A PNG you place there by hand
# (named <taxon>.png) is used as-is. Anything missing falls back to a drawn
# marker in compose_slide, so the slideshow always works.
# ------------------------------------------------------------------------------
# taxon_key(), taxon_color(), recolor_silhouette(), ensure_taxon_icon() are
# provided by bioblitz_style.R (sourced in the configuration section above).

# Draw a simple, taxon-indicative marker on the active image_draw() device.
# Coordinates are image pixels with (0,0) at top-left and y increasing DOWN.
# Shapes are built from base-graphics primitives so no emoji font is needed.
draw_taxon_marker <- function(taxon, cx, cy, s, col, lw = 5) {
  ell  <- function(ex, ey, rx, ry, n = 28) {
    t <- seq(0, 2 * pi, length.out = n); list(x = ex + rx * cos(t), y = ey + ry * sin(t))
  }
  fpoly <- function(e) graphics::polygon(e$x, e$y, col = col, border = col)
  fcirc <- function(ex, ey, r) fpoly(ell(ex, ey, r, r))
  key   <- tolower(taxon)

  if (key == "plantae") {
    # leaf: pointed oval
    graphics::polygon(c(cx, cx + 0.62 * s, cx, cx - 0.62 * s),
                      c(cy - s, cy, cy + s, cy), col = col, border = col)

  } else if (key == "fungi") {
    # mushroom: domed cap + stem
    ang <- seq(0, pi, length.out = 22)
    graphics::polygon(cx + s * cos(ang), (cy - 0.05 * s) - 0.85 * s * sin(ang),
                      col = col, border = col)
    graphics::rect(cx - 0.28 * s, cy + 0.85 * s, cx + 0.28 * s, cy - 0.05 * s,
                   col = col, border = col)

  } else if (key == "aves") {
    # bird: two wing arcs (gull silhouette)
    yy <- cy - 0.55 * s * sin(seq(0, pi, length.out = 12))
    graphics::lines(seq(cx - s, cx, length.out = 12), yy, lwd = lw, col = col)
    graphics::lines(seq(cx, cx + s, length.out = 12), yy, lwd = lw, col = col)

  } else if (key == "insecta") {
    # butterfly: 4 wings + body + antennae
    fpoly(ell(cx - 0.45 * s, cy - 0.30 * s, 0.50 * s, 0.42 * s))
    fpoly(ell(cx + 0.45 * s, cy - 0.30 * s, 0.50 * s, 0.42 * s))
    fpoly(ell(cx - 0.38 * s, cy + 0.34 * s, 0.36 * s, 0.32 * s))
    fpoly(ell(cx + 0.38 * s, cy + 0.34 * s, 0.36 * s, 0.32 * s))
    graphics::segments(cx, cy - 0.6 * s, cx, cy + 0.6 * s, col = col, lwd = lw)
    graphics::segments(cx, cy - 0.6 * s, cx - 0.25 * s, cy - 0.95 * s, col = col, lwd = lw * 0.7)
    graphics::segments(cx, cy - 0.6 * s, cx + 0.25 * s, cy - 0.95 * s, col = col, lwd = lw * 0.7)

  } else if (key == "arachnida") {
    # spider: abdomen + cephalothorax + 8 legs
    fcirc(cx, cy + 0.18 * s, 0.42 * s)
    fcirc(cx, cy - 0.28 * s, 0.24 * s)
    for (a in c(18, 48, 78, 108)) {
      rad <- a * pi / 180
      graphics::segments(cx, cy, cx - 1.05 * s * cos(rad), cy - 0.55 * s * sin(rad) + 0.1 * s,
                         col = col, lwd = lw * 0.7)
      graphics::segments(cx, cy, cx + 1.05 * s * cos(rad), cy - 0.55 * s * sin(rad) + 0.1 * s,
                         col = col, lwd = lw * 0.7)
    }

  } else if (key == "mollusca") {
    # spiral shell
    t <- seq(0, 4.2 * pi, length.out = 70); r <- (s / (4.2 * pi)) * t
    graphics::lines(cx + r * cos(t), cy + r * sin(t), lwd = lw, col = col)

  } else if (key == "actinopterygii") {
    # fish: body + tail + eye
    fpoly(ell(cx + 0.10 * s, cy, 0.70 * s, 0.42 * s))
    graphics::polygon(c(cx - 0.55 * s, cx - 1.0 * s, cx - 1.0 * s),
                      c(cy, cy - 0.40 * s, cy + 0.40 * s), col = col, border = col)
    de <- ell(cx + 0.45 * s, cy - 0.07 * s, 0.08 * s, 0.08 * s)
    graphics::polygon(de$x, de$y, col = "#10303a", border = "#10303a")

  } else if (key == "reptilia") {
    # lizard: body + head + curling tail + 4 legs
    fpoly(ell(cx, cy, 0.45 * s, 0.24 * s))
    fcirc(cx + 0.62 * s, cy, 0.18 * s)
    tt <- seq(0, 1, length.out = 12)
    graphics::lines(cx - 0.45 * s - tt * 0.6 * s, cy + 0.35 * s * sin(tt * pi), lwd = lw * 0.8, col = col)
    for (dx in c(-0.2, 0.2)) for (dy in c(-0.4, 0.4))
      graphics::segments(cx + dx * s, cy, cx + dx * 2 * s, cy + dy * s, col = col, lwd = lw * 0.7)

  } else if (key == "amphibia") {
    # frog: body + two eye bumps + hind legs
    fpoly(ell(cx, cy + 0.12 * s, 0.60 * s, 0.46 * s))
    fcirc(cx - 0.26 * s, cy - 0.34 * s, 0.16 * s)
    fcirc(cx + 0.26 * s, cy - 0.34 * s, 0.16 * s)
    graphics::lines(c(cx - 0.55 * s, cx - 0.72 * s, cx - 0.45 * s),
                    c(cy + 0.20 * s, cy + 0.50 * s, cy + 0.62 * s), lwd = lw * 0.7, col = col)
    graphics::lines(c(cx + 0.55 * s, cx + 0.72 * s, cx + 0.45 * s),
                    c(cy + 0.20 * s, cy + 0.50 * s, cy + 0.62 * s), lwd = lw * 0.7, col = col)

  } else if (key == "mammalia" || key == "animalia") {
    # paw print: main pad + 4 toe beans
    fpoly(ell(cx, cy + 0.28 * s, 0.50 * s, 0.42 * s))
    fcirc(cx - 0.46 * s, cy - 0.06 * s, 0.17 * s)
    fcirc(cx - 0.16 * s, cy - 0.34 * s, 0.18 * s)
    fcirc(cx + 0.16 * s, cy - 0.34 * s, 0.18 * s)
    fcirc(cx + 0.46 * s, cy - 0.06 * s, 0.17 * s)

  } else if (key == "protozoa" || key == "chromista") {
    # cell: outline + nucleus
    e <- ell(cx, cy, 0.72 * s, 0.72 * s)
    graphics::polygon(e$x, e$y, border = col, col = NA, lwd = lw * 0.9)
    fcirc(cx + 0.18 * s, cy - 0.12 * s, 0.22 * s)

  } else {
    # Unknown / fallback: simple filled dot
    fcirc(cx, cy, 0.5 * s)
  }
}

compose_slide <- function(photo_path, map_path, date, common, sci, obs_by,
                          taxon, has_tracks, has_water, out_path,
                          icon_path = NA_character_, marker_color = "#4FD1C5",
                          scale_px = NA_integer_, scale_label = "") {
  tryCatch({
    p      <- magick::image_read(photo_path)
    w <- 880; h <- 600
    # Always scale to COVER the cell (enlarging undersized photos too), then crop
    # to exactly w x h, so every photo fills the frame at a consistent size.
    p  <- magick::image_resize(p, paste0(w, "x", h, "^"))
    p2 <- magick::image_extent(p, paste0(w, "x", h), "center", "black")

    if (file.exists(map_path)) {
      m      <- magick::image_read(map_path)
      info_m <- magick::image_info(m)
      if (info_m$width != w || info_m$height != h)
        m <- magick::image_resize(m, paste0(w, "x", h, "^"))   # cover-fill the cell
      m2 <- magick::image_extent(m, paste0(w, "x", h), "center", "black")
    } else {
      m2 <- magick::image_blank(w, h, "black")
    }

    bg <- magick::image_blank(1920, 1080, "black")
    bg <- magick::image_composite(bg, p2, offset = "+20+140")
    bg <- magick::image_composite(bg, m2, offset = "+920+140")
    bg <- magick::image_annotate(bg, date, size = 48, color = "white", weight = 700,
                                 gravity = "north", location = "+0+30")

    # --- Left captions (below the photo), wrapped to the photo width so a long
    # common name flows onto extra rows instead of running under the map labels.
    # Each wrapped line takes its own row, pushing the rows below it down. ---
    cap_size <- 58
    cap_cw   <- cap_size * 0.56                 # approx character width (px)
    wrap_lines <- function(txt) {
      words <- strsplit(txt, "\\s+")[[1]]; words <- words[nzchar(words)]
      if (!length(words)) return(character(0))
      lines <- character(0); cur <- ""
      for (wd in words) {
        cand <- if (nzchar(cur)) paste(cur, wd) else wd
        if (nchar(cand) * cap_cw > w && nzchar(cur)) { lines <- c(lines, cur); cur <- wd }
        else cur <- cand
      }
      if (nzchar(cur)) lines <- c(lines, cur)
      lines
    }
    cap_rows <- list()
    if (nzchar(common)) for (ln in wrap_lines(common)) cap_rows <- c(cap_rows, list(list(t = ln, col = "white",   it = FALSE)))
    if (nzchar(sci))    for (ln in wrap_lines(sci))    cap_rows <- c(cap_rows, list(list(t = ln, col = "#9BD1FF", it = TRUE)))
    if (nzchar(obs_by)) for (ln in wrap_lines(obs_by)) cap_rows <- c(cap_rows, list(list(t = ln, col = "#FFE066", it = FALSE)))

    # Row spacing: 70px normally, tightened only if many wrapped rows would
    # otherwise run off the bottom of the slide.
    n_rows   <- length(cap_rows)
    cap_step <- 70
    if (n_rows > 1) {
      avail  <- 1050 - 760
      needed <- (n_rows - 1) * cap_step + cap_size
      if (needed > avail) cap_step <- max(cap_size + 2, floor((avail - cap_size) / (n_rows - 1)))
    }

    y <- 760
    for (r in cap_rows) {
      bg <- magick::image_annotate(bg, r$t, size = cap_size, color = r$col,
                                   style = if (r$it) "italic" else "normal",
                                   gravity = "northwest", location = sprintf("+20+%d", y))
      y <- y + cap_step
    }

    # --- Right-side labels (below the map), mirroring the caption rows ---
    # Drawn into the same image as the captions so they are always aligned:
    #   row 1 (y=760) taxon label   -> common-name row
    #   row 2 (y=810) legend entry  -> scientific-name row
    #   row 3 (y=860) legend entry  -> observer row
    rx_text   <- 1005          # where the right-side text starts
    marker_cx <- 960           # centre of the taxon marker
    line_x1   <- 925; line_x2 <- 995   # legend line-sample span
    row_y     <- c(760, 830, 900)

    # Taxon label text (top row), coloured to match the taxon's icon
    if (nzchar(taxon))
      bg <- magick::image_annotate(bg, taxon, size = 58, color = marker_color,
                                   gravity = "northwest", location = sprintf("+%d+%d", rx_text, row_y[1]))

    # Legend entries (only those present project-wide), Track then Watercourse
    legend_items <- list()
    if (isTRUE(has_tracks))
      legend_items <- c(legend_items, list(list(label = "Track",       col = "#B0B0B0", lty = 1)))
    if (isTRUE(has_water))
      legend_items <- c(legend_items, list(list(label = "Watercourse", col = "#4FA3FF", lty = 1)))

    for (li in seq_along(legend_items)) {
      bg <- magick::image_annotate(bg, legend_items[[li]]$label, size = 58, color = "white",
                                   gravity = "northwest",
                                   location = sprintf("+%d+%d", rx_text, row_y[li + 1]))
    }

    # Taxon icon: composite the cached silhouette PNG if we have one; otherwise
    # we fall back to the drawn marker below. Centred on (marker_cx, row 1).
    icon_done <- FALSE
    if (!is.na(icon_path) && nzchar(icon_path) && file.exists(icon_path)) {
      ic <- tryCatch(magick::image_read(icon_path), error = function(e) NULL)
      if (!is.null(ic)) {
        ic   <- magick::image_resize(ic, "58x58")   # fit within 58px, aspect preserved
        ii   <- magick::image_info(ic)
        bg   <- magick::image_composite(
          bg, ic,
          offset = sprintf("+%d+%d",
                           round(marker_cx - ii$width / 2),
                           round(row_y[1] + 30 - ii$height / 2)))
        icon_done <- TRUE
      }
    }

    # Markers and legend line-samples (single image_draw pass). The taxon marker
    # is only drawn when no icon was composited above.
    bg <- magick::image_draw(bg)
    if (nzchar(taxon) && !icon_done)
      draw_taxon_marker(taxon, marker_cx, row_y[1] + 30, 21, marker_color)
    for (li in seq_along(legend_items)) {
      yy <- row_y[li + 1] + 30
      graphics::segments(line_x1, yy, line_x2, yy,
                         col = legend_items[[li]]$col, lwd = 8, lty = legend_items[[li]]$lty)
    }
    grDevices::dev.off()

    # --- Scale bar: baked onto the canvas (not the map), right-aligned to the
    # map's right edge and vertically on the taxon-label row. ---
    if (file.exists(map_path) && !is.na(scale_px) && scale_px > 0 && nzchar(scale_label)) {
      map_right <- 920 + w                 # right edge of the map cell
      bar_h     <- 13L
      tick_h    <- 28L
      bar_cy    <- row_y[1] + 30           # ~centre of the taxon-label text
      bar_x1    <- map_right - scale_px
      whitebar  <- magick::image_blank(scale_px, bar_h, "white")
      tick      <- magick::image_blank(4, tick_h, "white")
      bg <- magick::image_composite(bg, whitebar, offset = sprintf("+%d+%d", bar_x1, bar_cy - bar_h %/% 2))
      bg <- magick::image_composite(bg, tick,     offset = sprintf("+%d+%d", bar_x1, bar_cy - tick_h %/% 2))
      bg <- magick::image_composite(bg, tick,     offset = sprintf("+%d+%d", map_right - 4, bar_cy - tick_h %/% 2))
      lab_sz <- 40
      lab_w  <- as.integer(nchar(scale_label) * lab_sz * 0.6)   # approx text width
      lab_x  <- bar_x1 - 16 - lab_w
      bg <- magick::image_annotate(bg, scale_label, size = lab_sz, color = "white",
                                   gravity = "northwest", location = sprintf("+%d+%d", lab_x, row_y[1]))
    }

    bg <- magick::image_convert(bg, format = "png", type = "TrueColor", depth = 8)
    magick::image_write(bg, out_path, format = "png", quality = 85, compression = "Zip")
    TRUE
  }, error = function(e) FALSE)
}

samples <- samples %>%
  mutate(slide_file = file.path(compo_dir, sprintf("slide_%s.png", obs_id)),
         slide_ok   = file.exists(slide_file))

need_slide <- !samples$slide_ok | force_rebuild_slides
if (any(need_slide)) {
  # Legend reflects whether tracks / waterways exist project-wide (consistent
  # across every slide), matching what the maps can show.
  project_has_tracks <- !is.null(roads_full)     && nrow(roads_full)     > 0
  project_has_water  <- !is.null(waterways_full) && nrow(waterways_full) > 0

  # Resolve a cached silhouette icon per taxon ONCE (fetch+cache on first run,
  # reuse thereafter). Returns NA for taxa with no icon -> drawn-marker fallback.
  taxon_icon_paths <- character(0)
  if (isTRUE(use_taxon_icons)) {
    if (!dir.exists(taxon_icon_dir)) dir.create(taxon_icon_dir, recursive = TRUE, showWarnings = FALSE)
    icon_taxa <- unique(samples$iconic_taxon)
    cat("Resolving taxon icons for:", paste(icon_taxa, collapse = ", "), "\n")
    taxon_icon_paths <- setNames(
      vapply(icon_taxa, function(tx) {
        pth <- ensure_taxon_icon(tx)
        if (!is.na(pth)) cat("  icon ready:", tx, "\n")
        pth
      }, character(1)), icon_taxa)
  }

  cat("Composing", sum(need_slide), "slides (", sum(samples$slide_ok & !force_rebuild_slides), "exist)...\n")
  for (i in which(need_slide)) {
    ip <- if (length(taxon_icon_paths)) taxon_icon_paths[[samples$iconic_taxon[i]]] else NA_character_
    sc <- map_scale_for(samples$longitude[i], samples$latitude[i])
    compose_slide(samples$photo_file_abs[i], samples$map_file[i],
                  samples$date_label[i], samples$cap_common[i],
                  samples$cap_sci[i], samples$cap_obs[i],
                  samples$iconic_taxon[i], project_has_tracks, project_has_water,
                  samples$slide_file[i], icon_path = ip,
                  marker_color = taxon_color(samples$iconic_taxon[i]),
                  scale_px = sc$px, scale_label = sc$label)
  }
} else {
  cat("All", nrow(samples), "slides exist\n")
}

samples <- samples %>% filter(file.exists(slide_file))

# ==============================================================================
# CREATE COLLAGE
# ==============================================================================

cat("\n=== CREATING COLLAGE ===\n")

collage_file       <- file.path(out_dir, "collage.png")
photos_for_collage <- unique(samples$photo_file_abs)
n_collage          <- min(length(photos_for_collage), max_collage)
photos_for_collage <- photos_for_collage[1:n_collage]

make_collage <- function(paths, out_path, stats = NULL, max_w = 1920, max_h = 1080) {
  k <- length(paths)
  if (k == 0) return(FALSE)

  set.seed(if (!is.null(random_seed)) random_seed else 42)

  # Photos fill the FULL canvas height; the statistic circles are drawn ON TOP
  # of the photos along the bottom edge (no reserved empty band). The band
  # height below is used only to size and vertically position the circles.
  grid_h <- max_h

  # Dark textured background
  canvas <- magick::image_blank(max_w, max_h, color = "#1a1a2e")
  canvas <- magick::image_noise(canvas, "gaussian")
  canvas <- magick::image_modulate(canvas, brightness = 60)

  # Polaroid frame parameters
  photo_w    <- 340
  photo_h    <- 260
  border_lr  <- 9    # 50% of previous (was 18)
  border_top <- 9    # 50% of previous (was 18)
  border_bot <- 28   # 50% of previous (was 56) - classic wider-bottom polaroid look

  # Grid layout with jitter (uses the full canvas height; circles overlay it)
  cols     <- ceiling(sqrt(k * (max_w / grid_h)))
  rows     <- ceiling(k / cols)
  cell_w   <- floor(max_w / cols)
  cell_h   <- floor(grid_h / rows)
  jitter_x <- floor(cell_w * 0.12)
  jitter_y <- floor(cell_h * 0.12)

  for (i in seq_len(k)) {
    img <- try(magick::image_read(paths[i]), silent = TRUE)
    if (inherits(img, "try-error")) next

    # Crop photo to exact size
    img <- magick::image_resize(img, paste0(photo_w, "x", photo_h, "^"))
    img <- magick::image_extent(img, paste0(photo_w, "x", photo_h),
                                 gravity = "center", color = "white")

    # White polaroid border
    frame_w <- photo_w + border_lr * 2
    frame_h <- photo_h + border_top + border_bot
    framed  <- magick::image_border(img, "white", paste0(border_lr, "x", border_top))
    framed  <- magick::image_extent(framed, paste0(frame_w, "x", frame_h),
                                     gravity = "north", color = "white")

    # Subtle 3D raised bevel on the white frame.
    # image_draw opens an R graphics device with pixel coordinates:
    # (0,0) = top-left, x increases right, y increases DOWN.
    # We draw highlight lines on top/left edges and shadow lines on bottom/right.
    bevel <- 4L
    fw    <- as.integer(frame_w)
    fh    <- as.integer(frame_h)
    framed <- magick::image_draw(framed)
    # Top highlight
    graphics::segments(0, bevel/2, fw, bevel/2,
                        col = "#f0f0f0", lwd = bevel)
    # Left highlight
    graphics::segments(bevel/2, 0, bevel/2, fh,
                        col = "#f0f0f0", lwd = bevel)
    # Bottom shadow
    graphics::segments(0, fh - bevel/2, fw, fh - bevel/2,
                        col = "#b8b8b8", lwd = bevel)
    # Right shadow
    graphics::segments(fw - bevel/2, 0, fw - bevel/2, fh,
                        col = "#b8b8b8", lwd = bevel)
    grDevices::dev.off()

    # Set background to transparent before rotating so exposed corners are
    # transparent — the canvas background then shows through naturally
    angle  <- sample(c(seq(-9, -2), seq(2, 9)), 1)
    framed <- magick::image_background(framed, "transparent")
    framed <- magick::image_rotate(framed, angle)

    # Grid position with jitter (vertical centre uses cell within grid_h)
    fi    <- magick::image_info(framed)
    row_i <- (i - 1) %/% cols
    col_i <- (i - 1) %% cols
    cx    <- floor(cell_w * col_i + cell_w / 2)
    cy    <- floor(cell_h * row_i + cell_h / 2)
    jx    <- sample(-jitter_x:jitter_x, 1)
    jy    <- sample(-jitter_y:jitter_y, 1)
    x     <- max(0, cx + jx - fi$width  %/% 2)
    y     <- max(0, cy + jy - fi$height %/% 2)

    canvas <- magick::image_composite(canvas, framed,
                                       offset = sprintf("+%d+%d", x, y))
  }

  # --- Statistic circles along the bottom edge ---
  # Four filled dark-rusty-red circles drawn ON TOP of the photos, each carrying
  # a number (top line) and a short label (bottom line) in white. Text is truly
  # centred in each circle using centre gravity (no character-count guessing).
  if (!is.null(stats) && length(stats) > 0) {
    rust_red    <- "#9A3324"   # dark rusty red
    n_stats     <- length(stats)
    band_h      <- round(max_h * 0.20)                    # nominal band for sizing/position
    circle_d    <- min(band_h - 24, round(max_w / (n_stats * 1.6)))  # diameter
    circle_r    <- circle_d / 2
    cy_band     <- max_h - band_h / 2                     # vertical centre near the bottom
    slot_w      <- max_w / n_stats
    centres_x   <- vapply(seq_len(n_stats), function(j) (j - 0.5) * slot_w, numeric(1))

    # Draw filled circles onto the full-canvas coordinate system.
    canvas <- magick::image_draw(canvas)
    for (j in seq_len(n_stats)) {
      symbols(centres_x[j], cy_band, circles = circle_r, inches = FALSE, add = TRUE,
              bg = rust_red, fg = "#5E1E14", lwd = 3)
    }
    grDevices::dev.off()

    # Annotate number + label, centred in each circle. With gravity = "center"
    # the location offset is measured from the canvas centre, and the text is
    # centred on that point, so circles are perfectly centred regardless of text
    # length. The number sits above centre and the label below it, with a tighter
    # gap between the two lines.
    num_size   <- max(28, round(circle_d * 0.30))
    label_size <- max(16, round(circle_d * 0.13))
    cx_canvas  <- max_w / 2
    cy_canvas  <- max_h / 2
    for (j in seq_len(n_stats)) {
      number <- format(stats[[j]]$value, big.mark = ",", scientific = FALSE, trim = TRUE)
      label  <- stats[[j]]$label

      # Number: offset above the circle centre
      num_dx <- round(centres_x[j] - cx_canvas)
      num_dy <- round((cy_band - circle_r * 0.42) - cy_canvas)
      canvas <- magick::image_annotate(canvas, number, gravity = "center",
                                        size = num_size, color = "white",
                                        weight = 700, font = "sans",
                                        location = sprintf("%+d%+d", num_dx, num_dy))
      # Label: offset below the circle centre (half the previous gap from the number)
      lab_dx <- round(centres_x[j] - cx_canvas)
      lab_dy <- round((cy_band + circle_r * 0.21) - cy_canvas)
      canvas <- magick::image_annotate(canvas, label, gravity = "center",
                                        size = label_size, color = "white",
                                        weight = 600, font = "sans",
                                        location = sprintf("%+d%+d", lab_dx, lab_dy))
    }
  }

  magick::image_write(canvas, out_path, format = "png")
  file.exists(out_path)
}

# --- Compute headline statistics for the collage (from the FULL pool) ---
# These summarise the whole event, not just the photos chosen for the collage.
stat_participants <- obs %>% filter(!is.na(observer), nzchar(observer)) %>%
  distinct(observer) %>% nrow()
stat_observations <- nrow(obs)
stat_species      <- obs %>% filter(!is.na(sci_name), nzchar(sci_name)) %>%
  distinct(sci_name) %>% nrow()
stat_days         <- {
  d <- suppressWarnings(as.Date(obs$observed_on))
  d <- d[!is.na(d)]
  if (length(d) > 0) length(unique(d)) else 0L
}

collage_stats <- list(
  list(value = stat_participants, label = "Participants"),
  list(value = stat_days,         label = "Days"),
  list(value = stat_observations, label = "Observations"),
  list(value = stat_species,      label = "Species")
)

cat("Collage statistics: ", stat_participants, " participants, ",
    stat_days, " days, ", stat_observations, " observations, ",
    stat_species, " species\n", sep = "")

collage_ok <- if (file.exists(collage_file) && !force_rebuild_collage) {
  cat("Collage exists, skipping rebuild\n")
  TRUE
} else {
  make_collage(photos_for_collage, collage_file, stats = collage_stats)
}
if (collage_ok) cat("Collage ready:", n_collage, "photos\n") else cat("Collage creation failed\n")

# ==============================================================================
# BUILD HTML SLIDESHOW
# ==============================================================================

# --------------------------------------------------------------------------
# Compute bioblitz title (name + year) and date range for the welcome slide
# --------------------------------------------------------------------------
obs_dates_valid <- as.Date(na.omit(obs$observed_on))

# Determine year from observation data
if (length(obs_dates_valid) > 0) {
  obs_year <- format(min(obs_dates_valid), "%Y")
} else {
  obs_year <- format(Sys.Date(), "%Y")
}
bioblitz_title <- paste(bioblitz_name, obs_year)

# Determine date range
if (bioblitz_dates_auto || is.null(bioblitz_dates_start) || is.null(bioblitz_dates_end)) {
  # Derive date range from the observation data
  date_start <- if (length(obs_dates_valid) > 0) min(obs_dates_valid) else NA
  date_end   <- if (length(obs_dates_valid) > 0) max(obs_dates_valid) else NA
  cat("Date range derived from observation data\n")
} else {
  # Use manually provided dates
  date_start <- as.Date(bioblitz_dates_start)
  date_end   <- as.Date(bioblitz_dates_end)
  cat("Date range set manually\n")
}

# Format the date range as a human-readable string
if (is.na(date_start)) {
  date_range_label <- ""
} else if (is.na(date_end) || date_start == date_end) {
  date_range_label <- format(date_start, "%d %B %Y")
} else if (format(date_start, "%B %Y") == format(date_end, "%B %Y")) {
  # Same month and year: "15–17 November 2025"
  date_range_label <- paste0(format(date_start, "%d"), "\u2013", format(date_end, "%d %B %Y"))
} else if (format(date_start, "%Y") == format(date_end, "%Y")) {
  # Same year, different months: "15 November – 2 December 2025"
  date_range_label <- paste0(format(date_start, "%d %B"), " \u2013 ", format(date_end, "%d %B %Y"))
} else {
  # Different years: "15 November 2025 – 3 January 2026"
  date_range_label <- paste0(format(date_start, "%d %B %Y"), " \u2013 ", format(date_end, "%d %B %Y"))
}

cat("Bioblitz title:", bioblitz_title, "\n")
cat("Date range label:", date_range_label, "\n")

# --------------------------------------------------------------------------
# Taxon icons and slide grouping
# --------------------------------------------------------------------------
taxon_icons <- c(
  "Plantae"="🪻","Animalia"="🐾","Aves"="🦜","Insecta"="🦋","Arachnida"="🕷️","Amphibia"="🐸",
  "Reptilia"="🦎","Mammalia"="🦘","Mollusca"="🐚","Fungi"="🍄","Actinopterygii"="🐠",
  "Protozoa"="🔬","Chromista"="🧫","Unknown"="❓"
)

grouped     <- split(samples, samples$iconic_taxon)
taxon_order <- names(sort(sapply(grouped, nrow), decreasing = TRUE))

# --------------------------------------------------------------------------
# Copy logo
# --------------------------------------------------------------------------
logo_rel <- ""
if (file.exists(bioblitz_logo)) {
  logo_dest <- file.path(out_dir, basename(bioblitz_logo))
  if (!file.exists(logo_dest) || fresh_run) {
    file.copy(bioblitz_logo, logo_dest, overwrite = TRUE)
    cat("Logo copied to output directory\n")
  }
  logo_rel <- basename(bioblitz_logo)
} else {
  cat("Warning: Logo file not found:", bioblitz_logo, "\n")
}

# --------------------------------------------------------------------------
# Build HTML directly — no Quarto intermediary
#
# Quarto always injects empty <h2> elements and applies r-stretch JS (which
# sets inline style="height:Xpx") to every lone image, making CSS overrides
# unreliable. Writing HTML directly gives full control over slide layout.
# reveal.js is loaded from CDN (requires internet, same as iNaturalist API).
# --------------------------------------------------------------------------

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;",  x, fixed = TRUE)
  x <- gsub(">", "&gt;",  x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

# --- Welcome slide ---
dates_p <- if (nzchar(date_range_label)) {
  paste0('  <p class="welcome-dates">Observations recorded ', date_range_label, '</p>\n')
} else { "" }
logo_div <- if (nzchar(logo_rel)) {
  paste0('  <div class="logo-centre"><img src="', logo_rel, '" alt="logo"></div>\n')
} else { "" }

welcome_section <- paste0(
  '<section class="welcome-slide" data-transition="fade">\n',
  logo_div,
  '  <h2 class="welcome-title">', html_escape(bioblitz_title), '</h2>\n',
  '  <p class="welcome-subtitle">A random selection of photos from our amazing biodiversity survey.</p>\n',
  dates_p,
  '</section>\n'
)

# --- Photo slides ---
# No taxon divider slides. Rows are shuffled so taxa are intermixed.
# The taxon label and legend are baked into each slide image (see compose_slide).
build_slide_sections <- function() {
  # Flatten all rows and shuffle
  all_slides <- do.call(rbind, lapply(names(grouped), function(tx) {
    df <- grouped[[tx]]
    df$iconic_taxon_key <- tx
    df
  }))
  set.seed(if (!is.null(random_seed)) random_seed else 42)
  all_slides <- all_slides[sample(nrow(all_slides)), ]

  # The taxon label and Track/Watercourse legend are baked into each slide PNG
  # (see compose_slide), so the sections only carry the background image.
  out <- ""
  for (i in seq_len(nrow(all_slides))) {
    row       <- all_slides[i, ]
    slide_rel <- url_path("slides", basename(row$slide_file))

    out <- paste0(out,
      '<section class="photo-slide"',
      ' data-background-image="', slide_rel, '"',
      ' data-background-size="contain"',
      ' data-background-color="#000000"',
      ' data-transition="fade">\n',
      '</section>\n')
  }
  out
}

# --- Collage slide ---
# Title omits the word "Bioblitz" from the name, e.g.
# "Walpole Wilderness Bioblitz" -> "Isn't the Walpole Wilderness Amazing?"
collage_place_name <- trimws(gsub("\\s*bioblitz\\s*", " ", bioblitz_name, ignore.case = TRUE))
collage_section <- if (collage_ok) paste0(
  '<section class="collage-slide"',
  ' data-background-image="collage.png"',
  ' data-background-size="contain"',
  ' data-background-color="#000000"',
  ' data-transition="fade">\n',
  '  <p class="collage-title">Isn\'t the ', html_escape(collage_place_name), ' Amazing?</p>\n',
  '</section>\n'
) else ""

# --- Embedded CSS ---
inline_css <- '
  :root { --green:#90EE90; --accent:#4FD1C5; --text:#F7FAFC; --muted:#CBD5E0; }
  body { background:#000; margin:0; }
  .reveal { font-family:"Montserrat","Open Sans",sans-serif; }
  /* Background gradient on .reveal — not .slides, which sits above the
     reveal.js .backgrounds layer where data-background-image renders */
  .reveal { background: radial-gradient(ellipse at 60% 40%, #0b1b2a 0%, #040a11 60%, #000 100%); }
  .reveal .slides { background: transparent !important; }

  /* --- Make the collage slide fill the whole slide --- */
  /* reveal.js runs with center:true, which shrink-wraps each <section> to its
     content height and recentres it. The collage title is an absolute overlay,
     so without this its top would be measured against a tiny content box and it
     would float toward the centre. Forcing the section to top:0 and full height
     makes the title position correctly map onto the 1920x1080 background. Photo slides
     no longer need this (their taxon label and legend are baked into the PNG),
     and the welcome slide keeps its own flex centring. */
  .reveal .slides section.collage-slide {
    top: 0 !important;
    height: 100% !important;
    padding: 0 !important;
  }

  /* --- Collage title overlay --- */
  .collage-slide .collage-title {
    position: absolute;
    top: 30px; left: 50%;
    transform: translateX(-50%);
    color: var(--green) !important;
    font-size: 2.2rem !important; font-weight: 700 !important;
    white-space: nowrap; z-index: 10;
    text-shadow: 2px 2px 8px rgba(0,0,0,0.95);
    margin: 0 !important;
    background: rgba(0,0,0,0.4);
    padding: 8px 30px;
    border-radius: 12px;
  }

  /* --- Welcome slide --- */
  .reveal .slides section.welcome-slide {
    display: flex !important; flex-direction: column !important;
    align-items: center !important; justify-content: center !important;
    position: relative !important; gap: 1rem; padding: 60px !important;
  }
  /* Logo: centred, above the title, larger */
  .welcome-slide .logo-centre {
    display: block;
    width: 320px;
    margin: 0 auto 0.5rem auto;
  }
  .welcome-slide .logo-centre img {
    width: 100%; height: auto;
    border-radius: 14px;
    box-shadow: 0 6px 28px rgba(0,0,0,0.6);
  }
  .welcome-slide .welcome-title {
    color: var(--green) !important; font-size: 5.6rem !important;
    font-weight: 700 !important; text-align: center;
    text-shadow: 2px 2px 6px rgba(0,0,0,0.6); margin: 0;
  }
  .welcome-slide .welcome-subtitle {
    color: var(--text) !important; font-size: 3rem !important;
    text-align: center; margin: 0;
  }
  .welcome-slide .welcome-dates {
    color: #90CDF4 !important; font-size: 2.2rem !important;
    font-style: italic; text-align: center; margin-top: 0.5rem;
  }
'

cdn <- "https://cdnjs.cloudflare.com/ajax/libs/reveal.js/4.6.0"

html_content <- paste0(
'<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>', html_escape(bioblitz_title), '</title>
  <link rel="stylesheet" href="', cdn, '/reset.min.css">
  <link rel="stylesheet" href="', cdn, '/reveal.min.css">
  <link rel="stylesheet" href="', cdn, '/theme/night.min.css">
  <style>', inline_css, '  </style>
</head>
<body>
<div class="reveal">
  <div class="slides">
', welcome_section,
build_slide_sections(),
collage_section,
'  </div>
</div>
<script src="', cdn, '/reveal.min.js"></script>
<script>
  Reveal.initialize({
    width: 1920, height: 1080,
    margin: 0,
    minScale: 0.1, maxScale: 2.0,
    controls: true, controlsLayout: "edges",
    progress: true, slideNumber: "c/t",
    hash: true, transition: "slide",
    autoSlide: ', auto_advance_ms, ',
    autoSlideStoppable: ', tolower(auto_slide_stoppable), ',
    loop: ', tolower(slideshow_loop), ',
    center: true,
  });
</script>
</body>
</html>
')

if (nzchar(logo_rel)) cat("Logo included in welcome slide (top-right)\n")

# ==============================================================================
# WRITE HTML & PDF
# ==============================================================================

cat("\n=== GENERATING HTML ===\n")

html_file <- file.path(out_dir, "slideshow.html")
pdf_file  <- file.path(out_dir, "slideshow.pdf")

tryCatch({
  writeLines(html_content, html_file)
  cat("HTML written:", basename(html_file), "\n")
}, error = function(e) cat("HTML write failed:", conditionMessage(e), "\n"))

if (file.exists(html_file)) {
  should_create_pdf <- create_pdf

  if (create_pdf && pdf_size_limit_mb > 0) {
    estimated_size_mb <- (nrow(samples) * 150) / 1024
    cat("\nEstimated PDF size:", round(estimated_size_mb, 1), "MB\n")
    if (estimated_size_mb > pdf_size_limit_mb) {
      cat("  Skipping PDF - estimated size exceeds limit of", pdf_size_limit_mb, "MB\n")
      should_create_pdf <- FALSE
    }
  }

  if (should_create_pdf && file.exists(pdf_file)) {
    can_write <- tryCatch({ con <- file(pdf_file, "w"); close(con); TRUE }, error = function(e) FALSE)
    if (!can_write) {
      cat("  WARNING: Existing PDF appears to be open in another program\n")
      should_create_pdf <- FALSE
    }
  }

  if (should_create_pdf && requireNamespace("pagedown", quietly = TRUE)) {
    tryCatch({
      cat("  Using pagedown::chrome_print...\n")
      pagedown::chrome_print(html_file, pdf_file, verbose = 1)
      if (file.exists(pdf_file)) {
        file_size_mb <- file.info(pdf_file)$size / (1024^2)
        cat("  PDF created! (", round(file_size_mb, 1), "MB)\n")
      }
    }, error = function(e) {
      cat("  pagedown failed:", conditionMessage(e), "\n")
      cat("  Common causes: Chrome not installed, or PDF is open in another app.\n")
    })
  } else if (!create_pdf) {
    cat("\nPDF creation disabled (create_pdf = FALSE)\n")
  }

  if (!file.exists(pdf_file)) {
    cat("\n  PDF not created. To export manually:\n")
    cat("    1. Open the HTML file in Chrome\n")
    cat("    2. Press 'E' to enter PDF export mode\n")
    cat("    3. Use Ctrl+P > Save as PDF\n")
  }
}

# ==============================================================================
# COMPLETE
# ==============================================================================

cat("\n=== COMPLETE ===\n")
cat("Created", nrow(samples), "slides\n")
cat("Output:", normalizePath(out_dir), "\n")
if (file.exists(html_file)) cat("HTML:", basename(html_file), "\n")
if (file.exists(pdf_file))  cat("PDF:",  basename(pdf_file),  "\n")
cat("\nDiversity maintained:\n")
cat("  Observer: max", max_obs_per_observer, "photos per observer\n")
cat("    (limited by", if(max_obs_per_observer == max_obs_per_observer_abs)
  paste0("absolute cap of ", max_obs_per_observer_abs)
  else paste0("percentage: ", max_obs_per_observer_pct * 100, "%"), ")\n")
cat("  Plants: max", max_plants_pct * 100, "%\n")
if (!is.null(random_seed)) {
  cat("\nRandom seed:", random_seed, "\n")
  cat("  (Set random_seed =", random_seed, "to reproduce)\n")
}
cat("\n=== SCRIPT COMPLETE ===\n")
