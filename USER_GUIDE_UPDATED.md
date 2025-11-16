# iNaturalist Bioblitz Slideshow Generator
## Complete User Guide

**Version 3.0 | November 2025**

---

## Table of Contents

1. [Introduction](#introduction)
2. [Choosing Your Method: GUI vs Script](#choosing-your-method-gui-vs-script)
3. [What This Software Does](#what-this-software-does)
4. [Prerequisites](#prerequisites)
5. [Method 1: Using the Shiny GUI App](#method-1-using-the-shiny-gui-app)
   - [Launching the App](#launching-the-app)
   - [Configuring Your Slideshow](#configuring-your-slideshow)
   - [Generating and Monitoring](#generating-and-monitoring)
   - [Accessing Outputs](#accessing-outputs)
   - [Daily Updates with the GUI](#daily-updates-with-the-gui)
6. [Method 2: Using the R Script](#method-2-using-the-r-script)
   - [Initial Setup](#initial-setup-script)
   - [Understanding the Configuration](#understanding-the-configuration)
   - [Running the Script](#running-the-script)
   - [Daily Updates with the Script](#daily-updates-with-the-script)
7. [Configuration Reference](#configuration-reference)
8. [Output Files](#output-files)
9. [Troubleshooting](#troubleshooting)
10. [Tips and Best Practices](#tips-and-best-practices)
11. [Advanced Topics](#advanced-topics)

---

## Introduction

This software automatically creates beautiful slideshows from iNaturalist bioblitz observations. It's **fully customizable for any bioblitz project worldwide** - just configure a few settings and you're ready to go.

The software downloads photos, creates custom maps showing where each observation was made, and assembles everything into a professional slideshow presentation.

The slideshow includes:
- Random selection of observations with biodiversity diversity controls
- Customizable maps (satellite imagery, street maps, or topographic)
- Organized by iconic taxon groups (Plants, Insects, Birds, etc.)
- Auto-advancing slides perfect for display at events
- Multiple output formats (HTML, QMD, and PDF)
- Your bioblitz name and year on welcome slides

**Who is this guide for?** Anyone who wants to create a slideshow from an iNaturalist bioblitz, regardless of technical expertise or R experience.

**New in Version 3.0:**
- **Interactive Shiny GUI App** - No code editing required!
- **Two usage methods** - Choose GUI or traditional R script
- Real-time progress monitoring with colorful indicators (🔭👥📷🗺️🎬)
- Enhanced caching and incremental updates
- Save and load configurations

---

## Choosing Your Method: GUI vs Script

You have two ways to use this software. Choose the method that best fits your needs and comfort level.

### 🖥️ Method 1: Shiny GUI App (Recommended for Most Users)

**Use this if you:**
- ✅ Prefer point-and-click interfaces over editing code
- ✅ Want to see real-time progress with visual indicators
- ✅ Need to experiment with different settings
- ✅ Are running multi-day bioblitzes with daily updates
- ✅ Want to save and reuse configurations
- ✅ Are less comfortable editing R scripts

**Advantages:**
- No code editing required - all settings in user-friendly forms
- Live progress tracking with colorful emoji indicators
- Save/load configurations for repeated use
- See observation counts and file creation in real-time
- Quick-access buttons to open outputs
- Built-in help text for every option
- Perfect for event displays where you need frequent updates

**File:** `bioblitz_shiny_app_FINAL.R`

---

### 📝 Method 2: Traditional R Script

**Use this if you:**
- ✅ Are comfortable editing R code
- ✅ Want maximum control over parameters
- ✅ Need to integrate into automated workflows
- ✅ Prefer version-controlling your settings
- ✅ Want to run from command line
- ✅ Don't need a GUI

**Advantages:**
- Complete control over every parameter
- Can be automated or scheduled
- Easier to version control settings
- No GUI overhead
- Can be modified or extended
- Simpler for one-time use

**File:** `iNaturalist_Bioblitz_Slideshow_Generator.R`

---

**Can't decide?** Try the Shiny GUI first! It's easier to learn and you can always switch to the script method later for more advanced needs.

---

## What This Software Does

### The Process

Both methods use the same underlying slideshow generation engine:

1. **Connects to iNaturalist**: Downloads observation data from your specified project
2. **Smart Sampling**: Randomly selects observations while ensuring diversity:
   - Limits how many photos from each observer (prevents one person dominating)
   - Controls plant vs. animal ratio
   - Ensures representation across different species groups
3. **Downloads Photos**: Gets high-quality images of each selected observation
4. **Creates Custom Maps**: For each observation, generates a map showing:
   - The observation location (marked with a red star)
   - Your bioblitz headquarters (marked with "HQ")
   - Optional roads (in gold) and waterways (in blue) for context
   - Scale bar for distance reference
   - **Configurable base map**: Choose satellite imagery, street maps, or topographic
5. **Composes Slides**: Combines photos with maps side-by-side, adds species names and observer credits
6. **Builds Slideshow**: Creates a professional presentation organized by organism type
7. **Generates Outputs**: Produces HTML (for viewing), QMD (for editing), and optionally PDF versions

### Key Features

- **Truly Random**: Every run selects different photos (perfect for daily displays)
- **Diversity Controls**: Ensures fair representation across observers and taxa
- **Efficient Caching**: After the first run, only checks for new observations (much faster!)
- **Flexible Map Options**: Choose from satellite, street, or topographic maps
- **Performance Optimized**: Fast map providers for large areas (10-20x faster)
- **High Resolution Photos**: Automatically downloads full-size images, not thumbnails
- **Fully Customizable**: Your bioblitz name, year, and extensive configuration options
- **Real-Time Monitoring** (GUI only): Watch progress with live updates

---

## Prerequisites

### Required Software

1. **R** (version 4.0 or higher)
   - Download from: https://cran.r-project.org/
   - Choose your operating system and follow installation instructions
   - Install first before RStudio

2. **RStudio** (Desktop version)
   - Download from: https://posit.co/download/rstudio-desktop/
   - Install after R is installed
   - This is where you'll run the software

3. **Google Chrome** (for PDF generation, optional)
   - Download from: https://www.google.com/chrome/
   - Required only if you want automatic PDF creation

### R Packages (Installed Automatically)

The first time you run either the GUI or the script, it will automatically install all required packages:

**Core packages:**
- `httr2`, `jsonlite` - Communicate with iNaturalist API
- `dplyr`, `tidyr`, `purrr` - Data manipulation
- `ggplot2`, `sf` - Map creation
- `maptiles`, `terra`, `osmdata` - Geographic features
- `magick` - Image processing
- `quarto` - Slideshow generation

**GUI packages** (for Shiny app only):
- `shiny`, `shinydashboard`, `shinyWidgets` - Interactive interface

**First-time setup:** Allow 10-15 minutes for package installation. You only need to do this once!

### Your Bioblitz Information

Before you start, gather this information:

1. **iNaturalist Project Slug**
   - Go to your project page on iNaturalist
   - Look at the URL: `https://www.inaturalist.org/projects/YOUR-PROJECT-SLUG`
   - Copy everything after `/projects/`
   - Example: For "City Nature Challenge 2025", slug is `city-nature-challenge-2025`

2. **Bioblitz Headquarters Location**
   - Find your HQ on Google Maps
   - Right-click the location
   - Click the coordinates to copy them
   - You'll need: Longitude (first number) and Latitude (second number)
   - Example: `116.634398, -34.992854`

3. **Optional: Your Bioblitz Logo**
   - JPG or PNG format
   - Place in the same folder as the script/app
   - Will appear on welcome slides

---

## Method 1: Using the Shiny GUI App

### Launching the App

#### Option A: Direct Launch (Easiest)

1. **Open RStudio**

2. **Open the app file:**
   - File → Open File
   - Navigate to `bioblitz_shiny_app_FINAL.R`
   - Click Open

3. **Click "Run App"**
   - Look for the green "Run App" button at the top right of the script editor
   - Click it!
   - The app will open in a new window or your web browser

#### Option B: Console Command

In the RStudio Console, type:
```r
shiny::runApp("bioblitz_shiny_app_FINAL.R")
```
Press Enter.

#### Option C: Create a Launcher (Advanced)

Create a new file called `launch_app.R` with this content:
```r
shiny::runApp("bioblitz_shiny_app_FINAL.R")
```

Double-click this file to always launch the app quickly.

### App Interface Tour

The app has four main tabs on the left sidebar:

1. **⚙️ Configuration** - Set all your slideshow parameters
2. **▶️ Run & Progress** - Generate slideshow and monitor progress
3. **📂 Outputs** - Access your generated files
4. **❓ Help** - Quick reference guide

Let's walk through each one.

---

### Configuring Your Slideshow

Click the **Configuration** tab. This page has several collapsible sections.

#### 1. Script Location

**What it is:** Tells the app where to find the main slideshow generation script.

**Settings:**
- **Script Filename**: Default is `Final_Walpole_Bioblitz_Slideshow_Script.R`
- Change this if you renamed the script file
- Must be in the same folder as the Shiny app

**Status indicator:** Shows green ✓ if script is found, red ✗ if not.

---

#### 2. Project Settings

**What it is:** Basic information about your bioblitz.

**Settings:**

- **iNaturalist Project Slug** ⚠️ REQUIRED
  - The identifier from your project URL
  - Example: `walpole-wilderness-bioblitz-2025`
  - See Prerequisites section for how to find this

- **Number of Photos in Slideshow**
  - How many observations to include
  - Default: 3 (for testing)
  - Typical: 25-50 for presentations, 50-100 for events
  - Maximum: 1000 (but very slow)

- **Upload Bioblitz Logo** (optional)
  - Click Browse to select your logo file
  - JPG or PNG format
  - Appears on welcome slide

- **Output Directory Name**
  - Where your slideshow will be saved
  - Default: `bioblitz_slideshow_output`
  - Saved in `outputs/` folder
  - Change this to create multiple versions

**💡 Tip:** The default output folder is different from the original script's default. This keeps Shiny app runs separate from manual script runs.

---

#### 3. Location Settings (for Maps)

**What it is:** Geographic settings for your maps.

**Settings:**

- **Headquarters Latitude** ⚠️ REQUIRED
  - Example: `-34.992854`
  - Southern hemisphere is negative

- **Headquarters Longitude** ⚠️ REQUIRED
  - Example: `116.634398`
  - Western hemisphere is negative

- **Base Map Zoom Level**
  - How zoomed in your maps are
  - 13-15 recommended
  - Higher = more detail but slower
  - Lower = faster but less detail

- **Map Buffer (km)**
  - How much area around observations to show
  - 3-5 km recommended
  - Larger areas take longer to render

- **Individual Map Radius (meters)**
  - Size of individual observation maps
  - 4000 (4 km) is default
  - Adjust based on your site size

**💡 Tip:** For a large bioblitz area, reduce zoom level and buffer for faster processing.

---

#### 4. Diversity Settings

**What it is:** Controls to ensure fair representation in your slideshow.

**Settings:**

- **Max % Photos from Single Observer**
  - Prevents one person dominating the slideshow
  - Default: 15% (if you have 100 photos, max 15 from one person)
  - Slider: 5% to 100%

- **Absolute Max Photos per Observer**
  - Hard limit regardless of percentage
  - Default: 5 photos
  - Overrides percentage if lower

- **Max % Plant Photos**
  - Prevents plant-heavy slideshows
  - Default: 50%
  - Ensures taxonomic diversity
  - Adjust if your bioblitz is plant-focused

**💡 Tip:** These settings ensure your slideshow represents the diversity of both observers and observations!

---

#### 5. Slideshow Settings

**What it is:** How your slideshow behaves.

**Settings:**

- **Auto-Advance Time (seconds)**
  - How long each slide displays
  - Default: 7 seconds
  - Range: 1-60 seconds
  - For presentations: 5-10 seconds
  - For displays: 7-15 seconds

- **Allow User to Stop Auto-Advance**
  - If checked: viewers can pause the slideshow
  - Recommended: Leave checked

- **Loop Slideshow**
  - If checked: slideshow restarts when it reaches the end
  - Great for event displays
  - Uncheck for one-time presentations

- **Max Photos in Final Collage**
  - The last slide shows a grid of photos
  - Default: 25
  - Range: 5-100

---

#### 6. Run Mode & Performance ⚠️ IMPORTANT

**What it is:** Determines how the script handles existing files and data.

**Settings:**

- **Fresh Run (Delete Old Artifacts)**
  - ✅ **Checked** (Fresh Run):
    - Deletes all previous output files
    - Re-downloads all observations from iNaturalist
    - Use for first run or complete refresh
  
  - ❌ **Unchecked** (Incremental Update):
    - Keeps existing cached data
    - Only identifies new observations since last run
    - Much faster for daily updates
    - Reuses previously downloaded photos/maps where possible

- **Fetch All Observations**
  - Usually keep checked
  - Uncheck only for testing with small subset

- **Cache Observations**
  - Keep checked!
  - Saves observation data for faster reruns

- **Use Incremental Fetch**
  - Only active when "Fresh Run" is unchecked
  - Fetches only NEW observations since last run
  - Essential for daily updates
  - Much faster than re-fetching everything

**💡 Important Usage Pattern:**

**First Run:**
- ✅ Check "Fresh Run"
- Generate your slideshow
- Click "Save Configuration"

**Daily Updates:**
- ❌ Uncheck "Fresh Run"
- ✅ Check "Use Incremental Fetch"
- Click "Generate Slideshow"
- Only processes new observations!

---

#### 7. Advanced Options

**What it is:** Fine control over map regeneration.

**Settings:**

- **Force Rebuild Base Map**
  - Regenerates the background map
  - Usually check this for first run
  - Uncheck after first run for speed

- **Force Rebuild All Maps**
  - Regenerates individual observation maps
  - Uncheck for faster reruns

- **Force Rebuild All Slides**
  - Regenerates all slide images
  - Uncheck for faster reruns

- **Skip OpenStreetMap Overlays (Faster)**
  - Skips roads and waterways
  - Much faster for large areas
  - Check if maps are slow

**💡 Tip:** After your first successful run, uncheck "Force Rebuild" options for much faster updates!

---

#### 8. PDF Output Settings

**What it is:** Optional PDF version of your slideshow.

**Settings:**

- **Create PDF Version**
  - Requires Chrome/Chromium installed
  - Can be very slow for large slideshows
  - Creates a shareable PDF file

- **PDF Size Limit (MB)**
  - Skip PDF creation if it would exceed this size
  - 0 = no limit (may create huge files!)
  - 50 MB recommended

**💡 Tip:** Disable PDF creation for 100+ photo slideshows to save time.

---

#### 9. Random Seed (Reproducibility)

**What it is:** Controls randomness in observation selection.

**Settings:**

- **Use Random Selection**
  - ✅ Checked: Different photos every run (recommended)
  - ❌ Unchecked: Uses R's current random state

- **Specific Random Seed** (optional)
  - Leave blank for true randomness
  - Enter a number (e.g., 12345) to get the exact same photos every time
  - Useful for testing or creating reproducible slideshows

---

### Saving Your Configuration

At the bottom of the Configuration tab:

**Buttons:**
- **Save Configuration** - Saves all current settings to `shiny_config.rds`
- **Load Configuration** - Restores previously saved settings

**💡 Best Practice:** After setting up your first slideshow, click "Save Configuration"! Then you can quickly restore these settings later.

---

### Generating and Monitoring

Click the **Run & Progress** tab.

#### Starting Generation

1. **Review your settings** in Configuration tab

2. **Click "Generate Slideshow"** (green button)
   - The button changes to show the process is running
   - Do NOT close the app window!

3. **Watch progress indicators update:**

   **🔭 Total Observations**
   - Shows total cached observation count
   - Updates when new observations are fetched

   **👥 Total Unique Observers**
   - Shows number of contributors
   - Updates with new data

   **📷 Photos (This Run)**
   - New photos downloaded in current run
   - Counter increases as photos download

   **🗺️ Maps (This Run)**
   - New maps created in current run
   - Counter increases as maps generate

   **🎬 Slides (This Run)**
   - New slides composed in current run
   - Counter increases as slides are created

4. **Monitor Progress Stages checklist:**
   - ✓ Initializing
   - ✓ Fetching observations from iNaturalist
   - ✓ Downloading photos
   - ✓ Creating maps
   - ✓ Composing slides
   - ✓ Building slideshow
   - ✓ Complete!

5. **Check Live Progress Log:**
   - Expandable section showing detailed output
   - Filtered to show important messages only
   - Look here if something seems wrong

#### Current Status

At the top, you'll see:
- **Current Status:** Ready / Initializing / Running / Complete / Error

#### Stopping Generation

If you need to stop:
- Click **"Stop Process"** (red button)
- The background process will be terminated
- Partial files may remain in output folder

#### Manual Refresh

If progress seems stuck:
- Click **"Refresh File Counts"**
- Manually updates the counters
- Check Live Progress Log for errors

**💡 Timing:** 
- Small slideshows (25 photos): 5-15 minutes
- Medium slideshows (50 photos): 15-30 minutes
- Large slideshows (100 photos): 30-60 minutes
- Times vary based on internet speed and computer performance

---

### Accessing Outputs

Click the **Outputs** tab.

#### Output Location

Shows the full path to your output folder, e.g.:
```
C:/Users/YourName/Documents/R/outputs/bioblitz_slideshow_output
```

#### Available Files

Lists the key files created:
- **slideshow.html** - Main slideshow (open in browser)
- **slideshow.pdf** - PDF version (if enabled)
- **collage.png** - Photo collage
- Additional files count

#### Quick Access Buttons

**🌐 Open Slideshow in Browser**
- Opens `slideshow.html` in your default web browser
- Ready to present!

**📁 Open Output Folder**
- Opens the output folder in Windows Explorer / Finder / File Manager
- View all generated files

**💡 Tip:** Bookmark the output folder for easy access to all your slideshow files!

---

### Daily Updates with the GUI

Perfect for multi-day bioblitz events where you want to add new observations each day.

#### Day 1 Setup

1. **Configuration Tab:**
   - Set all your settings
   - Enable "Fresh Run"
   - Click "Save Configuration"

2. **Run & Progress Tab:**
   - Click "Generate Slideshow"
   - Wait for completion
   - Check output looks good

3. **Set up for display:**
   - Open slideshow in browser
   - Press F for fullscreen
   - Enable "Loop Slideshow" if you want continuous display

#### Days 2-7 (Fast Updates)

1. **Configuration Tab:**
   - Click "Load Configuration" (restores all your settings)
   - **Uncheck "Fresh Run"** ⚠️ Important!
   - **Check "Use Incremental Fetch"** ⚠️ Important!
   - These settings fetch only NEW observations

2. **Run & Progress Tab:**
   - Notice indicators show cached counts immediately (🔭👥)
   - Click "Generate Slideshow"
   - **Much faster!** Only processes new observations
   - Photos/Maps/Slides counters show only new items

3. **Outputs Tab:**
   - Click "Open Slideshow in Browser"
   - Slideshow now includes new observations!

**⏱️ Time Savings:**
- Fresh run: 20-30 minutes
- Incremental update: 2-5 minutes (only new observations)

---

## Method 2: Using the R Script

### Initial Setup (Script)

#### 1. Locate the Script

Find the file: `iNaturalist_Bioblitz_Slideshow_Generator.R`

#### 2. Open in RStudio

- File → Open File
- Navigate to the script
- Click Open

#### 3. Find the Configuration Section

Scroll down to around **line 50** where you'll see:

```r
# ==============================================================================
# CONFIGURATION
# ==============================================================================
```

This is where you'll customize all the settings.

---

### Understanding the Configuration

The configuration section has comments explaining each setting. Here are the key ones:

#### Essential Settings

```r
# iNaturalist project identifier (from project URL)
project_slug <- "walpole-wilderness-bioblitz-2025"

# How many photos to include in slideshow
n_photos <- 25

# For welcome slides and branding
bioblitz_name <- "Walpole Wilderness"
bioblitz_year <- 2025

# Optional: path to your logo file (JPG or PNG)
bioblitz_logo <- "walpole_bioblitz_logo.jpg"
```

**Finding your project slug:**
1. Go to your iNaturalist project page
2. Look at URL: `https://www.inaturalist.org/projects/YOUR-PROJECT-SLUG`
3. Copy everything after `/projects/`

#### Location Settings

```r
# Coordinates of your bioblitz headquarters
hq_lon <- 116.634398   # Longitude (E/W)
hq_lat <- -34.992854   # Latitude (N/S)

# Map settings
base_map_zoom <- 14    # 13-15 typical (higher = more detail, slower)
buffer_km <- 3.5       # Area around observations (km)
default_dist_m <- 4000 # Radius for individual maps (meters)
```

**Finding your coordinates:**
1. Open Google Maps
2. Right-click your HQ location
3. Click the coordinates to copy
4. First number is longitude, second is latitude

#### Diversity Controls

```r
# Ensure fair representation
max_obs_per_observer_pct <- 0.15  # Max 15% from any one observer
max_obs_per_observer_abs <- 5     # Hard limit: max 5 per observer
max_plants_pct <- 0.50             # Max 50% plants (balance taxonomy)
```

#### Map Provider

Choose your map style:

```r
# Options:
map_provider <- "Esri.WorldImagery"    # Satellite (high quality, slower)
map_provider <- "OpenStreetMap"        # Street map (fast)
map_provider <- "CartoDB.Voyager"      # Balanced (fast, good detail)
map_provider <- "Esri.WorldTopoMap"    # Topographic
```

**For large bioblitzes (10-20x faster):**
```r
map_provider <- "OpenStreetMap"
skip_osm_overlays <- TRUE
base_map_zoom <- 12
```

#### Run Modes

**Fresh run** (first time or complete refresh):
```r
fresh_run <- TRUE                   # Delete old files
fetch_all_observations <- TRUE      # Download all observations
cache_observations <- TRUE          # Save for next time
```

**Incremental update** (daily bioblitz):
```r
fresh_run <- FALSE                  # Keep existing files
use_incremental_fetch <- TRUE       # Only new observations
cache_observations <- TRUE          # Update cache
```

#### Slideshow Settings

```r
auto_advance_ms <- 7000        # 7 seconds per slide
auto_slide_stoppable <- TRUE   # Allow manual control
slideshow_loop <- FALSE        # Don't loop (change to TRUE for displays)
max_collage <- 25              # Photos in final collage
```

#### PDF Settings

```r
create_pdf <- TRUE             # Generate PDF version (requires Chrome)
pdf_size_limit_mb <- 50        # Skip if PDF would be larger than this
```

---

### Running the Script

#### Method A: Source Button (Recommended)

1. **Save your changes:** Ctrl+S (Windows/Linux) or Cmd+S (Mac)

2. **Click "Source"** at the top right of the script editor
   - Or press: Ctrl+Shift+S (Windows/Linux) or Cmd+Shift+S (Mac)

3. **Watch the Console** (bottom pane) for progress messages:
   ```
   === Loading Required Packages ===
   === Fetching Observations from iNaturalist ===
   Total observations: 5495
   === Downloading Photos ===
   Ready: 25 photos
   === Creating Maps ===
   === Composing Slides ===
   === Building Slideshow ===
   === SCRIPT COMPLETED SUCCESSFULLY ===
   ```

4. **Wait for completion:**
   - Small (25): 5-15 minutes
   - Medium (50): 15-30 minutes
   - Large (100): 30-60 minutes

5. **Find your outputs:** `outputs/slideshow/`

#### Method B: Run Line-by-Line (For Troubleshooting)

1. Place cursor at the start of the script
2. Press Ctrl+Enter (Windows/Linux) or Cmd+Return (Mac) repeatedly
3. Runs one line at a time
4. Watch Console for each result
5. Good for finding errors

#### Method C: Command Line (Advanced)

```bash
cd /path/to/script
Rscript iNaturalist_Bioblitz_Slideshow_Generator.R
```

---

### Daily Updates with the Script

For multi-day bioblitzes:

#### Day 1

Edit script:
```r
fresh_run <- TRUE
n_photos <- 50
slideshow_loop <- TRUE
```

Run script. Takes 20-30 minutes.

#### Days 2-7

Edit script:
```r
fresh_run <- FALSE
use_incremental_fetch <- TRUE
# Keep other settings the same
```

Run script. Takes 2-5 minutes!

---

## Configuration Reference

This applies to both GUI and script methods.

### Complete Parameter List

| Parameter | Default | Description | GUI Location |
|-----------|---------|-------------|--------------|
| `project_slug` | Required | iNaturalist project identifier | Project Settings |
| `n_photos` | 25 | Number of photos in slideshow | Project Settings |
| `bioblitz_name` | Required | Name for slides | Project Settings |
| `bioblitz_year` | 2025 | Year for slides | Project Settings |
| `bioblitz_logo` | "" | Path to logo file | Project Settings |
| `hq_lon` | Required | Headquarters longitude | Location Settings |
| `hq_lat` | Required | Headquarters latitude | Location Settings |
| `base_map_zoom` | 14 | Map zoom level (10-18) | Location Settings |
| `buffer_km` | 3.5 | Buffer around observations (km) | Location Settings |
| `default_dist_m` | 4000 | Individual map radius (m) | Location Settings |
| `max_obs_per_observer_pct` | 0.15 | Max % from one observer | Diversity Settings |
| `max_obs_per_observer_abs` | 5 | Absolute max per observer | Diversity Settings |
| `max_plants_pct` | 0.50 | Max % plant photos | Diversity Settings |
| `map_provider` | "Esri.WorldImagery" | Map style | Advanced (script only) |
| `auto_advance_ms` | 7000 | Slide duration (milliseconds) | Slideshow Settings |
| `auto_slide_stoppable` | TRUE | Allow pause | Slideshow Settings |
| `slideshow_loop` | FALSE | Loop at end | Slideshow Settings |
| `max_collage` | 25 | Collage photo count | Slideshow Settings |
| `fresh_run` | TRUE | Delete old outputs | Run Mode & Performance |
| `fetch_all_observations` | TRUE | Fetch all vs subset | Run Mode & Performance |
| `cache_observations` | TRUE | Save observation data | Run Mode & Performance |
| `use_incremental_fetch` | TRUE | Fetch only new obs | Run Mode & Performance |
| `force_rebuild_base_map` | TRUE | Regenerate base map | Advanced Options |
| `force_rebuild_maps` | FALSE | Regenerate all maps | Advanced Options |
| `force_rebuild_slides` | FALSE | Regenerate all slides | Advanced Options |
| `skip_osm_overlays` | FALSE | Skip roads/waterways | Advanced Options |
| `create_pdf` | TRUE | Generate PDF | PDF Output Settings |
| `pdf_size_limit_mb` | 50 | PDF size limit (MB) | PDF Output Settings |
| `use_random_seed` | TRUE | Use randomization | Random Seed |
| `random_seed` | NULL | Specific seed number | Random Seed |
| `out_dir` | (varies) | Output folder name | Project Settings |

---

## Output Files

Both methods create the same outputs in your designated output folder.

### Main Outputs

**slideshow.html**
- Interactive HTML presentation
- Open in any web browser
- Auto-advancing slides with controls
- Press F for fullscreen, ESC to exit
- Space bar or arrows to navigate

**slideshow.qmd**
- Quarto source file
- Open in RStudio to edit
- Modify text, reorder slides, change styling
- Re-render with Quarto

**slideshow.pdf** (if enabled)
- Shareable PDF version
- Good for printing or email
- All slides in one file

### Supporting Files

**slides/** folder
- Individual slide images (PNG)
- One per observation
- Plus welcome slide and collage

**maps/** folder
- Location maps for each observation
- Base map (large area showing all observations)
- Individual observation maps

**photos/** folder
- Downloaded observation photos
- High resolution
- Named by observation ID

**Cache files** (.rds)
- `cached_observations.rds` - Observation data
- `selected_obs.rds` - Random selection
- Speeds up reruns
- Can safely delete to start fresh

---

## Troubleshooting

### Common Issues (Both Methods)

#### "Cannot connect to iNaturalist"

**Causes:**
- No internet connection
- iNaturalist API is down
- Incorrect project slug

**Solutions:**
- Check internet connection
- Try accessing iNaturalist.org in browser
- Verify project slug is correct
- Wait and try again (API may be temporarily down)

---

#### "No observations found"

**Causes:**
- Project has no observations yet
- Project has no observations with photos
- Incorrect project slug
- Date filters excluding all observations

**Solutions:**
- Verify project has observations with photos on iNaturalist
- Double-check project slug
- Ensure `fetch_all_observations <- TRUE` (or checked in GUI)
- Remove any date filters

---

#### "Script is very slow"

**Causes:**
- Large bioblitz area with detailed maps
- High zoom level
- Satellite imagery provider
- Many observations

**Solutions:**

**Quick fixes (GUI):**
- Change to "OpenStreetMap" provider (script only)
- Check "Skip OpenStreetMap Overlays"
- Reduce "Base Map Zoom Level" to 12-13
- Reduce "Map Buffer" to 2-3 km

**Quick fixes (Script):**
```r
map_provider <- "OpenStreetMap"
skip_osm_overlays <- TRUE
base_map_zoom <- 12
buffer_km <- 2.5
```

These can make maps 10-20x faster!

---

#### Package Installation Fails

**Symptoms:**
```
Error: package 'xyz' is not available
```

**Solutions:**
1. Update R to latest version
2. Update RStudio to latest version
3. Try manual installation:
   ```r
   install.packages("package_name")
   ```
4. Check Console for specific errors
5. Install dependencies first:
   ```r
   install.packages(c("terra", "sf", "ggplot2"))
   ```

---

### Shiny App Specific Issues

#### "Cannot find script file"

**Error message:**
```
ERROR: Cannot find 'Final_Walpole_Bioblitz_Slideshow_Script.R'
```

**Solution:**
1. Configuration Tab → Script Location
2. Enter correct filename
3. Ensure script is in same folder as Shiny app
4. Check Current directory in Console

---

#### Progress Indicators Stuck at Zero

**Symptoms:**
- Counters show 0
- Status shows "Running"
- Time passes with no updates

**Solutions:**
1. Click "Refresh File Counts" button
2. Check "Live Progress Log" for errors
3. Wait - initialization can take 2-3 minutes
4. Look in output folder to see if files are being created

---

#### "Process may still be running"

**When it happens:**
- After closing app window
- After clicking Stop

**Solution:**
- Reopen app
- Click "Stop Process" again
- Or check Task Manager (Windows) / Activity Monitor (Mac) for R processes
- Kill any orphaned Rscript processes

---

#### App Freezes or Becomes Unresponsive

**What's happening:**
- App interface may freeze while script runs
- This is normal - background process is working

**What to do:**
- **Don't close the browser/window**
- Check Live Progress Log (may still update)
- Check output folder for new files
- Wait for completion
- Background process runs separately from GUI

---

### Script-Specific Issues

#### "Object not found" errors

**Symptoms:**
```
Error: object 'xyz' not found
```

**Causes:**
- Ran partial script
- Skipped package loading section
- Variable name typo in configuration

**Solutions:**
- Always run from beginning (click Source)
- Never skip the package loading section
- Check variable names match exactly

---

#### "Fresh run vs incremental confusion"

**Problem:**
- Incremental run takes too long
- Fresh run doesn't find observations

**Understanding Fresh Run:**
- ✅ Checked: Deletes everything, starts over
- Use for first run or when you want to completely refresh

**Understanding Incremental:**
- ❌ Unchecked: Keeps cache, only fetches new observations
- Requires `use_incremental_fetch <- TRUE`
- Much faster for daily updates
- Needs cache from previous run

---

## Tips and Best Practices

### For Multi-Day Bioblitz Events

**Day 1:**
- Use Fresh Run
- Generate 50-photo slideshow
- Enable Loop
- Set auto-advance to 10 seconds
- Display on large screen at registration

**Days 2-7:**
- Use Incremental Update
- Keep same settings
- Regenerate each morning
- Updates only take 3-5 minutes!

---

### For Presentations

**Settings:**
- 25-50 photos
- Auto-advance: 7 seconds
- Don't loop
- Create PDF for sharing

**Presenting:**
- Press F for fullscreen
- Press Space to advance manually (overrides auto-advance)
- Press ESC to exit

---

### For Social Media

**Create short version:**
- 10-15 photos
- Create PDF
- Extract favorite slides as images
- Share slideshow.html link

---

### Optimizing Performance

**For FAST slideshow generation:**

```r
# In script:
map_provider <- "OpenStreetMap"
skip_osm_overlays <- TRUE
base_map_zoom <- 12
buffer_km <- 2
create_pdf <- FALSE
```

**In GUI:**
- Advanced Options → Check "Skip OpenStreetMap Overlays"
- Location Settings → Base Map Zoom Level: 12
- Location Settings → Map Buffer: 2 km
- PDF Output Settings → Uncheck "Create PDF"

**Trade-off:** Faster generation, less detailed maps

---

### Ensuring Diversity

**Problem:** One observer dominates slideshow

**Solution:**
```r
max_obs_per_observer_abs <- 3
# Or in GUI: Diversity Settings → Absolute Max: 3
```

**Problem:** Too many plant photos

**Solution:**
```r
max_plants_pct <- 0.30  # Max 30%
# Or in GUI: Diversity Settings → Max % Plant Photos: 30%
```

---

### Reproducing Exact Results

**Want same photos every time?**

```r
# In script:
use_random_seed <- TRUE
random_seed <- 42  # Any number

# In GUI:
# Random Seed → Check "Use Random Selection"
# Specific Random Seed: 42
```

Every run with seed 42 will select the same observations!

---

### Managing Disk Space

Slideshows can get large:
- 25 photos: ~500 MB
- 50 photos: ~1 GB
- 100 photos: ~2 GB

**To save space:**
- Delete old output folders when done
- Disable PDF for large slideshows
- Reduce `base_map_zoom` (smaller map files)

---

## Advanced Topics

### Customizing the Slideshow

Edit `slideshow.qmd` in RStudio:

**Change title slide:**
```yaml
title: "Your Custom Title"
subtitle: "Your Subtitle"
```

**Change colors:**
```css
.reveal h1 { color: #yourcolor; }
```

**Add extra slides:**
Add between observation slides in QMD file

**Reorder slides:**
Cut and paste slide sections

**Re-render:**
```r
quarto::quarto_render("outputs/slideshow/slideshow.qmd")
```

---

### Automating Daily Updates

**Windows Task Scheduler:**
1. Create `run_daily.bat`:
   ```batch
   "C:\Program Files\R\R-4.x.x\bin\Rscript.exe" "C:\path\to\script.R"
   ```
2. Schedule in Task Scheduler
3. Runs automatically each morning

**Mac/Linux Cron:**
1. Edit crontab: `crontab -e`
2. Add line:
   ```
   0 8 * * * Rscript /path/to/script.R
   ```
3. Runs at 8 AM daily

---

### Using Different Map Providers

**Available providers:**
- `Esri.WorldImagery` - Satellite
- `OpenStreetMap` - Street map
- `CartoDB.Voyager` - Light, modern
- `CartoDB.Positron` - Very light
- `Esri.WorldTopoMap` - Topographic
- `Esri.WorldStreetMap` - Street details

**In script:** Change `map_provider`  
**In GUI:** Must edit main script (advanced)

---

### Multiple Output Versions

Want different versions for different audiences?

**Create multiple configurations:**

**Script method:**
```r
# Save different script versions:
# script_presentation.R (25 photos, no loop)
# script_display.R (50 photos, loop, fast maps)
# script_comprehensive.R (100 photos, detailed maps)
```

**GUI method:**
- Change "Output Directory Name" for each version
- Save configuration after each
- Each gets own output folder

---

### Integrating with Workflows

The script can be part of larger workflows:

**R Markdown reports:**
```r
# In your R Markdown:
source("iNaturalist_Bioblitz_Slideshow_Generator.R")
```

**Shiny apps:**
```r
# Call from your Shiny app:
system("Rscript slideshow_script.R")
```

**API integration:**
- Script already uses iNaturalist API
- Extend to push results elsewhere
- Automate social media posts

---

## Conclusion

You now have two powerful ways to create beautiful bioblitz slideshows:

🖥️ **Shiny GUI App:** Perfect for most users, especially during multi-day events. No code editing required, real-time progress tracking, and easy configuration saving.

📝 **R Script:** Ideal for advanced users who want maximum control, automation, or integration into larger workflows.

Both methods produce the same high-quality outputs and can be used interchangeably based on your needs.

**Next Steps:**
1. Choose your method (try GUI first!)
2. Gather your bioblitz information
3. Configure your first slideshow
4. Generate and celebrate your biodiversity discoveries!

**Questions or Issues?**
- Check this guide's Troubleshooting section
- Open an issue on GitHub
- Contact through project discussions

**Happy Slideshow Creating!** 🦋🌿🦎

---

*Version 3.0 | November 2025*  
*Updated to include Shiny GUI application*
