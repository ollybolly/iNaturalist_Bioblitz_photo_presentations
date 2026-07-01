# iNaturalist Bioblitz Slideshow Generator
## Complete User Guide

**Version 4**

---

## Table of contents

1. [Introduction](#introduction)
2. [Choosing your method: app or script](#choosing-your-method-app-or-script)
3. [What the software does](#what-the-software-does)
4. [Prerequisites](#prerequisites)
5. [The companion style file](#the-companion-style-file)
6. [Method 1: using the Shiny app](#method-1-using-the-shiny-app)
   - [Launching the app](#launching-the-app)
   - [Configuration tab](#configuration-tab)
   - [Run and progress tab](#run-and-progress-tab)
   - [Outputs tab](#outputs-tab)
   - [Daily updates with the app](#daily-updates-with-the-app)
7. [Method 2: using the R script](#method-2-using-the-r-script)
8. [Configuration reference](#configuration-reference)
9. [Output files](#output-files)
10. [Troubleshooting](#troubleshooting)
11. [Tips and best practices](#tips-and-best-practices)
12. [Advanced topics](#advanced-topics)

---

## Introduction

This software builds a photo slideshow from an iNaturalist bioblitz project. It downloads photos, makes a satellite location map for each observation, composes the two into a slide, and assembles everything into an interactive reveal.js HTML presentation with a closing collage. It works for any bioblitz project worldwide, not just the one it was first written for.

Each slideshow includes:

- A random, diverse selection of observations, with per-observer and plant limits.
- A satellite map per photo showing the find location, your HQ, and nearby roads and waterways.
- Slides grouped by iconic taxon groups, each with a PhyloPic taxon silhouette baked in.
- Auto-advancing, loopable playback, ideal for a screen at your event.
- Your bioblitz name and the observation dates on the welcome slide.
- Optional PDF export.

**Who is this for?** Anyone who wants to make a bioblitz slideshow, with or without R experience.

**What changed in version 4**

- The engine now loads a shared style file, `bioblitz_style.R`, for the palette and taxon icons. It must sit next to the script (see [The companion style file](#the-companion-style-file)).
- The app browses for the script and output folder rather than asking you to type file names, and it checks the style file is present before running.
- Two new controls: **map edge padding** and **rebuild taxon icons**.
- Quick presets, seed reuse helpers, and a housekeeping panel for clearing cached images.
- A refreshed Wes Anderson "Zissou1" look.

---

## Choosing your method: app or script

### Shiny app (recommended for most users)

Choose the app if you prefer point-and-click over editing code, want live progress, are running a multi-day event, or like saving and reusing configurations. File: `bioblitz_shiny_app_V4.R`.

### R script

Choose the script if you are comfortable with R, want maximum control, or want to automate or schedule runs. File: `Walpole_Bioblitz_Photo_Slideshow_Script_V4.R`.

Both produce the same slideshow. If you are unsure, start with the app.

---

## What the software does

Both methods use the same engine:

1. **Connect to iNaturalist** and download observation data for your project.
2. **Sample** observations at random, while limiting how many come from any one observer and capping the share of plants.
3. **Download photos** at full size.
4. **Build a map** for each observation: an 880 by 600 satellite window centred between HQ and the find, snapped to a few fixed zoom levels so every map fills its frame consistently, with optional road and waterway overlays and a scale bar.
5. **Compose slides**: photo and map side by side, with the species name, observer credit, a taxon icon and a track or watercourse legend baked into the image.
6. **Assemble the slideshow** as a reveal.js HTML page, grouped by taxon, with a closing collage and four summary statistics (participants, days, observations, species).
7. **Export** an optional PDF.

---

## Prerequisites

### Software

1. **R** 4.0 or newer. https://cran.r-project.org/ Install this first.
2. **RStudio Desktop.** https://posit.co/download/rstudio-desktop/
3. **Google Chrome or Chromium.** https://www.google.com/chrome/ Needed only for the optional PDF.

### R packages (installed automatically on first run)

- **Core:** `httr2`, `jsonlite`, `dplyr`, `purrr`, `tidyr`, `stringr`, `lubridate`, `janitor`, `glue`, `readr`, `tibble`
- **Maps and images:** `ggplot2`, `sf`, `maptiles`, `terra`, `tidyterra`, `osmdata`, `magick`, `ggspatial`
- **Palette and taxon icons:** `wesanderson`, `rphylopic`, `png`
- **App only:** `shiny`, `shinydashboard`, `shinyWidgets`, `shinyFiles`
- **Optional PDF:** `quarto`, `pagedown`

First-time installation can take 10 to 15 minutes. You only do it once.

### Your bioblitz information

1. **Project slug.** The part of the project URL after `/projects/`. For "City Nature Challenge 2025" the slug is `city-nature-challenge-2025`.
2. **HQ coordinates.** Right-click your headquarters in Google Maps and copy the latitude and longitude, for example `-34.992854, 116.634398`.
3. **Logo (optional).** A JPG or PNG for the welcome slide.

---

## The companion style file

Version 4 begins by loading `bioblitz_style.R`, a small companion file that defines the shared Wes Anderson palette and the PhyloPic taxon-icon helpers. **It must be in the same folder as the slideshow script.**

- **Script method:** keep `bioblitz_style.R` beside `Walpole_Bioblitz_Photo_Slideshow_Script_V4.R`, and set that folder as your working directory before sourcing.
- **App method:** the app runs the script from its own folder, so the file is found the same way it would be standalone. The Configuration tab shows a green tick when the file is present and a red warning if it is missing. If the warning is red, the app will not start the run.

If you ever see an error about `bioblitz_style.R` not being found, this is the cause. Put the file next to the script.

### Where to put everything

The simplest setup is a single project folder containing all three files:

```
your-project-folder/
├── Walpole_Bioblitz_Photo_Slideshow_Script_V4.R
├── bioblitz_shiny_app_V4.R
├── bioblitz_style.R
├── taxon_icons/            # created automatically on first run
└── outputs/               # created automatically
```

Keep them together and both methods will work without any path fiddling.

### The taxon icon cache

On the first run, the style file fetches taxon silhouettes from PhyloPic (so you need internet once), recolours them to the palette, and caches them in a `taxon_icons/` folder created **next to the script**, not inside the output folder. After that it works offline, and the same cache is reused across runs and shared with the Data Dive deck. The folder is safe to keep and safe to commit if you want the icons to travel with the repo.

### Using your own taxon icons

Drop-in icons are supported. Put a PNG named after the iconic taxon, in lowercase letters only, into the `taxon_icons/` folder, and it is used as-is (no recolouring). The recognised names are:

`aves.png`, `plantae.png`, `insecta.png`, `mammalia.png`, `actinopterygii.png`, `amphibia.png`, `reptilia.png`, `fungi.png`, `arachnida.png`, `mollusca.png`, `animalia.png`, `chromista.png`, `protozoa.png`.

### Changing the palette

Both the slide colours and the icon tints come from the `taxon_cols` vector at the top of `bioblitz_style.R`. Edit a colour there and it flows through to every slide. After a palette change, tick **Rebuild taxon icons** (`force_rebuild_icons`) once so the cached silhouettes are re-tinted. Your own drop-in PNGs are left untouched.

---

## Method 1: using the Shiny app

### Launching the app

**Easiest.** Open `bioblitz_shiny_app_V4.R` in RStudio and click the **Run App** button at the top right of the editor. The app opens in a window or your browser.

**From the console.**

```r
shiny::runApp("bioblitz_shiny_app_V4.R")
```

The app has four tabs down the left: **Configuration**, **Run & progress**, **Outputs** and **Help**.

---

### Configuration tab

#### Slideshow script

Click **Browse** and select `Walpole_Bioblitz_Photo_Slideshow_Script_V4.R`. Two status lines appear:

- A green tick when the script is found.
- A green tick when `bioblitz_style.R` is found in the same folder, or a red warning if it is missing.

Both need to be green before you generate.

#### Project settings

- **iNaturalist project slug** (required). From your project URL.
- **Bioblitz name.** Shown on the welcome slide. The year is appended automatically from the data, for example "Walpole Wilderness Bioblitz 2025".
- **Number of photos.** How many observations to include. 25 to 50 suits a presentation, 50 to 100 an event display.
- **Upload bioblitz logo** (optional). JPG or PNG, shown top right on the welcome slide.

#### Observation date display

- Leave **Derive the date range automatically** ticked to read the earliest and latest observation dates from the data.
- Untick it to set the dates by hand. This is useful when the project has outlier records (for example, historical observations added later) that would otherwise skew the range.

#### Output folder

Click **Browse** and choose where the slideshow is saved. The folder is created if it does not exist. Everything for the run lands here.

#### Location and maps

- **HQ latitude** and **HQ longitude** (required), in decimal degrees.
- **Base map zoom level.** 13 to 15 recommended. Higher means more detail but slower.
- **Closest map radius (metres).** The most zoomed-in level. Distant observations zoom out from here.
- **Number of map zoom levels.** Discrete steps the maps snap to.
- **Map edge padding (metres).** Margin kept between HQ or the observation and the window edge, so neither sits hard against the border.
- **Map edge margin (fraction).** Keeps both points inside the inner part of each map. Higher means slightly more zoomed out.

#### Selection diversity

- **Max percent of photos from one observer.** Spreads the slideshow across contributors.
- **Absolute max photos per observer.** A hard cap that overrides the percentage if lower.
- **Max percent plant photos.** Keeps the mix varied rather than plant-heavy.

#### Slideshow playback

- **Auto-advance time (seconds).**
- **Let the viewer pause auto-advance.**
- **Loop back to the start at the end.**
- **Max photos in the final collage.**

#### Run mode and performance

- **Fresh run.** Deletes previous photos, maps and slides and rebuilds everything. Use for a brand-new slideshow or after big changes to the pool.
- **Fetch all observations.** Untick to fetch a subset for quick tests.
- **Cache observations.** Saves fetched data for faster reruns.
- **Fetch only new observations.** Pulls just the new records since the last run. Applies when Fresh run is off.

#### Advanced rebuild options

Each has a short explanation in the app. In brief:

- **Rebuild satellite base map.** Re-downloads the base tiles. Use on the first run or if the area changed.
- **Rebuild all observation maps.** Re-renders every map. Use after changing HQ, zoom or styling.
- **Rebuild all slide compositions.** Re-composites every slide. Use after layout or caption changes.
- **Rebuild the closing collage.**
- **Rebuild taxon icons.** Re-fetches and recolours the PhyloPic silhouettes. The first run fetches them anyway, so only tick this after a palette change or to refresh the cache.
- **Skip OpenStreetMap overlays.** Omits roads and waterways for faster runs.

#### PDF output

- **Also create a PDF version.** Needs Chrome or Chromium. Can be slow for large slideshows.
- **PDF size limit (MB).** Skips the PDF if the estimate exceeds this. 0 means no limit.

#### Reproducibility (random seed)

- **Random selection each run.** Different photos every time. Untick to use R's current state.
- **Specific seed (optional).** Enter a number to reproduce the exact same selection. Leave blank for random.

#### Save and load configuration

- **Save configuration** writes your settings to `bioblitz_config.rds`.
- **Load configuration** restores them. Handy for repeat events.

---

### Run and progress tab

#### Quick presets

Presets set all the rebuild switches for you. Pick one, then click **Generate slideshow**.

- **Regenerate HTML.** Reuse every cache and just rewrite `slideshow.html`. Fastest. A seed is applied so the same photos are used.
- **New collage only.** Rebuild just the collage, reuse the slides.
- **Quick test (3 slides).** Fetch three photos and build fresh, with no OSM overlays. Good for checking settings.
- **Update new obs.** Incrementally fetch new observations, then rebuild the collage and HTML.
- **Full rebuild.** Rebuild base map, maps, slides, collage and HTML from cached photos.
- **Fresh run.** Delete all cached files and start from scratch.

#### Generate and stop

- **Generate slideshow** starts a background R process. You can keep watching progress here while it runs.
- **Stop** cancels the running process.

#### Seed helpers

- The seed card mirrors the Reproducibility settings. Tick or untick random selection and set a specific seed here too.
- **Use last run seed** reads the seed from the previous run's log so you can reproduce the same photos.
- A banner warns you when no specific seed is set and photos may therefore differ from your last run. Setting a seed clears the warning.

#### Status, stages and counts

- **Current status** shows what the run is doing right now.
- **Progress** is a checklist: Initialising, Fetching observations, Downloading photos, Creating maps, Composing slides, Building slideshow, Complete.
- The info boxes show live counts: **Observations**, **Observers**, **Photos (this run)**, **Maps (this run)** and **Slides (this run)**.

#### Live log and debugging

- **Live progress log** streams the script's output, filtered to the useful lines.
- **Refresh file counts** forces a recount if the numbers look stuck.
- The collapsible **Debugging information** panel lists the paths and file counts the app is watching.

---

### Outputs tab

- **Output location** shows the full path to your folder.
- **Available files** lists the key outputs (`slideshow.html`, `collage.png`, and `slideshow.pdf` if you made one).
- **Open slideshow in browser** launches `slideshow.html`.
- **Open output folder** opens the folder in your file explorer.

#### Housekeeping

A collapsible panel to clear cached images when a layout change is not showing up on a rebuild:

- **Clear cached maps**
- **Clear cached slides**
- **Clear cached collage**

These only remove cached images. Your observation cache is kept, so the next run does not need to re-fetch data.

---

### Daily updates with the app

For a multi-day event:

1. **Configuration tab.** Click **Load configuration** to restore your settings. Make sure **Fresh run** is off and **Fetch only new observations** is on.
2. **Run & progress tab.** Notice the cached observation count appears straight away. Use the **Update new obs** preset and click **Generate slideshow**. Only new observations are processed, so it is quick.
3. **Outputs tab.** Open the refreshed slideshow.

---

## Method 2: using the R script

### Setup

1. Put `Walpole_Bioblitz_Photo_Slideshow_Script_V4.R` and `bioblitz_style.R` in the same folder.
2. Open the script in RStudio.
3. Set the working directory to that folder: **Session, Set Working Directory, To Source File Location**. This lets the script find `bioblitz_style.R` and write outputs where you expect.

### Configuration

Edit the **CONFIGURATION** block near the top (roughly lines 55 to 135). The essentials:

```r
project_slug  <- "your-project-slug"          # from your iNaturalist project URL
bioblitz_name <- "Your Bioblitz"               # year is appended automatically
n_photos      <- 50                            # number of observations to include
bioblitz_logo <- "your-logo.jpg"               # in the same folder, or "" for none

hq_lon <- 116.634398                           # headquarters longitude
hq_lat <- -34.992854                           # headquarters latitude

out_dir <- "outputs/your_project_slideshow"    # where everything is saved
```

Diversity, map, playback, rebuild and seed options follow, each commented in the file. Note that in the script the diversity limits are fractions (`0.15`, `0.40`) and the auto-advance time is in milliseconds (`7000`), whereas the app uses percentages and seconds.

### Running

- **Source button.** Click **Source** at the top right, or press `Ctrl+Shift+S` (Windows and Linux) or `Cmd+Shift+S` (Mac). Watch the console for progress and wait for `=== SCRIPT COMPLETE ===`.
- **Command line.**

```bash
Rscript Walpole_Bioblitz_Photo_Slideshow_Script_V4.R
```

Run it from the script's folder so `bioblitz_style.R` resolves.

### Daily updates with the script

For quick daily runs, leave `fresh_run <- FALSE` and `use_incremental_fetch <- TRUE`. Only new observations are fetched and cached work is reused.

---

## Configuration reference

| Parameter | Meaning | Default |
|---|---|---|
| `project_slug` | iNaturalist project identifier | (required) |
| `n_photos` | Observations in the slideshow | 50 |
| `bioblitz_logo` | Logo file, or "" for none | Walpole-Wilderness-bioblitz.jpg |
| `bioblitz_name` | Name on the welcome slide (year appended) | Walpole Wilderness Bioblitz |
| `bioblitz_dates_auto` | Derive dates from data | TRUE |
| `bioblitz_dates_start` / `bioblitz_dates_end` | Manual dates when auto is off | NULL |
| `hq_lon` / `hq_lat` | Headquarters coordinates | 116.634398 / -34.992854 |
| `max_obs_per_observer_pct` | Max share from one observer | 0.15 |
| `max_obs_per_observer_abs` | Absolute cap per observer | 5 |
| `max_plants_pct` | Max share of plant photos | 0.40 |
| `use_random_seed` | New selection each run | TRUE |
| `random_seed` | Fixed seed for reproducibility | NULL |
| `fresh_run` | Delete old artefacts and rebuild | FALSE |
| `fetch_all_observations` | Fetch the whole project | TRUE |
| `cache_observations` | Cache fetched data | TRUE |
| `use_incremental_fetch` | Fetch only new observations | TRUE |
| `force_rebuild_base_map` | Rebuild satellite base map | FALSE |
| `force_rebuild_maps` | Rebuild all observation maps | TRUE |
| `force_rebuild_slides` | Rebuild all slide compositions | FALSE |
| `force_rebuild_collage` | Rebuild the collage | TRUE |
| `force_rebuild_icons` | Rebuild PhyloPic taxon icons | TRUE |
| `skip_osm_overlays` | Skip roads and waterways | FALSE |
| `base_map_zoom` | Satellite zoom level | 14 |
| `default_dist_m` | Closest map half-width (m) | 4000 |
| `map_zoom_n` | Number of discrete zoom levels | 4 |
| `map_pad_m` | Margin to the window edge (m) | 1000 |
| `map_margin_frac` | Fractional edge margin | 0.20 |
| `auto_advance_ms` | Auto-advance time (ms) | 7000 |
| `auto_slide_stoppable` | Allow pausing auto-advance | TRUE |
| `slideshow_loop` | Loop at the end | TRUE |
| `max_collage` | Photos in the collage | 25 |
| `create_pdf` | Also make a PDF | FALSE |
| `pdf_size_limit_mb` | Skip PDF above this size (0 = no limit) | 50 |
| `out_dir` | Output folder | outputs/..._slideshow |
| `diagnostic_mode` | Print detailed progress | TRUE |

---

## Output files

Everything is written to your output folder, `outputs/<project>_slideshow/`:

- `slideshow.html` : the slideshow.
- `collage.png` : the closing collage.
- `slideshow.pdf` : optional, if you enabled the PDF.
- `slides/`, `maps/`, `photos/` : the composed slides, per-observation maps, and downloaded photos.
- `base_map_cache/` : the cached satellite base map.
- `*.rds` : observation and photo caches that speed up reruns.

The taxon icon cache (`taxon_icons/`) is the one thing kept **outside** this folder. It lives next to the script, so it can be shared across projects and with the Data Dive deck (see [The companion style file](#the-companion-style-file)).

### Important: the HTML is not self-contained

`slideshow.html` references its images by relative path (the pictures in `slides/`, the `collage.png` and the logo). It is not a single embedded file.

- **Open it from inside its folder.** Moving the HTML on its own will break the images.
- **To share it, keep the folder together.** Zip the whole `<project>_slideshow` folder, or at least send `slideshow.html` with its `slides/` folder, `collage.png` and the logo.
- The optional `slideshow.pdf` is a single portable file, best for emailing.

### Viewing controls

Open `slideshow.html` in any browser. Press **F** for fullscreen, **Space** or the arrow keys to move manually (this overrides auto-advance), and **Esc** to exit fullscreen.

---

## Troubleshooting

### The run will not start, or a red style-file warning appears

`bioblitz_style.R` is not in the script's folder. Put it there. In the app both status lines on the Configuration tab must be green.

### A layout change is not showing up after a rebuild

Cached images are being reused. Clear them with the **Housekeeping** panel on the Outputs tab (maps, slides or collage), or tick the matching **Rebuild** option, then generate again.

### Taxon icons look wrong after changing the palette

Tick **Rebuild taxon icons** (`force_rebuild_icons`) once to refresh the icon cache, then generate.

### Progress counts seem stuck at zero

Click **Refresh file counts** and check the live log for errors. The background process may still be initialising or working.

### Cannot connect to iNaturalist

Check your internet connection and confirm the project slug is exact. Very large projects take longer to fetch.

### No observations found

Confirm the project has observations with photos. For a first run, keep **Fetch all observations** on.

### The app window seems frozen while generating

The build runs in a separate background process, so the interface can pause briefly. Do not close the window. Watch the live log, and use **Refresh file counts** if needed.

### A background process is still running after you close the app

Reopen the app and click **Stop**, or end any stray R processes in your Task Manager or Activity Monitor.

### Package installation fails

Update R and RStudio, then try installing the named package by hand with `install.packages("package_name")` and read the console for the specific error.

---

## Tips and best practices

### Multi-day events

- **Day 1:** use **Fresh run**, 50 photos, loop on, auto-advance around 10 seconds, on a large screen at registration.
- **Later days:** switch to **Update new obs** and regenerate each morning. Updates are quick because only new observations are processed.

### Presentations

- 25 to 50 photos, auto-advance around 7 seconds, loop off.
- Enable the PDF for easy sharing.
- Present fullscreen with **F**, advance with **Space**, exit with **Esc**.

### Faster generation

- Tick **Skip OpenStreetMap overlays**.
- Lower the base map zoom to 12 or 13.
- Reduce the number of photos, and turn the PDF off.
- Trade-off: quicker runs, slightly less map detail.

### Ensuring diversity

- Too much from one person: lower the **absolute max per observer** to 3.
- Too many plants: lower **max percent plant photos** to 30.

### Reproducing the exact same photos

Set a specific seed and keep it. In the app, click **Use last run seed**, or type a number into the specific-seed field. In the script, set `use_random_seed <- TRUE` and `random_seed <- 42` (any number). Every run with the same seed selects the same observations.

### Managing disk space

Slideshows grow with the photo count (very roughly 0.5 GB for 25 photos, 1 GB for 50, 2 GB for 100). Delete old output folders when done, turn the PDF off for large runs, and use a lower base map zoom for smaller map files.

---

## Advanced topics

### Reusing work between runs

The engine caches aggressively. Observations, photos, maps and slides are all reused unless you request a rebuild. The presets are the easiest way to control this: **Regenerate HTML** touches almost nothing, **Full rebuild** redoes the imagery from cached photos, and **Fresh run** starts over. When in doubt, a preset plus the housekeeping cache-clear covers most situations.

### Automating daily updates

You can schedule the script (not the app) to run each morning.

**Windows Task Scheduler.** Create a small batch file, then schedule it:

```bat
"C:\Program Files\R\R-4.x.x\bin\Rscript.exe" "C:\path\to\Walpole_Bioblitz_Photo_Slideshow_Script_V4.R"
```

**Mac or Linux cron.** Edit your crontab with `crontab -e` and add a line to run at 8 am:

```
0 8 * * * cd /path/to/folder && Rscript Walpole_Bioblitz_Photo_Slideshow_Script_V4.R
```

Run from the script's folder so `bioblitz_style.R` and the relative output path resolve.

### Adjusting the look and using your own icons

The shared palette, the taxon icon cache and drop-in support all live with `bioblitz_style.R`. See [The companion style file](#the-companion-style-file) for how to change the palette, where the `taxon_icons/` cache sits, and how to name your own drop-in PNGs. In short: edit `taxon_cols` to change colours, tick **Rebuild taxon icons** once after a palette change, and drop a `<taxon>.png` (lowercase) into the `taxon_icons/` folder to override an icon.

---

## Conclusion

You have two ways to build a bioblitz slideshow: the **Shiny app** for an easy, visual, live-progress experience, and the **R script** for full control and automation. Both use the same engine and the same `bioblitz_style.R` companion file, and both produce the same reveal.js slideshow.

**Next steps**

1. Put the script, the app and `bioblitz_style.R` in one folder.
2. Gather your project slug, HQ coordinates and logo.
3. Configure and generate your first slideshow.
4. Open it, and celebrate your biodiversity discoveries.

**Happy slideshow making.** 🦋🌿🦎

---

*Version 4*
