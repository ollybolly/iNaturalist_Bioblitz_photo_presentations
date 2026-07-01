# 🌿🔬 iNaturalist Bioblitz Slideshow Generator

Turn your iNaturalist bioblitz observations into a polished, auto-playing photo slideshow. Perfect for celebrating biodiversity discoveries with your participants, on a screen at the event or shared afterwards.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue)](https://www.r-project.org/)

---

## ✨ What you get

- **Random, diverse selection.** Each run draws a fresh sample of observations, with controls that stop any one observer or plants from dominating.
- **Location map per photo.** Every slide pairs a species photo with a satellite map showing where it was found, plus your bioblitz HQ, roads and waterways.
- **Reveal.js HTML slideshow.** Interactive, auto-advancing and loopable, organised by iconic taxon groups, with a closing photo collage.
- **Taxon silhouettes.** PhyloPic icons are fetched once, recoloured to match the palette and cached for reuse.
- **Fast repeat runs.** Incremental fetch pulls only new observations, and cached photos, maps and slides are reused unless you ask for a rebuild.
- **Two ways to run.** A point-and-click Shiny app, or the R script on its own for full control.

---

## 🎯 How it works

The script talks to the iNaturalist API and then:

1. Downloads observation data from your project.
2. Samples observations at random, with diversity controls (per-observer caps and a plant limit).
3. Downloads full-size photos for the selected observations.
4. Builds a satellite location map for each one, centred between HQ and the observation.
5. Composes each slide (photo plus map, with species name, observer credit and a taxon icon baked in).
6. Assembles a reveal.js HTML slideshow and a closing collage.
7. Optionally exports a PDF.

---

## 📦 Repository contents

```
.
├── Walpole_Bioblitz_Photo_Slideshow_Script_V4.R   # The slideshow engine (edit config, or drive it from the app)
├── bioblitz_shiny_app_V4.R                         # The Shiny GUI (recommended for most users)
├── bioblitz_style.R                                # Shared palette + taxon icon helpers (REQUIRED, see below)
├── taxon_icons/                                     # Icon cache, created here on first run (shared, safe to keep)
├── README.md                                        # This file
├── USER_GUIDE.md                                    # Full step-by-step documentation
├── LICENSE.txt                                      # GPL v3
└── outputs/                                          # Created automatically when you run
    └── <project>_slideshow/
        ├── slideshow.html          # The slideshow (open from inside this folder)
        ├── collage.png             # Closing collage
        ├── slideshow.pdf           # Optional PDF
        ├── slides/                 # Composed slide images
        ├── maps/                   # Per-observation maps
        ├── photos/                 # Downloaded photos
        ├── base_map_cache/         # Cached satellite base map
        └── *.rds                   # Observation and photo caches (speed up reruns)
```

> ⚠️ **`bioblitz_style.R` must sit in the same folder as the slideshow script.** The script loads it on startup for the shared Wes Anderson palette and the PhyloPic taxon icons. If it is missing, the run will not start. The Shiny app checks for it and shows a clear status before you generate.
>
> On the first run it fetches taxon silhouettes from PhyloPic (internet needed once), recolours them and caches them in a `taxon_icons/` folder next to the script. After that it works offline, and the same cache is reused across runs and by the Data Dive deck.

---

## 🚀 Two ways to use it

### Method 1: Shiny GUI app (recommended)

Best if you prefer a visual interface, want live progress, or are running a multi-day event with frequent updates.

1. Open `bioblitz_shiny_app_V4.R` in RStudio.
2. Click **Run App** (top right of the editor).
3. On the **Configuration** tab, browse to the slideshow script, enter your project slug and HQ coordinates, and choose an output folder.
4. On **Run & progress**, pick a preset (or leave the defaults) and click **Generate slideshow**.
5. When it finishes, the app switches to **Outputs**, where you can open the slideshow in your browser.

The app never edits the script. It passes your settings to a background R process and shows the live log, stage checklist and file counts as they build.

### Method 2: The R script on its own

Best if you are comfortable with R, want to automate runs, or prefer to version-control your settings.

1. Put `Walpole_Bioblitz_Photo_Slideshow_Script_V4.R` and `bioblitz_style.R` in the same folder.
2. Open the script in RStudio and set that folder as the working directory (Session, Set Working Directory, To Source File Location).
3. Edit the **CONFIGURATION** block near the top (roughly lines 55 to 135).
4. Click **Source**, or run `Rscript Walpole_Bioblitz_Photo_Slideshow_Script_V4.R` from a terminal.
5. Find your slideshow in `outputs/<project>_slideshow/`.

---

## 📋 Prerequisites

**Software**

- **R** 4.0 or newer. https://cran.r-project.org/
- **RStudio Desktop.** https://posit.co/download/rstudio-desktop/
- **Google Chrome or Chromium** (only if you want the optional PDF). https://www.google.com/chrome/

**R packages** (installed automatically on first run)

- API and data: `httr2`, `jsonlite`, `dplyr`, `purrr`, `tidyr`, `stringr`, `lubridate`, `janitor`, `glue`, `readr`, `tibble`
- Maps and images: `ggplot2`, `sf`, `maptiles`, `terra`, `tidyterra`, `osmdata`, `magick`, `ggspatial`
- Palette and taxon icons: `wesanderson`, `rphylopic`, `png`
- GUI (app only): `shiny`, `shinydashboard`, `shinyWidgets`, `shinyFiles`
- Optional PDF: `quarto`, `pagedown`

First-time package installation can take 10 to 15 minutes. You only do it once.

**Before you start, gather**

- Your **project slug**, the part of the project URL after `/projects/` (for example `walpole-wilderness-bioblitz-2025`).
- Your **HQ coordinates** (right-click the spot in Google Maps and copy the latitude and longitude).
- Optionally, a **logo** (JPG or PNG) for the welcome slide.

---

## ⚙️ Key settings at a glance

These apply to both methods. In the app you enter percentages and seconds; in the raw script the same values are fractions and milliseconds.

| Setting | App | Script | Default |
|---|---|---|---|
| Project slug | Project settings | `project_slug` | (required) |
| Bioblitz name | Project settings | `bioblitz_name` | Walpole Wilderness Bioblitz |
| Number of photos | Project settings | `n_photos` | 50 |
| HQ latitude / longitude | Location & maps | `hq_lat` / `hq_lon` | -34.992854 / 116.634398 |
| Max per observer | Selection diversity | `max_obs_per_observer_pct`, `max_obs_per_observer_abs` | 15% and 5 |
| Max plants | Selection diversity | `max_plants_pct` | 40% |
| Auto-advance | Slideshow playback | `auto_advance_ms` | 7 s |
| Map zoom / radius / padding | Location & maps | `base_map_zoom`, `default_dist_m`, `map_pad_m` | 14 / 4000 m / 1000 m |
| Random seed | Reproducibility | `use_random_seed`, `random_seed` | random each run |

See [USER_GUIDE.md](USER_GUIDE.md) for the full reference, including the rebuild switches and presets.

---

## 🗂️ About the output

The slideshow is a reveal.js page that **references its images by relative path** (the slide pictures in `slides/`, the `collage.png` and the logo). It is not a single self-contained file. So:

- **Open `slideshow.html` from inside its output folder.** Moving the HTML on its own will break the images.
- **To share it, keep the folder together.** Zip the whole `<project>_slideshow` folder, or at least ship `slideshow.html` alongside its `slides/` folder, `collage.png` and the logo.
- The optional `slideshow.pdf` is a single portable file, handy for emailing.

---

## 🔁 Typical workflows

**A new slideshow.** In the app, use the **Fresh run** preset (or set `fresh_run <- TRUE`), enter your details and generate. This clears old artefacts and rebuilds everything.

**Daily updates during a multi-day event.** Leave **Fresh run** off and keep **Fetch only new observations** on (`use_incremental_fetch <- TRUE`). Each run pulls just the new records and reuses cached work, so it is much faster.

**Same photos as last time.** Reuse the seed. In the app click **Use last run seed** on the Run tab, or set a specific number in `random_seed`. Every run with the same seed selects the same observations.

**A quick check of your settings.** Use the **Quick test (3 slides)** preset for a fast, three-photo build.

---

## 🛠️ Troubleshooting quick hits

- **The run will not start / red style-file warning.** `bioblitz_style.R` is not next to the slideshow script. Put it in the same folder.
- **A layout change is not showing up.** Cached images are being reused. Clear them from the app's **Housekeeping** panel (maps, slides or collage), or tick the matching **Rebuild** option, then generate again.
- **Taxon icons look wrong after a palette change.** Tick **Rebuild taxon icons** (`force_rebuild_icons`) once to refresh the icon cache.
- **Progress counts look stuck.** Click **Refresh file counts**, and check the live log for errors. The background process may still be working.
- **No observations found.** Check the project slug is exact and that the project has observations with photos.

Full troubleshooting is in the [User Guide](USER_GUIDE.md#troubleshooting).

---

## 📄 License

Licensed under the GNU General Public License v3.0. See [LICENSE.txt](LICENSE.txt). You are free to use, change and share the software and your changes, provided you share modifications under the same licence and keep the original notices.

---

## 👥 Authors and acknowledgements

**Olly Berry** and **Claude**.

With thanks to the organisers and participants of the **Walpole Wilderness Bioblitzes**, to [iNaturalist](https://www.inaturalist.org/) for the API and platform, to [PhyloPic](https://www.phylopic.org/) for the silhouettes, to [reveal.js](https://revealjs.com/) for the slideshow framework, to the map data providers (Esri, OpenStreetMap), and to the R and Shiny communities.

---

## 🔗 Related resources

- [iNaturalist Help](https://www.inaturalist.org/pages/help)
- [R](https://www.r-project.org/help.html) and [RStudio](https://support.posit.co/hc/en-us) documentation
- [reveal.js](https://revealjs.com/) and [Shiny](https://shiny.posit.co/) documentation

---

**Happy slideshow making.** 🦋🌿🦎 If you create something you are proud of, consider sharing it back with the iNaturalist community.
