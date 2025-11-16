# 🌿🔬 iNaturalist Bioblitz Slideshow Generator

Automatically create slideshows from your iNaturalist bioblitz observations. Perfect for celebrating biodiversity discoveries with your participants!

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue)](https://www.r-project.org/)

---

## ✨ Features

- **🎲 Truly Random**: Every run creates a unique selection of observations
- **🌍 Custom Maps**: Automatically generates location maps for each observation with your bioblitz HQ marker
- **📊 Smart Diversity Controls**: Ensures fair representation across observers and species groups
- **⚡ Performance Optimized**: Fast map providers and incremental caching for large bioblitzes
- **🎨 Fully Customizable**: Configure everything from map styles to slideshow timing
- **📱 Multiple Outputs**: HTML (interactive), QMD (editable), and PDF formats
- **🔄 Daily Updates**: Efficiently fetch only new observations for ongoing events
- **🖼️ High-Resolution Photos**: Automatically downloads full-size images
- **🖥️ **NEW: User-Friendly GUI**: Interactive Shiny app interface - no code editing required!

## 🎯 What It Does

The script connects to iNaturalist's API to:

1. Download observation data from your specified bioblitz project
2. Randomly select observations with diversity controls (prevents one observer from dominating, balances plant vs. animal ratio)
3. Download high-quality photos of each selected observation
4. Generate custom maps showing observation locations, your bioblitz HQ, roads, and waterways
5. Create professional slideshow presentations organized by iconic taxon groups (Plants, Insects, Birds, etc.)
6. Output in multiple formats perfect for event displays or presentations

**New in Version 3.0:**
- **Interactive Shiny GUI** - Easy point-and-click interface with live progress tracking
- **Two Usage Methods** - Choose between GUI app or traditional R script
- Colorful emoji progress indicators (🔭👥📷🗺️🎬)
- Real-time observation and observer counts
- Enhanced progress monitoring with detailed stages

## 🚀 Two Ways to Use

### Method 1: Shiny GUI App (Recommended for Most Users) 🖥️

**Best for:** Users who prefer a visual interface, want to experiment with settings, or need live progress tracking

**Advantages:**
- No code editing required - all settings in a user-friendly interface
- Real-time progress updates with colorful indicators
- Save and load configurations for repeated use
- See file counts update as slideshow generates
- Quick access buttons to open outputs
- Perfect for event organizers during multi-day bioblitzes

**Quick Start:**
1. Open `bioblitz_shiny_app_FINAL.R` in RStudio
2. Click **Run App** (top right of script pane)
3. Configure settings in the GUI tabs
4. Click **Generate Slideshow**
5. Watch progress in real-time!

[→ Jump to Shiny App Instructions](#shiny-gui-app-detailed-instructions)

### Method 2: Traditional R Script 📝

**Best for:** Advanced users, automated workflows, or when you want maximum control

**Advantages:**
- Full control over every parameter
- Can be integrated into larger workflows
- Easier to version control settings
- Can be run from command line
- No GUI overhead

**Quick Start:**
1. Open `iNaturalist_Bioblitz_Slideshow_Generator.R` in RStudio
2. Edit configuration section (around line 50)
3. Click **Source** or press `Ctrl+Shift+S`
4. Wait for completion
5. Find slideshow in `outputs/slideshow/`

[→ Jump to Script Instructions](#traditional-r-script-detailed-instructions)

---

## 📋 Prerequisites

### Required Software

- **R** (version 4.0 or higher) - [Download here](https://cran.r-project.org/)
- **RStudio** (Desktop version) - [Download here](https://posit.co/download/rstudio-desktop/)
- **Google Chrome** (for PDF generation, optional) - [Download here](https://www.google.com/chrome/)

### R Packages

The script will automatically install all required packages on first run:
- `httr2`, `jsonlite` - iNaturalist API connection
- `dplyr`, `tidyr`, `purrr` - Data manipulation
- `ggplot2`, `sf` - Map creation
- `maptiles`, `terra`, `osmdata` - Geographic features
- `magick` - Image processing
- `quarto` - Slideshow generation
- `shiny`, `shinydashboard`, `shinyWidgets` - GUI interface (for Shiny app)

*First-time setup may take 10-15 minutes while packages install.*

---

## 🖥️ Shiny GUI App: Detailed Instructions

### Launching the App

1. **Open the app file** in RStudio:
   - File: `bioblitz_shiny_app_FINAL.R`
   - Or create a launcher file (see below)

2. **Click the "Run App" button** that appears at the top right of the script editor
   - Alternatively, type `shiny::runApp("bioblitz_shiny_app_FINAL.R")` in the Console

3. **The app opens** in a new window or your web browser

### App Interface Overview

The Shiny app has four main tabs:

#### 📝 Configuration Tab

Set all your slideshow parameters:

1. **Script Location**
   - Specify the filename of your main slideshow script
   - Default: `Final_Walpole_Bioblitz_Slideshow_Script.R`
   - Must be in the same folder as the Shiny app

2. **Project Settings**
   - iNaturalist project slug (from your project URL)
   - Number of photos in slideshow
   - Optional: Upload your bioblitz logo
   - Output directory name

3. **Location Settings (for Maps)**
   - Headquarters latitude and longitude
   - Base map zoom level
   - Map buffer distance
   - Individual map radius

4. **Diversity Settings**
   - Max % from single observer
   - Absolute max per observer
   - Max % plant photos

5. **Slideshow Settings**
   - Auto-advance timing
   - Loop option
   - Maximum collage photos

6. **Run Mode & Performance**
   - **Fresh Run**: Delete old files and start fresh
   - **Incremental Update**: Keep cache, only fetch new observations
   - Fetch all observations toggle
   - Cache observations toggle
   - Use incremental fetch option

7. **Advanced Options**
   - Force rebuild base map
   - Force rebuild all maps
   - Force rebuild all slides
   - Skip OSM overlays (faster)

8. **PDF Output Settings**
   - Create PDF toggle
   - PDF size limit

9. **Random Seed**
   - Use random selection
   - Optional: Set specific seed for reproducibility

**Save/Load Configurations:**
- Click "Save Configuration" to save current settings
- Click "Load Configuration" to restore saved settings
- Configurations saved as `shiny_config.rds` in app folder

#### ▶️ Run & Progress Tab

Monitor slideshow generation in real-time:

**Progress Indicators** (with colorful emojis!):
- 🔭 **Total Observations** - Shows cached observation count
- 👥 **Total Unique Observers** - Shows number of contributors
- 📷 **Photos (This Run)** - New photos downloaded
- 🗺️ **Maps (This Run)** - New maps created
- 🎬 **Slides (This Run)** - New slides composed

**Progress Stages Checklist:**
- ✓ Initializing
- ✓ Fetching observations from iNaturalist
- ✓ Downloading photos
- ✓ Creating maps
- ✓ Composing slides
- ✓ Building slideshow
- ✓ Complete!

**Live Progress Log:**
- Shows real-time output from script
- Filtered to show important progress only
- Collapsible for cleaner view

**Controls:**
- **Generate Slideshow** - Start the process
- **Stop Process** - Cancel running slideshow
- **Refresh File Counts** - Manually update counts if stuck

#### 📂 Outputs Tab

Access your generated files:

- **Output Location** - Shows full path to output folder
- **Available Files** - Lists slideshow.html, slideshow.pdf, etc.
- **Open Slideshow in Browser** - Opens HTML slideshow
- **Open Output Folder** - Opens folder in file explorer

#### ❓ Help Tab

Quick reference guide for using the app

### Typical Workflow (Shiny App)

**For a New Bioblitz:**

1. **Configuration Tab**
   - Enter your project slug
   - Set HQ coordinates
   - Upload logo (optional)
   - Set number of photos (25-50 recommended)
   - Enable "Fresh Run"
   - Click "Save Configuration"

2. **Run & Progress Tab**
   - Click "Generate Slideshow"
   - Watch progress indicators update
   - Monitor live log for details
   - Wait for "Complete!" status

3. **Outputs Tab**
   - Click "Open Slideshow in Browser"
   - Or click "Open Output Folder" to see all files

**For Daily Updates (Multi-Day Bioblitz):**

1. **Configuration Tab**
   - Click "Load Configuration" (restores your settings)
   - **Uncheck "Fresh Run"**
   - **Enable "Use Incremental Fetch"**
   - This fetches only new observations!

2. **Run & Progress Tab**
   - Notice cached observation count shown immediately
   - Click "Generate Slideshow"
   - Much faster - only processes new observations
   - Progress shows incremental counts

3. **Outputs Tab**
   - New slideshow with updated observations
   - Previous files preserved in output folder

### Shiny App Tips

✅ **Do:**
- Save your configuration after first setup
- Use "Fresh Run" for your first slideshow
- Use incremental mode for daily updates
- Watch the progress log for errors
- Use "Refresh File Counts" if numbers seem stuck

❌ **Don't:**
- Close the app window while slideshow is generating
- Change configuration during generation
- Use "Fresh Run" for daily updates (you'll lose cache!)

---

## 📝 Traditional R Script: Detailed Instructions

### Setup and Configuration

1. **Open the script** in RStudio:
   - File: `iNaturalist_Bioblitz_Slideshow_Generator.R`

2. **Find the configuration section** (around line 50)

3. **Edit essential settings:**

```r
# --- Essential Settings ---
project_slug <- "your-project-name-here"  # From your iNaturalist project URL
bioblitz_name <- "Your Location"           # Appears on welcome slides
bioblitz_year <- 2025                      # Year of your bioblitz
n_photos <- 25                             # Number of photos in slideshow

# --- HQ Location ---
hq_lon <- 116.634398  # Your headquarters longitude
hq_lat <- -34.992854  # Your headquarters latitude

# --- Optional: Add Your Logo ---
bioblitz_logo <- "your-logo.jpg"  # Place logo file in project root
```

**Finding your project slug:**
- Go to your iNaturalist project page
- Copy everything after `/projects/` in the URL
- Example: `https://www.inaturalist.org/projects/city-nature-challenge-2025` → `"city-nature-challenge-2025"`

**Finding your coordinates:**
- Right-click your HQ location in Google Maps
- Click the coordinates to copy them
- First number is longitude, second is latitude

### Running the Script

**Method A: Source Button**
1. Click **Source** at the top right of the script editor
2. Or press `Ctrl+Shift+S` (Windows/Linux) or `Cmd+Shift+S` (Mac)
3. Watch progress in the Console
4. Wait for "SCRIPT COMPLETED SUCCESSFULLY"

**Method B: Command Line**
```bash
Rscript iNaturalist_Bioblitz_Slideshow_Generator.R
```

### Script Output

The script creates files in `outputs/slideshow/`:
- `slideshow.html` - Main interactive presentation
- `slideshow.qmd` - Editable Quarto source
- `slideshow.pdf` - PDF version (if enabled)
- `slides/` - Individual slide images
- `maps/` - Location maps
- `photos/` - Downloaded photos
- Cache files (`.rds`) - For faster reruns

---

## 🎛️ Key Configuration Options

*These apply to both Shiny app and traditional script*

### Project Settings
```r
project_slug <- "your-project-slug"   # iNaturalist project identifier
n_photos <- 25                         # Number of photos (25-100 typical)
bioblitz_name <- "Your Location"       # Name for slides
bioblitz_year <- 2025                  # Year for slides
```

### Diversity Controls
```r
max_obs_per_observer_pct <- 0.15  # Max 15% from any one observer
max_obs_per_observer_abs <- 5     # Absolute max per observer
max_plants_pct <- 0.50             # Max 50% plants
```

### Map Customization
```r
# Choose your map style:
map_provider <- "Esri.WorldImagery"    # Satellite (high quality, slower)
map_provider <- "OpenStreetMap"        # Street map (fast)
map_provider <- "CartoDB.Voyager"      # Balanced (fast, good detail)
map_provider <- "Esri.WorldTopoMap"    # Topographic (shows terrain)

base_map_zoom <- 14                    # Zoom level (13-15)
buffer_km <- 3.5                       # Area around observations
```

### Slideshow Behavior
```r
auto_advance_ms <- 7000        # 7 seconds per slide
auto_slide_stoppable <- TRUE   # Allow manual control
slideshow_loop <- FALSE        # Loop at end
create_pdf <- TRUE             # Generate PDF version
```

### Run Modes

**Fresh Run** (clean slate):
```r
fresh_run <- TRUE                   # Delete old outputs
fetch_all_observations <- TRUE      # Download all observations
cache_observations <- TRUE          # Save for future use
```

**Incremental Update** (daily bioblitz):
```r
fresh_run <- FALSE                  # Keep existing files
use_incremental_fetch <- TRUE       # Only fetch new observations
cache_observations <- TRUE          # Update cache
```

### Performance Optimization

For large bioblitz areas, use these settings for 10-20x faster generation:

```r
map_provider <- "OpenStreetMap"     # Fast map provider
skip_osm_overlays <- TRUE           # Skip road/waterway overlays
base_map_zoom <- 12                 # Lower zoom level
buffer_km <- 2.5                    # Smaller area
force_rebuild_base_map <- FALSE     # After first run
```

---

## 💡 Common Use Cases

### Multi-Day Bioblitz Event Display

**Day 1 (Shiny App):**
1. Open Shiny app
2. Configure all settings in GUI
3. Enable "Fresh Run"
4. Save configuration
5. Generate slideshow
6. Display on screen with auto-loop

**Days 2-7 (Fast Updates):**
1. Open Shiny app
2. Load saved configuration
3. **Disable "Fresh Run"**
4. **Enable "Use Incremental Fetch"**
5. Generate slideshow (much faster!)
6. New observations automatically included

**Alternative (Script Method):**
```r
# Day 1
fresh_run <- TRUE
n_photos <- 50
slideshow_loop <- TRUE

# Days 2-7 (edit script each day)
fresh_run <- FALSE
use_incremental_fetch <- TRUE
```

### One-Time Presentation

**Shiny App:**
- Set photos to 25-50
- Enable "Create PDF"
- Disable "Loop Slideshow"
- Set auto-advance to 7 seconds
- Generate once

**Script:**
```r
n_photos <- 25
fresh_run <- TRUE
create_pdf <- TRUE
slideshow_loop <- FALSE
auto_advance_ms <- 7000
```

### Large Slideshow (100+ photos)

**Shiny App:**
- Set photos to 100
- Max per observer: 5
- Disable "Create PDF" (file size)
- Use cached data

**Script:**
```r
n_photos <- 100
max_obs_per_observer_abs <- 5
create_pdf <- FALSE
fresh_run <- FALSE
```

---

## 🛠️ Troubleshooting

### Shiny App Issues

**"Cannot find script file"**
- Make sure the main R script is in the same folder as the Shiny app
- Check the script filename in Configuration tab
- Default name: `Final_Walpole_Bioblitz_Slideshow_Script.R`

**Progress indicators stuck at zero**
- Click "Refresh File Counts" button
- Check "Live Progress Log" for errors
- Script may still be initializing

**App freezes or becomes unresponsive**
- Don't close the browser/window - it's still working
- Check the Live Progress Log
- Background process runs separately

**"Process may still be running" after closing**
- The background script continues even if you close the app
- Reopen the app and click "Stop Process"
- Or check Task Manager for stray R processes

### Script Issues

**"Cannot connect to iNaturalist"**
- Check your internet connection
- Verify your `project_slug` is correct
- Check iNaturalist API status

**"No observations found"**
- Verify your project has observations with photos
- Check date filters if using them
- Ensure `fetch_all_observations <- TRUE` for first run

**Script is slow**
- For large bioblitzes, use `map_provider <- "OpenStreetMap"`
- Set `skip_osm_overlays <- TRUE`
- Reduce `base_map_zoom` to 12 or 13
- See [Performance Optimization](#performance-optimization)

**Package installation fails**
- Update R and RStudio to latest versions
- Try installing packages manually: `install.packages("package_name")`
- Check the Console for specific error messages

For comprehensive troubleshooting, see the [User Guide](Bioblitz_photo_show_user_guide.md#troubleshooting).

---

## 📁 Repository Structure

```
.
├── iNaturalist_Bioblitz_Slideshow_Generator.R  # Main slideshow script
├── bioblitz_shiny_app_FINAL.R                  # Shiny GUI application
├── Bioblitz_photo_show_user_guide.md           # Comprehensive documentation
├── README.md                                    # This file
├── LICENSE.txt                                  # GPL v3 license
└── outputs/                                     # Generated slideshows (created automatically)
    └── slideshow/
        ├── slideshow.html
        ├── slideshow.qmd
        ├── slideshow.pdf
        ├── slides/
        ├── maps/
        └── photos/
```

---

## 🌟 Examples

This script was originally developed for the **Walpole Wilderness Bioblitz 2025** and has been generalized to work with any iNaturalist bioblitz project worldwide.

Share your slideshows with the iNaturalist community and help celebrate biodiversity discoveries! 🦋🌿🦎

---

## 🤝 Contributing

Contributions are welcome! If you've made improvements or have suggestions:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.txt](LICENSE.txt) file for details.

This means you are free to:
- Use the software for any purpose
- Change the software to suit your needs
- Share the software with others
- Share the changes you make

Under the following conditions:
- You must share your modifications under the same GPL v3 license
- You must include the original copyright notice
- You must include a copy of the GPL v3 license

---

## 👥 Authors

**Olly Berry** and **Claude**

---

## 🙏 Acknowledgements

- Thanks to all organizers and participants in the **Walpole Wilderness Bioblitzes**
- [iNaturalist](https://www.inaturalist.org/) for providing the API and platform
- The R community for excellent mapping and data processing packages
- [Quarto](https://quarto.org/) and [Reveal.js](https://revealjs.com/) for slideshow capabilities
- Map data providers: Esri, OpenStreetMap, CartoDB
- The Shiny team at Posit for the excellent GUI framework

---

## 📞 Support

- **Documentation**: See [Bioblitz_photo_show_user_guide.md](Bioblitz_photo_show_user_guide.md)
- **Issues**: Open an issue on GitHub
- **Questions**: Contact through GitHub discussions

---

## 🔗 Related Resources

- [iNaturalist Help](https://www.inaturalist.org/pages/help)
- [R Documentation](https://www.r-project.org/help.html)
- [RStudio Documentation](https://support.posit.co/hc/en-us)
- [Quarto Documentation](https://quarto.org/docs/guide/)
- [Shiny Documentation](https://shiny.posit.co/)

---

**Happy Slideshow Creating!** 🦋🌿🦎

*Choose your preferred method - Shiny GUI for ease of use, or R script for maximum control!*

*If you create something cool with this script, please consider sharing it back with the iNaturalist community!*
