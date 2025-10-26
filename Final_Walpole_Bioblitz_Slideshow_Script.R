
# ==============================================================================
# iNaturalist Bioblitz Slideshow Generator
# ==============================================================================

cat("=== SCRIPT STARTING ===\n\n")

# ==============================================================================
# CONFIGURATION - EDIT THESE SETTINGS
# ==============================================================================
# 
# To use this script for a different bioblitz, update the following:
# 1. project_slug - your iNaturalist project URL slug
# 2. bioblitz_name - the name that will appear on slides
# 3. bioblitz_year - the year of your bioblitz
# 4. bioblitz_logo - your logo filename (optional)
# 5. hq_lon, hq_lat - coordinates for your bioblitz headquarters
# ==============================================================================

# --- Project Settings ---
project_slug <- "walpole-wilderness-bioblitz-2025"  # Your iNaturalist project slug
bioblitz_name <- "Walpole Wilderness"               # Name of your bioblitz (used in slides)
bioblitz_year <- 2025                               # Year of the bioblitz
n_photos <- 3                                       # Number of photos in slideshow
bioblitz_logo <- "Walpole-Wilderness-bioblitz.jpg"   # Logo filename (in project root folder)

# --- HQ Location (for maps) ---
hq_lon <- 116.634398  # Headquarters longitude
hq_lat <- -34.992854  # Headquarters latitude

# --- Diversity Settings ---
max_obs_per_observer_pct <- 0.15  # Max 15% of photos from any single observer
max_obs_per_observer_abs <- 5     # Absolute max photos per observer (takes precedence if lower)
max_plants_pct <- 0.50             # Max 50% of photos can be plants (Plantae)

# --- Random Seed Settings ---
use_random_seed <- TRUE   # TRUE = different selection each run, FALSE = use R's random state
random_seed <- NULL       # Set to a number (e.g., 42) for reproducible results, NULL for random

# --- Run Mode ---
fresh_run <- TRUE              # TRUE = delete all old artifacts and start fresh
fetch_all_observations <- TRUE  # TRUE = fetch all obs from project, FALSE = fetch subset
cache_observations <- TRUE      # TRUE = cache fetched observations for faster reruns
use_incremental_fetch <- TRUE   # TRUE = only fetch NEW observations since last run (much faster!)
# NOTE: For daily updates, set fresh_run=FALSE to use incremental fetch

# --- Force Rebuild Options ---
force_rebuild_base_map <- TRUE   # FALSE = rebuild satellite base map even if cached
force_rebuild_maps <- FALSE       # TRUE = rebuild all individual observation maps
force_rebuild_slides <- FALSE     # TRUE = rebuild all slide compositions
skip_osm_overlays <- FALSE        # TRUE = skip OpenStreetMap roads/waterways (faster)

# --- Map Settings ---
# Map Provider Options (affects download speed):
#   "Esri.WorldImagery"     - High quality satellite imagery (SLOWEST, best quality)
#   "OpenStreetMap"         - Simple street map (FAST, clear but basic)
#   "CartoDB.Positron"      - Light minimal map (FAST, clean look)
#   "CartoDB.Voyager"       - Balanced detail map (FAST, good compromise)
#   "Esri.WorldTopoMap"     - Topographic map (MEDIUM speed, shows terrain)
# For LARGE areas, use "OpenStreetMap" or "CartoDB.Positron" for 10-20x faster downloads
map_provider <- "Esri.WorldImagery"  # Change to "OpenStreetMap" for large areas
base_map_zoom <- 14                  # Zoom level (13-15 recommended)
                                      # Lower zoom (12-13) = faster downloads for large areas
buffer_km <- 3.5                     # Buffer around observations for base map extent (km)
                                      # Reduce to 2-3 for large areas to minimize download time
default_dist_m <- 4000               # Default map radius for individual observations (meters)

# PERFORMANCE TIPS FOR LARGE BIOBLITZES:
# 1. Set map_provider = "OpenStreetMap" or "CartoDB.Positron" (10-20x faster than satellite)
# 2. Set skip_osm_overlays = TRUE (skips road/waterway download)
# 3. Reduce base_map_zoom to 12 or 13 (fewer tiles to download)
# 4. Reduce buffer_km to 2-3 (smaller area to download)
# 5. After first run, set force_rebuild_base_map = FALSE (reuse cached base map)

# --- Slideshow Settings ---
auto_advance_ms <- 7000        # Auto-advance time in milliseconds (7000 = 7 seconds)
auto_slide_stoppable <- TRUE   # Allow user to stop auto-advance
slideshow_loop <- FALSE        # Loop slideshow when it reaches the end
max_collage <- 25              # Maximum photos in final collage
create_pdf <- FALSE             # Set to FALSE to skip PDF creation (useful for large slideshows)
pdf_size_limit_mb <- 50        # Skip PDF if estimated size exceeds this (0 = no limit)

# --- Output Settings ---
out_dir <- "outputs/slideshow"  # Output directory (created automatically)
diagnostic_mode <- TRUE  # Print detailed progress messages

# ==============================================================================
# END OF CONFIGURATION - DO NOT EDIT BELOW THIS LINE
# ==============================================================================

cat("=== CONFIGURATION LOADED ===\n")
cat("Project:", project_slug, "\n")
cat("Target photos:", n_photos, "\n")
cat("Map provider:", map_provider, "\n")
cat("Map zoom:", base_map_zoom, "\n")
cat("OSM overlays:", if(skip_osm_overlays) "DISABLED (faster)" else "enabled", "\n")
cat("Observer diversity: max", max_obs_per_observer_pct * 100, "% per observer\n")
cat("Plant diversity: max", max_plants_pct * 100, "% plants\n")
cat("Run mode:", if(fresh_run) "FRESH" else "INCREMENTAL", "\n")
cat("Fetch mode:", if(use_incremental_fetch && !fresh_run) "INCREMENTAL (new obs only)" else "FULL", "\n")

# FIX 1: SET SEED BEFORE ANY RANDOMIZATION
if (use_random_seed && is.null(random_seed)) {
  # Use more entropy for better randomization
  # Use timestamp modulo to keep within integer range, plus microseconds for extra randomness
  time_num <- as.numeric(Sys.time())
  random_seed <- as.integer((time_num %% 100000) * 10000 + runif(1, 0, 9999))
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
photos_dir <- file.path(out_dir, "photos")
maps_dir <- file.path(out_dir, "maps")
compo_dir <- file.path(out_dir, "slides")
styles_dir <- file.path(out_dir, "styles")
base_map_dir <- file.path(out_dir, "base_map_cache")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(photos_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(maps_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(compo_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(styles_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(base_map_dir, recursive = TRUE, showWarnings = FALSE)

# Clean up if fresh run requested
if (fresh_run) {
  cat("FRESH RUN: Cleaning up old artifacts...\n")
  if (dir.exists(photos_dir)) unlink(photos_dir, recursive = TRUE)
  if (dir.exists(maps_dir)) unlink(maps_dir, recursive = TRUE)
  if (dir.exists(compo_dir)) unlink(compo_dir, recursive = TRUE)
  
  obs_cache_file <- file.path(out_dir, "observations_cache.rds")
  if (file.exists(obs_cache_file)) unlink(obs_cache_file)
  
  photo_manifest_file <- file.path(out_dir, "photo_manifest.rds")
  if (file.exists(photo_manifest_file)) unlink(photo_manifest_file)
  
  if (!force_rebuild_base_map && dir.exists(base_map_dir)) {
    cat("  Keeping base map cache\n")
  }
  
  dir.create(photos_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(maps_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(compo_dir, recursive = TRUE, showWarnings = FALSE)
  cat("  Old artifacts removed\n\n")
}

# ==============================================================================
# LOAD PACKAGES
# ==============================================================================

cat("Loading packages...\n")
req <- c("httr2","jsonlite","dplyr","purrr","tidyr","stringr","lubridate",
         "janitor","glue","readr","tibble","ggplot2","sf",
         "maptiles","terra","tidyterra","osmdata","magick","ggspatial")
opt <- c("quarto","pagedown","rstudioapi")

to_install <- setdiff(c(req, opt), rownames(installed.packages()))
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")
invisible(lapply(req, library, character.only = TRUE))
cat("Packages loaded\n\n")

`%||%` <- function(a, b) if (is.null(a)) b else a
url_path <- function(...) gsub("\\\\","/", file.path(...))
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

best_photo_url <- function(photo_obj, size = c("original", "large", "medium")) {
  # First try to get size-specific URL fields from API (if they exist)
  for (s in size) {
    url_field <- paste0(s, "_url")
    u <- photo_obj[[url_field]]
    if (!is.null(u) && !is.na(u) && nzchar(u)) {
      return(u)
    }
  }
  
  # If size-specific fields don't exist, try URL manipulation
  u <- photo_obj$url
  if (is.null(u) || is.na(u) || !nzchar(u)) {
    return(NA_character_)
  }
  
  # iNaturalist photo URLs have patterns like:
  # .../square.jpeg, .../medium.jpeg, .../large.jpeg, .../original.jpeg
  # Also handles .jpg and .png extensions
  for (s in size) {
    # Try to replace size in URL (e.g., square.jpeg -> large.jpeg)
    new_url <- sub("/[a-z]+\\.(jpeg|jpg|png)$", paste0("/", s, ".\\1"), u, ignore.case = TRUE)
    if (new_url != u) {
      # Successfully modified the URL
      return(new_url)
    }
  }
  
  # If no pattern matched, return original URL
  return(u)
}

flatten_obs <- function(o) {
  tax <- if (!is.null(o$taxon)) o$taxon else list()
  user <- if (!is.null(o$user)) o$user else list()
  phot <- if (!is.null(o$photos)) o$photos else list()
  coords <- if (!is.null(o$geojson) && !is.null(o$geojson$coordinates)) o$geojson$coordinates else c(NA_real_, NA_real_)
  
  tibble::tibble(
    obs_id = if (!is.null(o$id)) o$id else NA_integer_,
    observed_on = if (!is.null(o$observed_on)) o$observed_on else NA_character_,
    observer = if (!is.null(user$name)) user$name else if (!is.null(user$login)) user$login else NA_character_,
    sci_name = if (!is.null(tax$name)) tax$name else NA_character_,
    common_name = if (!is.null(tax$preferred_common_name)) tax$preferred_common_name else NA_character_,
    iconic_taxon = if (!is.null(tax$iconic_taxon_name)) tax$iconic_taxon_name else NA_character_,
    longitude = suppressWarnings(as.numeric(coords[[1]])),
    latitude = suppressWarnings(as.numeric(coords[[2]])),
    photos_list = list(phot)
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
  page <- 1
  per_page <- 200
  obs_pool <- list()
  
  cat("Fetching", if(fetch_all) "ALL" else "subset of", "observations...\n")
  
  if (fetch_all) {
    q_count <- list(project_id = project_slug, per_page = 1, fields = "id")
    q_count[["has[]"]] <- "photos"
    
    res_count <- inat_get("observations", q_count)
    total_results <- res_count$total_results
    n_pages <- ceiling(total_results / per_page)
    
    cat("  Total observations:", total_results, "\n")
    cat("  Pages to fetch:", n_pages, "\n")
    
    for (page in 1:n_pages) {
      if (page %% 5 == 1 || page == n_pages) {
        cat("  Fetching pages", page, "to", min(page + 4, n_pages), "of", n_pages, "...\n")
      }
      
      q <- list(
        project_id = project_slug,
        per_page = per_page,
        page = page,
        order = "desc",
        order_by = "id",
        fields = paste0("id,observed_on,geojson,user.login,user.name,",
                        "taxon.name,taxon.preferred_common_name,taxon.iconic_taxon_name,",
                        "photos.url,photos.original_url,photos.large_url,photos.medium_url")
      )
      q[["has[]"]] <- "photos"
      
      res <- inat_get("observations", q)
      if (!length(res$results)) break
      
      chunk <- purrr::map_dfr(res$results, flatten_obs)
      if (nrow(chunk) > 0) {
        obs_pool[[length(obs_pool) + 1]] <- chunk
      }
    }
  } else {
    repeat {
      q <- list(
        project_id = project_slug,
        per_page = per_page,
        page = page,
        order = "desc",
        order_by = "id",
        fields = paste0("id,observed_on,geojson,user.login,user.name,",
                        "taxon.name,taxon.preferred_common_name,taxon.iconic_taxon_name,",
                        "photos.url,photos.original_url,photos.large_url,photos.medium_url")
      )
      q[["has[]"]] <- "photos"
      
      if (page %% 5 == 1) cat("  Page", page, "...\n")
      
      res <- inat_get("observations", q)
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

obs_cache_file <- file.path(out_dir, "observations_cache.rds")
fetch_state_file <- file.path(out_dir, "fetch_state.rds")

# Load existing observations and fetch state
existing_obs <- NULL
last_fetch_time <- NULL

if (cache_observations && file.exists(obs_cache_file) && !fresh_run) {
  existing_obs <- readRDS(obs_cache_file)
  cat("Loaded", nrow(existing_obs), "cached observations\n")
  
  if (file.exists(fetch_state_file)) {
    fetch_state <- readRDS(fetch_state_file)
    last_fetch_time <- fetch_state$last_fetch_time
    cat("Last fetch:", last_fetch_time, "\n")
  }
}

# Decide whether to do incremental fetch
do_incremental <- use_incremental_fetch && !fresh_run && !is.null(existing_obs) && !is.null(last_fetch_time)

if (do_incremental) {
  cat("\n=== INCREMENTAL FETCH (new observations only) ===\n")
  cat("This will be much faster than a full fetch!\n")
  
  # Fetch only observations created/updated since last fetch
  new_obs <- tryCatch({
    page <- 1
    per_page <- 200
    obs_pool <- list()
    
    cat("Fetching observations updated since", last_fetch_time, "...\n")
    
    repeat {
      q <- list(
        project_id = project_slug,
        per_page = per_page,
        page = page,
        order = "desc",
        order_by = "created_at",
        updated_since = last_fetch_time,
        fields = paste0("id,observed_on,geojson,user.login,user.name,",
                        "taxon.name,taxon.preferred_common_name,taxon.iconic_taxon_name,",
                        "photos.url,photos.original_url,photos.large_url,photos.medium_url")
      )
      q[["has[]"]] <- "photos"
      
      res <- inat_get("observations", q)
      if (!length(res$results)) break
      
      chunk <- purrr::map_dfr(res$results, flatten_obs)
      if (nrow(chunk) > 0) {
        obs_pool[[length(obs_pool) + 1]] <- chunk
      }
      
      if (length(res$results) < per_page) break
      page <- page + 1
      if (page > 50) break
    }
    
    if (length(obs_pool) > 0) {
      dplyr::bind_rows(obs_pool) |> janitor::clean_names()
    } else {
      data.frame()
    }
  }, error = function(e) {
    cat("Incremental fetch failed:", conditionMessage(e), "\n")
    cat("Falling back to full fetch...\n")
    NULL
  })
  
  if (!is.null(new_obs) && nrow(new_obs) > 0) {
    cat("  Found", nrow(new_obs), "new/updated observations\n")
    
    # Merge with existing, removing duplicates (keep newer versions)
    obs <- bind_rows(existing_obs, new_obs) %>%
      distinct(obs_id, .keep_all = TRUE)
    
    cat("  Total after merge:", nrow(obs), "observations\n")
    cat("  Time saved: Did not re-download", nrow(existing_obs) - nrow(new_obs), "existing observations!\n")
  } else if (!is.null(new_obs)) {
    cat("  No new observations found\n")
    obs <- existing_obs
  } else {
    # Incremental fetch failed, do full fetch
    obs <- fetch_obs(fetch_all = fetch_all_observations)
  }
  
} else {
  # Full fetch
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

# Save updated cache and fetch state
if (cache_observations && nrow(obs) > 0) {
  saveRDS(obs, obs_cache_file)
  
  # Save fetch timestamp for next incremental fetch
  fetch_state <- list(
    last_fetch_time = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    total_obs = nrow(obs)
  )
  saveRDS(fetch_state, fetch_state_file)
  cat("Cache updated\n")
}

# FIX 1: Randomize observations AFTER seed is set (already done above)
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

cat("With photos:", nrow(obs_photos), "\n")

# DIAGNOSTIC: Check what photo URLs are being retrieved
if (diagnostic_mode && nrow(obs_photos) > 0) {
  cat("\n=== PHOTO URL DIAGNOSTICS ===\n")
  cat("Checking first 3 observations for available photo URLs:\n\n")
  for (i in 1:min(3, nrow(obs_photos))) {
    cat("Observation", i, "(ID:", obs_photos$obs_id[i], "):\n")
    photo_obj <- obs_photos$photos_list[[i]][[1]]
    cat("  url:", if(!is.null(photo_obj$url)) photo_obj$url else "NULL", "\n")
    cat("  original_url:", if(!is.null(photo_obj$original_url)) photo_obj$original_url else "NULL", "\n")
    cat("  large_url:", if(!is.null(photo_obj$large_url)) photo_obj$large_url else "NULL", "\n")
    cat("  medium_url:", if(!is.null(photo_obj$medium_url)) photo_obj$medium_url else "NULL", "\n")
    cat("  Selected URL:", obs_photos$photo_url[i], "\n\n")
  }
}
cat("\n")

# ==============================================================================
# SAMPLING WITH DIVERSITY
# ==============================================================================

cat("=== SAMPLING ===\n")

n_target <- min(n_photos, nrow(obs_photos))

# Calculate max per observer using BOTH percentage and absolute limits
max_obs_per_observer_pct_calc <- max(1, floor(n_target * max_obs_per_observer_pct))
max_obs_per_observer <- min(max_obs_per_observer_pct_calc, max_obs_per_observer_abs)

max_plants <- floor(n_target * max_plants_pct)

cat("Target:", n_target, "\n")
cat("Observer limits:\n")
cat("  - Percentage-based:", max_obs_per_observer_pct_calc, "(", max_obs_per_observer_pct * 100, "% of", n_target, ")\n")
cat("  - Absolute maximum:", max_obs_per_observer_abs, "\n")
cat("  - ACTUAL LIMIT USED:", max_obs_per_observer, "(using the lower of the two)\n")
cat("Max plants:", max_plants, "\n")
cat("Random seed being used:", if(!is.null(random_seed)) random_seed else "none", "\n\n")

plants_df <- dplyr::filter(obs_photos, iconic_taxon == "Plantae")
other_df <- dplyr::filter(obs_photos, iconic_taxon != "Plantae")
all_df <- bind_rows(plants_df, other_df)

# CRITICAL: Randomize the order of observers to ensure different selections each run
observer_counts <- all_df %>% count(observer) %>% arrange(n)
cat("Observer processing order before randomization:\n")
print(head(observer_counts, 5))

# Randomize observer order while keeping count info
observer_counts <- observer_counts[sample(nrow(observer_counts)), ]
cat("\nObserver processing order after randomization:\n")
print(head(observer_counts, 5))

sampled_list <- list()
n_sampled <- 0

for (obs_name in observer_counts$observer) {
  if (n_sampled >= n_target) break
  
  obs_pool <- all_df %>% filter(observer == obs_name)
  n_to_take <- min(nrow(obs_pool), max_obs_per_observer, n_target - n_sampled)
  
  if (n_to_take > 0) {
    selected <- obs_pool %>% slice_sample(n = n_to_take)
    sampled_list[[length(sampled_list) + 1]] <- selected
    n_sampled <- n_sampled + n_to_take
    
    if (diagnostic_mode && n_sampled <= n_target) {
      cat("  Selected", n_to_take, "from", obs_name, "(total now:", n_sampled, ")\n")
    }
  }
}

sampled <- bind_rows(sampled_list)

cat("\nSelected observation IDs (first 10):", paste(head(sampled$obs_id, 10), collapse = ", "), "\n")

# Apply plant limit and backfill if needed
n_plants <- sum(sampled$iconic_taxon == "Plantae")

if (n_plants > max_plants) {
  cat("Adjusting plants:", n_plants, "->", max_plants, "\n")
  
  # Keep only max_plants plants
  sampled_plants <- sampled %>% filter(iconic_taxon == "Plantae") %>% slice_sample(n = max_plants)
  sampled_other <- sampled %>% filter(iconic_taxon != "Plantae")
  sampled <- bind_rows(sampled_other, sampled_plants)
  
  # Backfill removed slots with non-plants
  n_removed <- n_plants - max_plants
  if (n_removed > 0 && nrow(sampled) < n_target) {
    cat("Backfilling", n_removed, "slots with non-plants...\n")
    
    # Get non-plant observations not already selected
    already_selected_ids <- sampled$obs_id
    available_nonplants <- other_df %>% 
      filter(!obs_id %in% already_selected_ids)
    
    if (nrow(available_nonplants) > 0) {
      # Sample additional non-plants, respecting observer limits
      backfill_needed <- min(n_removed, n_target - nrow(sampled))
      backfill_list <- list()
      
      for (i in 1:backfill_needed) {
        # Find observers who haven't hit their limit yet
        current_counts <- sampled %>% count(observer)
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
      
      if (length(backfill_list) > 0) {
        cat("  Added", length(backfill_list), "non-plant observations\n")
      }
    }
  }
}

cat("\nFinal sample size:", nrow(sampled), "\n")

cat("\nFinal sample:\n")
observer_breakdown <- sampled %>% count(observer) %>% arrange(desc(n))
print(observer_breakdown)
cat("\nObserver diversity check:\n")
cat("  Max photos from one observer:", max(observer_breakdown$n), "\n")
cat("  Number of unique observers:", nrow(observer_breakdown), "\n")
cat("  Target max per observer was:", max_obs_per_observer, "\n")
print(sampled %>% count(iconic_taxon))

# ==============================================================================
# BUILD BASE MAP
# ==============================================================================

cat("\n=== BASE MAP ===\n")

base_map_file <- file.path(base_map_dir, "base_map.tif")
osm_data_file <- file.path(base_map_dir, "osm_overlays.rds")

if (file.exists(base_map_file) && file.exists(osm_data_file) && !force_rebuild_base_map) {
  cat("Loading cached base map\n")
  sat_raster <- terra::rast(base_map_file)
  overlay_data <- readRDS(osm_data_file)
  roads_full <- overlay_data$roads
  waterways_full <- overlay_data$waterways
  
  # Diagnostic info
  ext <- terra::ext(sat_raster)
  cat("  Base map raster loaded\n")
  cat("    Extent (EPSG:3857):\n")
  cat("      X:", ext$xmin, "to", ext$xmax, "\n")
  cat("      Y:", ext$ymin, "to", ext$ymax, "\n")
  cat("    Dimensions:", terra::nrow(sat_raster), "x", terra::ncol(sat_raster), "\n")
  cat("    Layers:", terra::nlyr(sat_raster), "\n")
  
  if (!is.null(roads_full)) cat("  Roads:", nrow(roads_full), "features\n")
  if (!is.null(waterways_full)) cat("  Waterways:", nrow(waterways_full), "features\n")
  
  # Check if preview exists, if not create it
  preview_path <- file.path(base_map_dir, "preview_full_project_map.png")
  if (!file.exists(preview_path)) {
    cat("  Creating diagnostic preview map...\n")
    tryCatch({
      ext <- terra::ext(sat_raster)
      
      p_preview <- ggplot() +
        tidyterra::geom_spatraster_rgb(data = sat_raster) +
        coord_sf(crs = 3857, xlim = c(ext$xmin, ext$xmax), ylim = c(ext$ymin, ext$ymax),
                 expand = FALSE) +
        {if (!is.null(waterways_full) && nrow(waterways_full) > 0) {
          list(
            geom_sf(data = waterways_full, colour = "#4FA3FF", 
                    linewidth = 1.2, alpha = 0.95, inherit.aes = FALSE),
            annotate("text", x = ext$xmin + (ext$xmax - ext$xmin) * 0.02,
                     y = ext$ymax - (ext$ymax - ext$ymin) * 0.05,
                     label = paste("Waterways:", nrow(waterways_full)),
                     hjust = 0, colour = "#4FA3FF", size = 4, fontface = "bold")
          )
        }} +
        {if (!is.null(roads_full) && nrow(roads_full) > 0) {
          list(
            geom_sf(data = roads_full, colour = "gold", 
                    linewidth = 0.8, alpha = 0.9, inherit.aes = FALSE),
            annotate("text", x = ext$xmin + (ext$xmax - ext$xmin) * 0.02,
                     y = ext$ymax - (ext$ymax - ext$ymin) * 0.1,
                     label = paste("Roads:", nrow(roads_full)),
                     hjust = 0, colour = "gold", size = 4, fontface = "bold")
          )
        }} +
        ggspatial::annotation_scale(
          location = "bl",
          width_hint = 0.2,
          style = "bar",
          bar_cols = c("white", "white"),
          text_col = "white"
        ) +
        ggspatial::annotation_north_arrow(
          location = "tr",
          style = ggspatial::north_arrow_fancy_orienteering,
          height = unit(1.5, "cm"),
          width = unit(1.5, "cm")
        ) +
        labs(title = "Project Area Base Map with OSM Overlays",
             subtitle = paste0("Satellite extent: ",
                               round((ext$xmax - ext$xmin)/1000, 1), " x ",
                               round((ext$ymax - ext$ymin)/1000, 1), " km")) +
        theme_void() +
        theme(
          plot.title = element_text(hjust = 0.5, size = 16, color = "white", face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, size = 12, color = "white"),
          plot.background = element_rect(fill = "black"),
          plot.margin = margin(10, 10, 10, 10)
        )
      
      ggsave(preview_path, p_preview, width = 16, height = 12, dpi = 150, units = "in")
      if (file.exists(preview_path)) {
        cat("  Preview map saved:", basename(preview_path), "\n")
      }
    }, error = function(e) {
      cat("  Preview map creation failed:", conditionMessage(e), "\n")
    })
  } else {
    cat("  Preview map exists:", basename(preview_path), "\n")
  }
} else {
  cat("Building base map with OSM overlays...\n")
  
  coords <- sampled %>% filter(!is.na(longitude), !is.na(latitude))
  
  # Calculate bounding box with buffer
  buffer_deg <- buffer_km / 111
  
  # Create bbox ensuring we have valid coordinates
  cat("  Coordinate range:\n")
  cat("    Longitude:", min(coords$longitude), "to", max(coords$longitude), "\n")
  cat("    Latitude:", min(coords$latitude), "to", max(coords$latitude), "\n")
  
  project_bbox <- sf::st_bbox(c(
    xmin = min(coords$longitude) - buffer_deg,
    ymin = min(coords$latitude) - buffer_deg,
    xmax = max(coords$longitude) + buffer_deg,
    ymax = max(coords$latitude) + buffer_deg
  ), crs = 4326)
  
  cat("  Buffered bbox (WGS84):\n")
  cat("    X:", project_bbox["xmin"], "to", project_bbox["xmax"], "\n")
  cat("    Y:", project_bbox["ymin"], "to", project_bbox["ymax"], "\n")
  
  bbox_sf <- sf::st_as_sfc(project_bbox)
  bbox_3857 <- sf::st_transform(bbox_sf, 3857)
  bbox_3857_coords <- sf::st_bbox(bbox_3857)
  
  cat("  Transformed bbox (EPSG:3857):\n")
  cat("    X:", bbox_3857_coords["xmin"], "to", bbox_3857_coords["xmax"], "\n")
  cat("    Y:", bbox_3857_coords["ymin"], "to", bbox_3857_coords["ymax"], "\n")
  
  cat("  Downloading base map tiles (provider:", map_provider, ")...\n")
  sat_raster <- maptiles::get_tiles(
    x = bbox_sf,
    provider = map_provider,
    zoom = base_map_zoom,
    crop = TRUE,
    cachedir = tempdir(),
    verbose = TRUE
  )
  
  cat("  Base map tiles downloaded\n")
  cat("    Dimensions:", terra::nrow(sat_raster), "x", terra::ncol(sat_raster), "\n")
  cat("    Layers:", terra::nlyr(sat_raster), "\n")
  
  # Check and reproject if needed
  sat_crs <- terra::crs(sat_raster, describe = TRUE)$code
  cat("    CRS:", sat_crs, "\n")
  
  if (sat_crs != "3857") {
    cat("  Reprojecting to EPSG:3857...\n")
    sat_raster <- terra::project(sat_raster, "EPSG:3857", method = "bilinear")
  }
  
  sat_ext <- terra::ext(sat_raster)
  cat("  Final satellite extent (EPSG:3857):\n")
  cat("    X:", sat_ext$xmin, "to", sat_ext$xmax, "\n")
  cat("    Y:", sat_ext$ymin, "to", sat_ext$ymax, "\n")
  
  roads_full <- NULL
  waterways_full <- NULL
  
  if (!skip_osm_overlays) {
    cat("  Fetching OSM overlays...\n")
    osmdata::set_overpass_url("https://overpass-api.de/api/interpreter")
    
    # Use the WGS84 bbox for OSM queries - fetch a bit extra to ensure full coverage
    osm_bbox <- as.numeric(project_bbox)
    cat("    Using bbox for OSM:", paste(osm_bbox, collapse = ", "), "\n")
    
    # Get the actual satellite extent to clip OSM data
    sat_ext <- terra::ext(sat_raster)
    
    # Create bbox - simplest reliable method
    sat_bbox_3857 <- c(
      xmin = as.numeric(sat_ext$xmin),
      ymin = as.numeric(sat_ext$ymin),
      xmax = as.numeric(sat_ext$xmax),
      ymax = as.numeric(sat_ext$ymax)
    )
    class(sat_bbox_3857) <- "bbox"
    attr(sat_bbox_3857, "crs") <- sf::st_crs(3857)
    
    cat("    Will clip OSM data to satellite extent (EPSG:3857):\n")
    cat("      X:", sat_bbox_3857["xmin"], "to", sat_bbox_3857["xmax"], "\n")
    cat("      Y:", sat_bbox_3857["ymin"], "to", sat_bbox_3857["ymax"], "\n")
    
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
      } else {
        cat("      No road features found\n")
        NULL
      }
    }, error = function(e) { 
      cat("      Roads fetch failed:", conditionMessage(e), "\n")
      NULL 
    })
    
    if (!is.null(roads_raw) && nrow(roads_raw) > 0) {
      roads_full <- tryCatch({
        r <- sf::st_transform(roads_raw, 3857)
        r <- sf::st_make_valid(r)
        r <- r[sf::st_is_valid(r) & !sf::st_is_empty(r), ]
        cat("      Transformed:", nrow(r), "valid road features\n")
        
        # Clip to satellite extent
        r_clipped <- sf::st_crop(r, sat_bbox_3857)
        cat("      Clipped to satellite extent:", nrow(r_clipped), "road features\n")
        r_clipped
      }, error = function(e) { 
        cat("      Road processing failed:", conditionMessage(e), "\n")
        NULL 
      })
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
      } else {
        cat("      No waterway features found\n")
        NULL
      }
    }, error = function(e) { 
      cat("      Waterways fetch failed:", conditionMessage(e), "\n")
      NULL 
    })
    
    if (!is.null(waterways_raw) && nrow(waterways_raw) > 0) {
      waterways_full <- tryCatch({
        w <- sf::st_transform(waterways_raw, 3857)
        w <- sf::st_make_valid(w)
        w <- w[sf::st_is_valid(w) & !sf::st_is_empty(w), ]
        cat("      Transformed:", nrow(w), "valid waterway features\n")
        
        # Clip to satellite extent
        w_clipped <- sf::st_crop(w, sat_bbox_3857)
        cat("      Clipped to satellite extent:", nrow(w_clipped), "waterway features\n")
        w_clipped
      }, error = function(e) { 
        cat("      Waterway processing failed:", conditionMessage(e), "\n")
        NULL 
      })
    }
    
    cat("  OSM fetching complete\n")
    if (!is.null(roads_full)) cat("    Roads ready:", nrow(roads_full), "features (clipped to satellite)\n")
    if (!is.null(waterways_full)) cat("    Waterways ready:", nrow(waterways_full), "features (clipped to satellite)\n")
  }
  
  cat("  Saving base map cache...\n")
  terra::writeRaster(sat_raster, base_map_file, overwrite = TRUE,
                     gdal = c("COMPRESS=LZW", "TILED=YES"))
  saveRDS(list(roads = roads_full, waterways = waterways_full), osm_data_file)
  cat("  Base map saved\n")
  
  # Create diagnostic preview map
  cat("  Creating diagnostic preview map...\n")
  preview_path <- file.path(base_map_dir, "preview_full_project_map.png")
  
  tryCatch({
    ext <- terra::ext(sat_raster)
    
    # Create preview plot
    p_preview <- ggplot() +
      tidyterra::geom_spatraster_rgb(data = sat_raster) +
      coord_sf(crs = 3857, xlim = c(ext$xmin, ext$xmax), ylim = c(ext$ymin, ext$ymax),
               expand = FALSE) +
      {if (!is.null(waterways_full) && nrow(waterways_full) > 0) {
        list(
          geom_sf(data = waterways_full, colour = "#4FA3FF", 
                  linewidth = 1.2, alpha = 0.95, inherit.aes = FALSE),
          annotate("text", x = ext$xmin + (ext$xmax - ext$xmin) * 0.02, 
                   y = ext$ymax - (ext$ymax - ext$ymin) * 0.05,
                   label = paste("Waterways:", nrow(waterways_full)), 
                   hjust = 0, colour = "#4FA3FF", size = 4, fontface = "bold")
        )
      }} +
      {if (!is.null(roads_full) && nrow(roads_full) > 0) {
        list(
          geom_sf(data = roads_full, colour = "gold", 
                  linewidth = 0.8, alpha = 0.9, inherit.aes = FALSE),
          annotate("text", x = ext$xmin + (ext$xmax - ext$xmin) * 0.02,
                   y = ext$ymax - (ext$ymax - ext$ymin) * 0.1,
                   label = paste("Roads:", nrow(roads_full)),
                   hjust = 0, colour = "gold", size = 4, fontface = "bold")
        )
      }} +
      ggspatial::annotation_scale(
        location = "bl",
        width_hint = 0.2,
        style = "bar",
        bar_cols = c("white", "white"),
        text_col = "white"
      ) +
      ggspatial::annotation_north_arrow(
        location = "tr",
        style = ggspatial::north_arrow_fancy_orienteering,
        height = unit(1.5, "cm"),
        width = unit(1.5, "cm")
      ) +
      labs(title = "Project Area Base Map with OSM Overlays",
           subtitle = paste0("Satellite extent: ", 
                             round((ext$xmax - ext$xmin)/1000, 1), " x ", 
                             round((ext$ymax - ext$ymin)/1000, 1), " km")) +
      theme_void() +
      theme(
        plot.title = element_text(hjust = 0.5, size = 16, color = "white", face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 12, color = "white"),
        plot.background = element_rect(fill = "black"),
        plot.margin = margin(10, 10, 10, 10)
      )
    
    ggsave(preview_path, p_preview, width = 16, height = 12, dpi = 150, units = "in")
    
    if (file.exists(preview_path)) {
      cat("  Preview map saved:", basename(preview_path), "\n")
      cat("  Base map extent (EPSG:3857):\n")
      cat("    X:", ext$xmin, "to", ext$xmax, "\n")
      cat("    Y:", ext$ymin, "to", ext$ymax, "\n")
      cat("    Size:", round((ext$xmax - ext$xmin)/1000, 1), "x", 
          round((ext$ymax - ext$ymin)/1000, 1), "km\n")
    }
  }, error = function(e) {
    cat("  Preview map creation failed:", conditionMessage(e), "\n")
  })
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
    ext = ifelse(grepl("\\.png", photo_url, ignore.case = TRUE), "png", "jpg"),
    photo_file_abs = file.path(photos_dir, sprintf("obs_%s.%s", obs_id, ext))
  )

# Check photo manifest for previously downloaded URLs
if (nrow(photo_manifest) > 0) {
  samples <- samples %>%
    left_join(photo_manifest %>% select(photo_url, photo_file_cached = photo_file), 
              by = "photo_url")
} else {
  samples <- samples %>%
    mutate(photo_file_cached = NA_character_)
}

# Check if we can reuse existing files
samples <- samples %>%
  mutate(
    existing_file = ifelse(
      !is.na(photo_file_cached) & file.exists(file.path(photos_dir, photo_file_cached)),
      file.path(photos_dir, photo_file_cached),
      NA_character_
    ),
    photo_exists = !is.na(existing_file) | file.exists(photo_file_abs)
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
need_download <- !samples$photo_exists

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

# DIAGNOSTIC: Check downloaded image sizes
if (diagnostic_mode && nrow(samples) > 0) {
  cat("\n=== DOWNLOADED IMAGE SIZE DIAGNOSTICS ===\n")
  cat("Checking first 3 downloaded images:\n")
  for (i in 1:min(3, nrow(samples))) {
    if (file.exists(samples$photo_file_abs[i])) {
      img_info <- file.info(samples$photo_file_abs[i])
      img <- try(magick::image_read(samples$photo_file_abs[i]), silent = TRUE)
      if (!inherits(img, "try-error")) {
        img_geom <- magick::image_info(img)
        cat("  Photo", i, "(obs", samples$obs_id[i], "):\n")
        cat("    File size:", round(img_info$size / 1024, 1), "KB\n")
        cat("    Dimensions:", img_geom$width, "x", img_geom$height, "pixels\n")
        cat("    URL:", samples$photo_url[i], "\n\n")
      }
    }
  }
  cat("\n")
}

new_entries <- samples %>%
  filter(photo_exists) %>%
  select(photo_url, photo_file_abs) %>%
  mutate(photo_file = basename(photo_file_abs)) %>%
  select(photo_url, photo_file)

photo_manifest <- bind_rows(photo_manifest, new_entries) %>%
  distinct(photo_url, .keep_all = TRUE)

saveRDS(photo_manifest, photo_manifest_file)

samples <- samples %>%
  filter(photo_exists) %>%
  mutate(
    date_label = suppressWarnings(lubridate::ymd(observed_on)) %>% format("%A, %d %b %Y"),
    cap_common = ifelse(!is.na(common_name) & nzchar(common_name), common_name, ""),
    cap_sci = ifelse(!is.na(sci_name) & nzchar(sci_name), sci_name, ""),
    cap_obs = paste0("Observed by ", ifelse(is.na(observer), "Unknown", observer))
  )

cat("Ready:", nrow(samples), "photos\n")

# ==============================================================================
# CREATE MAPS
# ==============================================================================

cat("\n=== CREATING MAPS ===\n")

# FIX 2: Improved map creation with better error reporting
safe_make_map <- function(lon, lat, out_path, obs_id = NULL) {
  tryCatch({
    if (is.na(lon) || is.na(lat)) {
      if (diagnostic_mode) cat("  Obs", obs_id, "- Missing coordinates\n")
      return(FALSE)
    }
    
    if (diagnostic_mode) cat("  Obs", obs_id, "- Creating map...\n")
    
    obs_ll <- sf::st_sfc(sf::st_point(c(lon, lat)), crs = 4326)
    hq_ll <- sf::st_sfc(sf::st_point(c(hq_lon, hq_lat)), crs = 4326)
    obs_m <- sf::st_transform(obs_ll, 3857)
    hq_m <- sf::st_transform(hq_ll, 3857)
    
    dist <- as.numeric(sf::st_distance(obs_m, hq_m))
    radius <- max(default_dist_m, dist / 2 + 1000)
    
    box_m <- sf::st_union(sf::st_buffer(obs_m, radius), sf::st_buffer(hq_m, radius))
    bbox_m <- sf::st_bbox(box_m)
    
    # Create extent using vector format (terra::ext expects a vector, not named args)
    crop_ext <- terra::ext(c(
      bbox_m["xmin"],
      bbox_m["xmax"],
      bbox_m["ymin"],
      bbox_m["ymax"]
    ))
    
    # Check if sat_raster exists
    if (!exists("sat_raster")) {
      if (diagnostic_mode) cat("  Obs", obs_id, "- ERROR: Base map not loaded\n")
      return(FALSE)
    }
    
    rast_crop <- terra::crop(sat_raster, crop_ext)
    
    if (is.null(rast_crop) || !terra::hasValues(rast_crop)) {
      if (diagnostic_mode) cat("  Obs", obs_id, "- ERROR: Failed to crop raster\n")
      return(FALSE)
    }
    
    ext <- terra::ext(rast_crop)
    xmin <- ext$xmin; xmax <- ext$xmax
    ymin <- ext$ymin; ymax <- ext$ymax
    
    roads_crop <- NULL
    if (!is.null(roads_full) && nrow(roads_full) > 0) {
      roads_crop <- tryCatch({
        r <- sf::st_crop(roads_full, bbox_m)
        if (nrow(r) > 0) r else NULL
      }, error = function(e) NULL)
    }
    
    waterways_crop <- NULL
    if (!is.null(waterways_full) && nrow(waterways_full) > 0) {
      waterways_crop <- tryCatch({
        w <- sf::st_crop(waterways_full, bbox_m)
        if (nrow(w) > 0) w else NULL
      }, error = function(e) NULL)
    }
    
    obs_coords <- sf::st_coordinates(obs_m)
    hq_coords <- sf::st_coordinates(hq_m)
    
    p <- ggplot() +
      tidyterra::geom_spatraster_rgb(data = rast_crop) +
      coord_sf(crs = 3857, xlim = c(xmin, xmax), ylim = c(ymin, ymax), 
               expand = FALSE, clip = "on") +
      {if (!is.null(waterways_crop) && nrow(waterways_crop) > 0) {
        geom_sf(data = waterways_crop, colour = "#4FA3FF", 
                linewidth = 1.2, alpha = 0.95, inherit.aes = FALSE)
      }} +
      {if (!is.null(roads_crop) && nrow(roads_crop) > 0) {
        geom_sf(data = roads_crop, colour = "gold", 
                linewidth = 0.9, alpha = 0.95, inherit.aes = FALSE)
      }} +
      ggspatial::annotation_scale(
        location = "bl",
        width_hint = 0.25,
        style = "bar",
        bar_cols = c("white", "white"),
        line_width = 0,
        text_cex = 0.9,
        text_col = "white"
      ) +
      geom_point(aes(x = hq_coords[1], y = hq_coords[2]),
                 colour = "yellow", fill = "orange", shape = 23, size = 4.8, stroke = 1.3,
                 inherit.aes = FALSE) +
      geom_text(aes(x = hq_coords[1], y = hq_coords[2]), label = "HQ",
                vjust = -1.2, colour = "yellow", fontface = "bold", size = 4.2,
                inherit.aes = FALSE) +
      geom_point(aes(x = obs_coords[1], y = obs_coords[2]),
                 colour = "white", shape = 21, size = 6.5, stroke = 2.2, alpha = 0.55,
                 inherit.aes = FALSE) +
      geom_point(aes(x = obs_coords[1], y = obs_coords[2]),
                 colour = "#FF0000", shape = 8, size = 5.2, stroke = 1.2,
                 inherit.aes = FALSE) +
      theme_void() +
      theme(plot.margin = margin(0, 0, 0, 0))
    
    ggsave(out_path, p, width = 12.8, height = 8.8, dpi = 150, units = "in")
    
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
  mutate(
    map_file = file.path(maps_dir, sprintf("map_%s.png", obs_id)),
    map_ok = file.exists(map_file)
  )

need_map <- !samples$map_ok | force_rebuild_maps
if (any(need_map)) {
  cat("Creating", sum(need_map), "maps (", sum(samples$map_ok & !force_rebuild_maps), "exist)...\n")
  
  map_results <- rep(FALSE, nrow(samples))
  for (i in which(need_map)) {
    map_results[i] <- safe_make_map(
      samples$longitude[i], 
      samples$latitude[i], 
      samples$map_file[i],
      samples$obs_id[i]
    )
  }
  
  samples$map_ok <- file.exists(samples$map_file)
  
  n_success <- sum(map_results)
  n_failed <- sum(need_map) - n_success
  cat("Maps created:", n_success, "successful,", n_failed, "failed\n")
  
  if (n_failed > 0 && diagnostic_mode) {
    failed_ids <- samples$obs_id[which(need_map)[!map_results]]
    cat("Failed observation IDs:", paste(failed_ids, collapse = ", "), "\n")
  }
} else {
  cat("All", nrow(samples), "maps exist\n")
}

# ==============================================================================
# COMPOSE SLIDES
# ==============================================================================

cat("\n=== COMPOSING SLIDES ===\n")

compose_slide <- function(photo_path, map_path, date, common, sci, obs_by, out_path) {
  tryCatch({
    p <- magick::image_read(photo_path)
    info_p <- magick::image_info(p)
    
    w <- 880; h <- 600
    
    if (info_p$width > w || info_p$height > h) {
      p <- magick::image_resize(p, paste0(w, "x", h, "^"))
    }
    p2 <- magick::image_extent(p, paste0(w, "x", h), "center", "black")
    
    if (file.exists(map_path)) {
      m <- magick::image_read(map_path)
      info_m <- magick::image_info(m)
      if (info_m$width > w || info_m$height > h) {
        m <- magick::image_resize(m, paste0(w, "x", h, "^"))
      }
      m2 <- magick::image_extent(m, paste0(w, "x", h), "center", "black")
    } else {
      m2 <- magick::image_blank(w, h, "black")
    }
    
    bg <- magick::image_blank(1920, 1080, "black")
    bg <- magick::image_composite(bg, p2, offset = "+20+140")
    bg <- magick::image_composite(bg, m2, offset = "+920+140")
    
    bg <- magick::image_annotate(bg, date, size = 48, color = "white", weight = 700, 
                                 gravity = "north", location = "+0+30")
    
    y <- 760
    if (nzchar(common)) {
      bg <- magick::image_annotate(bg, common, size = 44, color = "white", 
                                   gravity = "northwest", location = sprintf("+20+%d", y))
      y <- y + 50
    }
    if (nzchar(sci)) {
      bg <- magick::image_annotate(bg, sci, size = 44, color = "#9BD1FF", style = "italic", 
                                   gravity = "northwest", location = sprintf("+20+%d", y))
      y <- y + 50
    }
    if (nzchar(obs_by)) {
      bg <- magick::image_annotate(bg, obs_by, size = 44, color = "#FFE066", 
                                   gravity = "northwest", location = sprintf("+20+%d", y))
    }
    
    bg <- magick::image_convert(bg, format = "png", type = "TrueColor", depth = 8)
    magick::image_write(bg, out_path, format = "png", quality = 85, compression = "Zip")
    
    TRUE
  }, error = function(e) FALSE)
}

samples <- samples %>%
  mutate(
    slide_file = file.path(compo_dir, sprintf("slide_%s.png", obs_id)),
    slide_ok = file.exists(slide_file)
  )

need_slide <- !samples$slide_ok | force_rebuild_slides
if (any(need_slide)) {
  cat("Composing", sum(need_slide), "slides (", sum(samples$slide_ok & !force_rebuild_slides), "exist)...\n")
  for (i in which(need_slide)) {
    compose_slide(
      samples$photo_file_abs[i],
      samples$map_file[i],
      samples$date_label[i],
      samples$cap_common[i],
      samples$cap_sci[i],
      samples$cap_obs[i],
      samples$slide_file[i]
    )
  }
} else {
  cat("All", nrow(samples), "slides exist\n")
}

samples <- samples %>% filter(file.exists(slide_file))

# ==============================================================================
# CREATE COLLAGE
# ==============================================================================

cat("\n=== CREATING COLLAGE ===\n")

collage_file <- file.path(out_dir, "collage.png")
photos_for_collage <- unique(samples$photo_file_abs)
n_collage <- min(length(photos_for_collage), max_collage)
photos_for_collage <- photos_for_collage[1:n_collage]

make_collage <- function(paths, out_path, max_w = 1920, max_h = 1080, gap = 8) {
  k <- length(paths)
  if (k == 0) return(FALSE)
  
  cols <- ceiling(sqrt(k))
  rows <- ceiling(k / cols)
  
  tw <- floor((max_w - (cols + 1) * gap) / cols)
  th <- floor((max_h - (rows + 1) * gap) / rows)
  
  canvas <- magick::image_blank(max_w, max_h, color = "black")
  
  for (i in seq_len(k)) {
    img <- try(magick::image_read(paths[i]), silent = TRUE)
    if (inherits(img, "try-error")) next
    
    img <- magick::image_extent(
      magick::image_resize(img, paste0(tw, "x", th, "^")),
      paste0(tw, "x", th),
      gravity = "center",
      color = "black"
    )
    
    r <- (i - 1) %/% cols
    c <- (i - 1) %% cols
    x <- gap + c * (tw + gap)
    y <- gap + r * (th + gap)
    
    canvas <- magick::image_composite(canvas, img, offset = sprintf("+%d+%d", x, y))
  }
  
  magick::image_write(canvas, out_path, format = "png")
  file.exists(out_path)
}

collage_ok <- make_collage(photos_for_collage, collage_file)
if (collage_ok) {
  cat("Collage created:", n_collage, "photos\n")
} else {
  cat("Collage creation failed\n")
}

# ==============================================================================
# GENERATE QMD
# ==============================================================================

cat("\n=== GENERATING QMD ===\n")

css_text <- '
:root { --accent:#4FD1C5; --text:#F7FAFC; --muted:#CBD5E0; --bioblitz-green:#90EE90; }
.reveal { font-family: "Montserrat","Open Sans",sans-serif; }
.reveal .slides { background: radial-gradient(1200px 700px at 60% 40%, #0b1b2a 0%, #040a11 60%, #000 100%); }
.reveal section h1, .reveal section h2, .reveal section h3 { color: var(--text); letter-spacing: 0.5px; }
.reveal p, .reveal li { color: var(--muted); }
.slide-img { width: 100%; border-radius: 18px; box-shadow: 0 10px 40px rgba(0,0,0,0.55); display:block; }
.reveal .welcome-slide {
  display: flex !important;
  flex-direction: column !important;
  align-items: center !important;
  justify-content: center !important;
  gap: 2rem !important;
}
.reveal .welcome-slide .logo-container {
  max-width: 400px;
  margin-bottom: 1rem;
}
.reveal .welcome-slide img {
  width: 100%;
  height: auto;
  border-radius: 12px;
  box-shadow: 0 8px 30px rgba(0,0,0,0.4);
}
.reveal .welcome-slide h1 {
  color: var(--bioblitz-green) !important;
  font-size: 2.5rem !important;
  font-weight: 600 !important;
  margin: 0.5rem 0 !important;
  text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
}
.reveal .welcome-slide p {
  color: var(--text) !important;
  font-size: 1.5rem !important;
  margin: 0 !important;
}
.reveal .taxon-title h2 { 
  font-size: 2.5rem !important;
  font-weight: 400 !important;
  margin: 0 !important;
  padding: 0 !important;
  position: absolute !important;
  top: 50% !important;
  left: 50% !important;
  transform: translate(-50%, -50%) !important;
  width: 90% !important;
  text-align: center !important;
}
.taxon-plantae .slide-img { border: 3px solid #4CAF50; }
.taxon-insecta .slide-img { border: 3px solid #FF9800; }
.taxon-animalia .slide-img { border: 3px solid #9C27B0; }
.taxon-aves .slide-img { border: 3px solid #2196F3; }
.taxon-arachnida .slide-img { border: 3px solid #F44336; }
.taxon-amphibia .slide-img { border: 3px solid #00BCD4; }
.taxon-reptilia .slide-img { border: 3px solid #8BC34A; }
.taxon-mammalia .slide-img { border: 3px solid #795548; }
.taxon-mollusca .slide-img { border: 3px solid #E91E63; }
.taxon-fungi .slide-img { border: 3px solid #FFC107; }
.taxon-actinopterygii .slide-img { border: 3px solid #03A9F4; }
.taxon-protozoa .slide-img { border: 3px solid #CDDC39; }
.taxon-chromista .slide-img { border: 3px solid #FF5722; }
.taxon-unknown .slide-img { border: 3px solid #9E9E9E; }
'
writeLines(css_text, file.path(styles_dir, "custom.css"))

taxon_icons <- c(
  "Plantae"="🪻","Animalia"="🐾","Aves"="🦜","Insecta"="🦋","Arachnida"="🕷️","Amphibia"="🐸","Reptilia"="🦎",
  "Mammalia"="🦘","Mollusca"="🐚","Fungi"="🍄","Actinopterygii"="🐠","Protozoa"="🔬","Chromista"="🧫","Unknown"="❓"
)

grouped <- split(samples, samples$iconic_taxon)
taxon_order <- names(sort(sapply(grouped, nrow), decreasing = TRUE))

build_slides <- function() {
  slides <- ""
  for (tx in taxon_order) {
    df <- grouped[[tx]]
    icon <- if (!is.null(taxon_icons[[tx]])) taxon_icons[[tx]] else ""
    
    taxon_class <- paste0("taxon-", tolower(gsub("[^a-z0-9]", "", tolower(tx))))
    
    # Create taxon title slide with proper formatting
    slides <- paste0(slides, "\n## ", tx, " ", icon, " {.taxon-title data-transition=\"fade\"}\n\n")
    
    for (i in 1:nrow(df)) {
      slide_rel <- url_path("slides", basename(df$slide_file[i]))
      slides <- paste0(slides, "## {.", taxon_class, " data-transition=\"fade\"}\n\n![](", slide_rel, "){.slide-img}\n\n")
    }
  }
  slides
}

slides_content <- build_slides()

collage_block <- if (collage_ok) {
  paste0("\n## Isn't the ", bioblitz_name, " Amazing?\n\n![](collage.png)\n")
} else {
  ""
}

# Copy logo to output directory if it exists
logo_dest <- NA
if (file.exists(bioblitz_logo)) {
  logo_dest <- file.path(out_dir, basename(bioblitz_logo))
  if (!file.exists(logo_dest) || fresh_run) {
    file.copy(bioblitz_logo, logo_dest, overwrite = TRUE)
    cat("Logo copied to output directory\n")
  }
  logo_rel <- basename(bioblitz_logo)
} else {
  cat("Warning: Logo file not found:", bioblitz_logo, "\n")
  logo_rel <- ""
}

# Create welcome slide content
welcome_content <- if (nzchar(logo_rel)) {
  paste0('# {.welcome-slide}

<div class="logo-container">
![](', logo_rel, ')
</div>

# ', bioblitz_name, ' Bioblitz ', bioblitz_year, '

A random selection of photos from our amazing biodiversity survey.
')
} else {
  paste0('# Welcome {.welcome-slide}

# ', bioblitz_name, ' Bioblitz ', bioblitz_year, '

A random selection of photos from our amazing biodiversity survey.
')
}

qmd_content <- paste0('---
title: ""
format:
  revealjs:
    theme: [simple, night]
    slide-number: true
    transition: slide
    controls: true
    auto-slide: ', auto_advance_ms, '
    auto-slide-stoppable: ', tolower(auto_slide_stoppable), '
    loop: ', tolower(slideshow_loop), '
css: styles/custom.css
---

',
                      welcome_content,
                      slides_content,
                      collage_block
)

qmd_file <- file.path(out_dir, "slideshow.qmd")
writeLines(qmd_content, qmd_file)
cat("QMD created:", qmd_file, "\n")
if (nzchar(logo_rel)) {
  cat("Logo included in slideshow\n")
}

# ==============================================================================
# RENDER HTML & PDF
# ==============================================================================

cat("\n=== RENDERING ===\n")

html_file <- file.path(out_dir, "slideshow.html")
pdf_file <- file.path(out_dir, "slideshow.pdf")

if (requireNamespace("quarto", quietly = TRUE)) {
  cat("Rendering HTML...\n")
  tryCatch({
    quarto::quarto_render(qmd_file, quiet = FALSE)
    cat("HTML rendered\n")
  }, error = function(e) {
    cat("Quarto render failed:", conditionMessage(e), "\n")
  })
} else {
  cat("Quarto package not available\n")
}

if (file.exists(html_file)) {
  
  # Check if PDF creation should be attempted
  should_create_pdf <- create_pdf
  
  if (create_pdf && pdf_size_limit_mb > 0) {
    # Estimate PDF size: roughly 150KB per slide (conservative estimate)
    estimated_size_mb <- (nrow(samples) * 150) / 1024
    cat("\nEstimated PDF size:", round(estimated_size_mb, 1), "MB\n")
    
    if (estimated_size_mb > pdf_size_limit_mb) {
      cat("  Skipping PDF creation - estimated size exceeds limit of", pdf_size_limit_mb, "MB\n")
      cat("  To create PDF anyway, set pdf_size_limit_mb = 0 or increase the limit\n")
      should_create_pdf <- FALSE
    }
  }
  
  if (should_create_pdf) {
    cat("\nAttempting PDF creation...\n")
    
    # Check if PDF file is currently open/locked
    if (file.exists(pdf_file)) {
      can_write <- tryCatch({
        # Try to open the file for writing
        con <- file(pdf_file, "w")
        close(con)
        TRUE
      }, error = function(e) FALSE)
      
      if (!can_write) {
        cat("  WARNING: Existing PDF appears to be open in another program\n")
        cat("  Please close the PDF file and try again, or the old version will be used\n")
        cat("  File location:", normalizePath(pdf_file), "\n\n")
        should_create_pdf <- FALSE
      }
    }
  }
  
  if (should_create_pdf && requireNamespace("pagedown", quietly = TRUE)) {
    tryCatch({
      cat("  Using pagedown::chrome_print...\n")
      cat("  (This requires Chrome/Chromium to be installed)\n")
      pagedown::chrome_print(html_file, pdf_file, verbose = 1)
      if (file.exists(pdf_file)) {
        file_size_mb <- file.info(pdf_file)$size / (1024^2)
        cat("  PDF created successfully! (", round(file_size_mb, 1), "MB)\n")
      } else {
        cat("  PDF file not found after chrome_print\n")
      }
    }, error = function(e) {
      cat("  pagedown failed:", conditionMessage(e), "\n")
      if (grepl("overwritten|locked", conditionMessage(e), ignore.case = TRUE)) {
        cat("\n  The PDF file is open in another program!\n")
        cat("  Please close:", normalizePath(pdf_file), "\n")
        cat("  Then run the script again, or set create_pdf = FALSE\n")
      } else {
        cat("  Common causes:\n")
        cat("    - Chrome/Chromium not installed or not in PATH\n")
        cat("    - pagedown can't find Chrome executable\n")
      }
    })
  } else if (!create_pdf) {
    cat("\nPDF creation disabled (create_pdf = FALSE)\n")
  } else if (!should_create_pdf) {
    cat("\nPDF creation skipped\n")
  } else {
    cat("\n  pagedown package not available\n")
  }
  
  if (!file.exists(pdf_file)) {
    cat("\n  PDF not created.\n")
    cat("  To create PDF manually:\n")
    cat("    1. Close any open PDF viewers showing this file\n")
    cat("    2. Open the HTML file in your browser:\n")
    cat("       ", normalizePath(html_file), "\n")
    cat("    3. Press 'E' to enter PDF export mode (removes controls)\n")
    cat("    4. Use browser's Print to PDF:\n")
    cat("       - Chrome: Ctrl+P > Save as PDF\n")
    cat("       - Firefox: Ctrl+P > Print to PDF\n")
  }
}

# ==============================================================================
# COMPLETE
# ==============================================================================

cat("\n=== COMPLETE ===\n")
cat("Created", nrow(samples), "slides\n")
cat("Output:", normalizePath(out_dir), "\n")
if (file.exists(html_file)) cat("HTML:", basename(html_file), "\n")
if (file.exists(pdf_file)) cat("PDF:", basename(pdf_file), "\n")
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