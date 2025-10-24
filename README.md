---
title: "iNaturalist Bioblitz Slideshow Generator - User Guide"
format: html
---

# iNaturalist Bioblitz Slideshow Generator
## Complete User Guide

**Version 1.0 | October 2025**

---

## Table of Contents

1. [Introduction](#introduction)
2. [What This Script Does](#what-this-script-does)
3. [Prerequisites](#prerequisites)
4. [Initial Setup](#initial-setup)
5. [Understanding the Configuration Section](#understanding-the-configuration-section)
6. [Running the Script](#running-the-script)
7. [Output Files](#output-files)
8. [Troubleshooting](#troubleshooting)
9. [Tips and Best Practices](#tips-and-best-practices)

---

## Introduction

This script automatically creates beautiful slideshows from iNaturalist bioblitz observations. It downloads photos, creates custom maps showing where each observation was made, and assembles everything into a professional slideshow presentation.

The slideshow includes:
- Random selection of observations with biodiversity diversity controls
- Satellite maps with roads and waterways showing observation locations
- Organized by iconic taxon groups (Plants, Insects, Birds, etc.)
- Auto-advancing slides perfect for display at events
- Multiple output formats (HTML, QMD, and PDF)

**Who is this guide for?** Anyone who wants to create a slideshow from an iNaturalist project, even if you're new to R and RStudio.

---

## What This Script Does

### The Process

1. **Connects to iNaturalist**: Downloads observation data from your specified project
2. **Smart Sampling**: Randomly selects observations while ensuring diversity:
   - Limits how many photos from each observer (prevents one person dominating)
   - Controls plant vs. animal ratio
   - Ensures representation across different species groups
3. **Downloads Photos**: Gets high-quality images of each selected observation
4. **Creates Custom Maps**: For each observation, generates a satellite map showing:
   - The observation location (marked with a red star)
   - Your bioblitz headquarters (marked with "HQ")
   - Roads (in gold) and waterways (in blue) for context
   - Scale bar for distance reference
5. **Composes Slides**: Combines photos with maps side-by-side, adds species names and observer credits
6. **Builds Slideshow**: Creates a professional presentation organized by organism type
7. **Generates Outputs**: Produces HTML (for viewing), QMD (for editing), and optionally PDF versions

### Key Features

- **Truly Random**: Every run selects different photos (perfect for daily displays)
- **Diversity Controls**: Ensures fair representation across observers and taxa
- **Efficient Caching**: After the first run, only checks for new observations (much faster!)
- **Professional Quality**: Satellite imagery, clean typography, beautiful styling
- **Customizable**: Extensive configuration options for your specific needs

---

## Prerequisites

### Required Software

1. **R** (version 4.0 or higher)
   - Download from: https://cran.r-project.org/
   - Choose your operating system and follow installation instructions

2. **RStudio** (Desktop version)
   - Download from: https://posit.co/download/rstudio-desktop/
   - Install after R is installed

3. **Google Chrome** (for PDF generation)
   - Download from: https://www.google.com/chrome/
   - Required if you want automatic PDF creation

### R Packages (Installed Automatically)

The script will automatically install these packages the first time you run it:
- `httr2`, `jsonlite` - For connecting to iNaturalist
- `dplyr`, `tidyr`, `purrr` - For data manipulation
- `ggplot2`, `sf` - For creating maps
- `maptiles`, `terra`, `osmdata` - For satellite imagery and geographic features
- `magick` - For image processing
- `quarto` - For creating the slideshow
- And several others

**This may take 10-15 minutes the first time**, so be patient!

---

## Initial Setup

### Step 1: Install R and RStudio

1. First install R from https://cran.r-project.org/
2. Then install RStudio from https://posit.co/download/rstudio-desktop/
3. Open RStudio - you should see 4 panes (Console, Source, Environment, Files/Plots)

### Step 2: Create a New Project

Creating a project keeps all your files organized in one place.

1. In RStudio, click **File** → **New Project**
2. Choose **New Directory**
3. Choose **New Project**
4. **Directory name**: Give it a name like `MyBioblitz_Slideshow`
5. **Create project as subdirectory of**: Click **Browse** and choose where to save it (e.g., your Documents folder)
6. Click **Create Project**

RStudio will restart with your new project open.

### Step 3: Prepare Your Files

1. **Get the Script**:
   - Save the slideshow script file (e.g., `walpole_bioblitz_slideshow_v3.R`) into your project folder
   - You can see where your project folder is by looking at the Files pane (bottom right) - it shows your working directory

2. **Add Your Logo** (Optional but recommended):
   - Find your bioblitz logo image (JPG, PNG, etc.)
   - Copy it into the same project folder
   - Remember the exact filename - you'll need it later
   - Example: `My-Bioblitz-Logo.jpg`

3. **Verify File Locations**:
   - In RStudio's Files pane (bottom right), you should see:
     - Your script file (`.R` extension)
     - Your logo file (if you have one)

### Step 4: Open the Script

1. In RStudio's Files pane (bottom right), find your script file
2. Click on it to open it in the Source pane (top left)
3. You should now see all the script code

---

## Understanding the Configuration Section

The top of the script has a **CONFIGURATION** section. This is where you customize the script for your needs. Everything between these lines can be changed:

```r
# ==============================================================================
# CONFIGURATION - EDIT THESE SETTINGS
# ==============================================================================
```

and

```r
# ==============================================================================
# END OF CONFIGURATION - DO NOT EDIT BELOW THIS LINE
# ==============================================================================
```

**⚠️ IMPORTANT**: Only edit settings in the CONFIGURATION section. Don't change anything below the "DO NOT EDIT" line unless you know what you're doing!

### Project Settings

```r
project_slug <- "walpole-wilderness-bioblitz-2025"
n_photos <- 25
bioblitz_logo <- "Walpole-Wilderness-Bioblitz.jpg"
```

**What to change:**

- `project_slug`: Your iNaturalist project identifier
  - **How to find it**: Go to your project page on iNaturalist.org
  - Look at the URL: `https://www.inaturalist.org/projects/YOUR-PROJECT-NAME`
  - Copy everything after `/projects/`
  - Example: For `https://www.inaturalist.org/projects/city-nature-challenge-2025`, use `"city-nature-challenge-2025"`

- `n_photos`: Number of photos in your slideshow
  - **Common values**: 
    - `25` - Quick slideshow (~3 minutes at 7 seconds per slide)
    - `50` - Medium slideshow (~6 minutes)
    - `100` - Long slideshow (~12 minutes)
    - Any number up to your total observations
  - **Note**: Larger slideshows take longer to generate

- `bioblitz_logo`: Your logo filename
  - **Must be exact**, including capitals and file extension
  - Example: `"My-Bioblitz-Logo.jpg"` or `"logo.png"`
  - If you don't have a logo, leave it as is (script will skip if not found)

### HQ Location (for maps)

```r
hq_lon <- 116.634398
hq_lat <- -34.992854
```

**What to change:**

These are the coordinates of your bioblitz headquarters or main meeting point. This appears on every map as a yellow diamond marked "HQ".

**How to find your coordinates:**
1. Go to Google Maps
2. Find your headquarters location
3. Right-click on the spot
4. Click on the coordinates (they'll be copied)
5. Paste them into the script
6. Format: First number is longitude (`hq_lon`), second is latitude (`hq_lat`)

Example: If Google Maps shows `-34.992854, 116.634398`, use:
```r
hq_lon <- 116.634398
hq_lat <- -34.992854
```

### Diversity Settings

```r
max_obs_per_observer_pct <- 0.15
max_obs_per_observer_abs <- 5
max_plants_pct <- 0.50
```

**What these do:**

These settings ensure your slideshow shows diversity - no single observer or organism type dominates.

- `max_obs_per_observer_pct`: Maximum percentage from any one observer
  - `0.15` = 15% maximum
  - Example: In a 100-photo slideshow, no observer can have more than 15 photos
  - **When to adjust**: Usually leave at 15%

- `max_obs_per_observer_abs`: Absolute maximum per observer
  - Takes precedence if lower than the percentage
  - Example: Even if 15% = 15 photos, this caps it at 5
  - **For large slideshows (100+)**: Keep at 5 for good diversity
  - **For small slideshows (25)**: Can increase to 10

- `max_plants_pct`: Maximum percentage of plants
  - `0.50` = Plants can be up to 50% of photos
  - Plants are often over-represented in bioblitzes
  - **When to adjust**: 
    - If your event was plant-focused: increase to `0.70`
    - If you want more animals: decrease to `0.30`

### Random Seed Settings

```r
use_random_seed <- TRUE
random_seed <- NULL
```

**What these do:**

Control whether each run produces different photos or the same photos.

- `use_random_seed <- TRUE`: Each run selects different random photos ✅ **(Recommended for most uses)**
- `use_random_seed <- FALSE`: Uses R's default randomization

- `random_seed <- NULL`: Generate a new seed each time (truly random)
- `random_seed <- 42`: Use a specific number to get reproducible results

**When to change:**

- **For event displays**: Leave as `TRUE` and `NULL` - different photos each day!
- **For a specific version**: Set a number like `random_seed <- 12345` to always get the same selection
- **To reproduce a specific slideshow**: Check the console output for the seed number used, then set it

### Run Mode

```r
fresh_run <- TRUE
fetch_all_observations <- TRUE
cache_observations <- TRUE
use_incremental_fetch <- TRUE
```

**What these do:**

Control how the script handles data fetching and caching.

- `fresh_run`: Start completely fresh
  - `TRUE` = Delete old maps/slides/photos and regenerate everything
  - `FALSE` = Keep existing files where possible (much faster!)

- `fetch_all_observations`: Get all observations from the project
  - `TRUE` = Download complete dataset **(Recommended for first run)**
  - `FALSE` = Just fetch a subset (for testing)

- `cache_observations`: Save downloaded observations
  - `TRUE` = Save data locally for faster future runs **(Always recommended)**
  - `FALSE` = Re-download every time (slow!)

- `use_incremental_fetch`: Only check for new observations
  - `TRUE` = After first run, only download new data **(Much faster!)**
  - `FALSE` = Always re-download everything

**When to change:**

**First time running the script:**
```r
fresh_run <- TRUE
fetch_all_observations <- TRUE
cache_observations <- TRUE
use_incremental_fetch <- TRUE
```

**Daily updates (after first run):**
```r
fresh_run <- FALSE              # Keep existing files
fetch_all_observations <- TRUE  # (ignored when incremental)
cache_observations <- TRUE
use_incremental_fetch <- TRUE   # Only get new observations (fast!)
```

**Complete regeneration (new maps, new cache):**
```r
fresh_run <- TRUE               # Delete everything and start over
```

### Force Rebuild Options

```r
force_rebuild_base_map <- FALSE
force_rebuild_maps <- FALSE
force_rebuild_slides <- FALSE
skip_osm_overlays <- FALSE
```

**What these do:**

Fine-tune what gets regenerated without doing a full `fresh_run`.

- `force_rebuild_base_map`: Recreate the satellite base map
  - Usually `FALSE`
  - Set `TRUE` if: Map coverage changed, want higher quality, base map looks wrong

- `force_rebuild_maps`: Recreate all individual observation maps
  - Usually `FALSE`
  - Set `TRUE` if: Maps look wrong, changed map settings

- `force_rebuild_slides`: Recreate all slide compositions
  - Usually `FALSE`  
  - Set `TRUE` if: Text/layout looks wrong

- `skip_osm_overlays`: Skip roads and waterways
  - Usually `FALSE` (include roads/waterways)
  - Set `TRUE` if: Fetching is slow, don't need roads/waterways

**When to change:**

- **Normal runs**: Leave all as `FALSE`
- **Map problems**: Set `force_rebuild_maps <- TRUE`
- **Fast testing**: Set `skip_osm_overlays <- TRUE`

### Map Settings

```r
base_map_zoom <- 14
buffer_km <- 3.5
default_dist_m <- 4000
```

**What these do:**

Control map appearance and coverage.

- `base_map_zoom`: Satellite image detail level
  - `14` = Good balance (recommended)
  - `13` = Zoomed out more, larger area
  - `15` = Zoomed in more, more detail
  - **Higher = more detail but slower downloads**

- `buffer_km`: Extra space around observations
  - `3.5` = 3.5km buffer around the project area
  - **Larger values**: More context but bigger maps
  - **Smaller values**: Tighter focus but less context

- `default_dist_m`: Radius for individual observation maps
  - `4000` = 4km radius around each observation
  - Ensures both observation and HQ are visible

**When to change:**

- **Large area project**: Increase `buffer_km` to `5`
- **Small area project**: Decrease `buffer_km` to `2`
- **Very detailed maps**: Increase `base_map_zoom` to `15` (slower)

### Slideshow Settings

```r
auto_advance_ms <- 7000
auto_slide_stoppable <- TRUE
slideshow_loop <- FALSE
max_collage <- 25
create_pdf <- TRUE
pdf_size_limit_mb <- 50
```

**What these do:**

Control slideshow behavior and outputs.

- `auto_advance_ms`: Time per slide in milliseconds
  - `7000` = 7 seconds per slide
  - `5000` = 5 seconds (faster)
  - `10000` = 10 seconds (slower)
  - **To calculate**: slides × seconds = total time
    - 50 slides × 7 sec = 5.8 minutes

- `auto_slide_stoppable`: Allow stopping auto-advance
  - `TRUE` = Press a key to stop/start **(Recommended)**
  - `FALSE` = Can't stop auto-advance

- `slideshow_loop`: Restart at end
  - `FALSE` = Stop at last slide **(For events)**
  - `TRUE` = Loop forever (for unattended displays)

- `max_collage`: Photos in final collage slide
  - `25` = Show 25 photos in a grid at the end
  - Nice summary slide

- `create_pdf`: Generate PDF version
  - `TRUE` = Create PDF (requires Chrome)
  - `FALSE` = Skip PDF (HTML only)
  - **For large slideshows (100+)**: Consider `FALSE`

- `pdf_size_limit_mb`: Skip PDF if too large
  - `50` = Skip if estimated over 50MB
  - `0` = No limit, always try
  - **Large slideshows**: Set to `0` or `FALSE`

**When to change:**

- **Event loop display**: `slideshow_loop <- TRUE`, `auto_advance_ms <- 5000`
- **Presentation**: `slideshow_loop <- FALSE`, `auto_slide_stoppable <- TRUE`
- **Large slideshow**: `create_pdf <- FALSE` or increase `pdf_size_limit_mb`

### Output Settings

```r
out_dir <- "outputs/walpole_wilderness_bioblitz_2025_slideshow"
diagnostic_mode <- TRUE
```

**What these do:**

- `out_dir`: Where files are saved
  - Default creates a subfolder in your project
  - Can change to any folder path
  - Example: `"my_slideshows/january_2025"`

- `diagnostic_mode`: Show detailed progress
  - `TRUE` = Show lots of helpful messages **(Recommended)**
  - `FALSE` = Quiet mode

**When to change:**

- **Different output location**: Change `out_dir` path
- **Multiple slideshows**: Use different folder names for each

---

## Running the Script

### First Time Running

1. **Review Configuration**: Make sure you've set at least:
   - `project_slug` (your iNaturalist project)
   - `hq_lon` and `hq_lat` (your headquarters coordinates)
   - `bioblitz_logo` (your logo filename, if you have one)

2. **Run Mode Settings**:
   ```r
   fresh_run <- TRUE
   fetch_all_observations <- TRUE
   cache_observations <- TRUE
   use_incremental_fetch <- TRUE
   ```

3. **Start the Script**:
   - Click anywhere in the script
   - Click **Code** → **Run Region** → **Run All**
   - Or press **Ctrl+Alt+R** (Windows/Linux) or **Cmd+Option+R** (Mac)

4. **Be Patient**:
   - **First run takes a while!** Possibly 15-30 minutes for a 25-photo slideshow
   - The script needs to:
     - Install packages (first time only, 5-10 minutes)
     - Download observation data (2-5 minutes)
     - Download photos (1-5 minutes depending on internet)
     - Download satellite imagery (2-5 minutes)
     - Fetch road and waterway data (2-5 minutes)
     - Create maps (2-10 minutes depending on number of photos)
     - Compose slides (1-2 minutes)
     - Generate HTML and PDF (1-2 minutes)

5. **Watch the Console**:
   - The bottom-left pane (Console) shows progress
   - Look for sections like:
     - "=== FETCHING OBSERVATIONS ===" ✓
     - "=== BASE MAP ===" ✓
     - "=== DOWNLOADING PHOTOS ===" ✓
     - "=== CREATING MAPS ===" ✓
     - "=== COMPLETE ===" ✓

6. **Check for Errors**:
   - Red text = errors (see [Troubleshooting](#troubleshooting))
   - Black text = normal progress
   - If it stops, scroll up to find the error message

### Subsequent Runs (Daily Updates)

Much faster after the first run!

1. **Adjust Settings**:
   ```r
   fresh_run <- FALSE              # Keep existing files
   use_incremental_fetch <- TRUE   # Only new observations
   ```

2. **Change Random Selection** (optional):
   - The default settings already randomize each run
   - No changes needed for different photos each time!

3. **Run the Script**:
   - Same as before: **Code** → **Run All** or **Ctrl+Alt+R**
   - **Much faster now**: 5-10 minutes instead of 30!
   - It only downloads new observations and regenerates what's needed

### Running with Different Settings

**Want 50 photos instead of 25?**
```r
n_photos <- 50
fresh_run <- FALSE    # Can reuse cached data
```

**Need to regenerate everything?**
```r
fresh_run <- TRUE     # Start from scratch
```

**Testing changes without full regeneration?**
```r
fresh_run <- FALSE
force_rebuild_slides <- TRUE    # Just rebuild slide compositions
```

---

## Output Files

After running successfully, look in your output folder (check the Files pane, or look for the path shown in `out_dir`).

### Main Files

1. **slideshow.html** - The slideshow!
   - **Double-click to open** in your web browser
   - **Press 'F' for fullscreen**
   - **Press 'S' for speaker notes**
   - **Press 'E' for PDF export mode**
   - Arrow keys or clicking navigates slides
   - Best for presentations and event displays

2. **slideshow.qmd** - Source file
   - Quarto markdown source
   - Can edit to customize text, slides, etc.
   - Advanced users only

3. **slideshow.pdf** - PDF version (if enabled)
   - For printing or sharing
   - May not be created for large slideshows
   - See [Troubleshooting](#troubleshooting) if missing

### Supporting Folders

- **photos/** - Downloaded observation photos
- **maps/** - Generated maps for each observation
- **slides/** - Composed slides (photo + map combinations)
- **base_map_cache/** - Cached satellite imagery
  - Includes `preview_full_project_map.png` - overview of project area
- **styles/** - CSS styling files

### Cache Files

- **observations_cache.rds** - Downloaded observation data
- **fetch_state.rds** - Timestamp of last fetch
- **photo_manifest.rds** - Photo download tracking

**Don't delete these!** They make subsequent runs much faster.

---

## Troubleshooting

### Problem: "No observations found"

**Cause**: Project slug is wrong or project has no observations with photos.

**Solution**:
1. Check your `project_slug` spelling
2. Go to your project on iNaturalist.org
3. Verify the URL: `https://www.inaturalist.org/projects/YOUR-SLUG-HERE`
4. Make sure the project has observations with photos

### Problem: "Logo file not found"

**Cause**: Logo filename doesn't match actual file.

**Solution**:
1. Look in your Files pane (bottom right)
2. Find your logo file
3. Copy the **exact** filename including capitals and extension
4. Update `bioblitz_logo <- "EXACT-FILENAME.jpg"`

### Problem: "Chrome/Chromium not installed"

**Cause**: PDF creation needs Chrome but can't find it.

**Solution**:
1. Install Google Chrome from https://www.google.com/chrome/
2. Or set `create_pdf <- FALSE` to skip PDF creation
3. You can create PDF manually later from the HTML file

### Problem: "PDF cannot be overwritten (may be locked)"

**Cause**: PDF file is open in a PDF reader.

**Solution**:
1. Close the PDF file in Adobe/Edge/Chrome/etc.
2. Run the script again
3. Or set `create_pdf <- FALSE` to skip PDF

### Problem: Script runs but maps are missing

**Cause**: OSM data fetch might have failed.

**Solution**:
1. Check your internet connection
2. Look for error messages about "OSM" or "waterways"
3. Try running again (sometimes servers are busy)
4. As last resort: `skip_osm_overlays <- TRUE` (no roads/waterways)

### Problem: "Package installation failed"

**Cause**: Package installation was interrupted or failed.

**Solution**:
1. Try running the script again (it will retry installation)
2. Manually install problematic package:
   ```r
   install.packages("PACKAGE_NAME")
   ```
3. Check your internet connection

### Problem: Script is very slow

**Causes**: First run, large project, slow internet.

**Solutions**:
- **First run**: Be patient! 15-30 minutes is normal
- **Subsequent runs**: Make sure `fresh_run <- FALSE`
- **Testing**: Use `n_photos <- 10` for quick tests
- **Large project**: Increase `n_photos` gradually (25, 50, 100)

### Problem: Maps show wrong area

**Cause**: HQ coordinates might be wrong or need more buffer.

**Solution**:
1. Verify your `hq_lon` and `hq_lat` coordinates
2. Increase `buffer_km` to show more area
3. Set `force_rebuild_base_map <- TRUE` and run again

### Problem: Same photos every time

**Cause**: Random seed might be set to a fixed number.

**Solution**:
```r
use_random_seed <- TRUE
random_seed <- NULL    # Make sure this is NULL, not a number
```

---

## Tips and Best Practices

### For Daily Event Displays

1. **First day**: Run with `fresh_run <- TRUE` to set up everything
2. **Each day after**: Run with `fresh_run <- FALSE` for quick updates
3. **Settings**:
   ```r
   n_photos <- 50
   auto_advance_ms <- 5000
   slideshow_loop <- TRUE
   use_incremental_fetch <- TRUE
   ```
4. Open `slideshow.html` in fullscreen (press 'F') on display screen
5. Let it run - will loop automatically!

### For Presentations

1. **Settings**:
   ```r
   n_photos <- 25
   auto_advance_ms <- 7000
   auto_slide_stoppable <- TRUE
   slideshow_loop <- FALSE
   create_pdf <- TRUE
   ```
2. Open `slideshow.html` in Chrome
3. Press 'F' for fullscreen
4. Press Space or Arrow keys to manually control
5. Press 'S' for speaker view (shows next slide)

### Optimizing Performance

1. **Keep cache files**: Don't delete `.rds` files between runs
2. **Use incremental fetch**: `use_incremental_fetch <- TRUE`
3. **Don't rebuild unnecessarily**: Keep `fresh_run <- FALSE` after first run
4. **Start small**: Test with 10-25 photos before making large slideshows
5. **Monitor first run**: Watch for errors in package installation

### Creating Multiple Versions

Want different slideshows from the same project?

1. **Change `out_dir`**:
   ```r
   out_dir <- "outputs/slideshow_plants_only"
   ```
2. **Run with different settings** (e.g., `max_plants_pct <- 0.90`)
3. **Each version gets its own folder** with separate outputs

### Reproducing a Specific Slideshow

If you created a slideshow you really like:

1. **Find the random seed** in the console output:
   ```
   Random seed: 602053374
   ```
2. **Set it in the configuration**:
   ```r
   random_seed <- 602053374
   ```
3. **Run again** - you'll get the exact same selection!

### Customizing the Slideshow

Advanced users can edit `slideshow.qmd` after it's generated to:
- Change titles or text
- Adjust slide order
- Add custom slides
- Modify styling

Then re-render with Quarto (Tools → Render Document).

### Sharing Your Slideshow

**HTML version** (best for most uses):
- Share the entire output folder
- Or put it on a website
- Anyone can open `slideshow.html` in a browser

**PDF version**:
- Single file, easy to email
- Good for archiving
- Can print if needed

**For websites**:
- Upload the entire output folder
- Link to `slideshow.html`
- Works on any web hosting

---

## Getting Help

### Console Output

The Console (bottom-left pane) shows detailed progress. Look for:

- **=== SECTION NAMES ===** - Shows what step is running
- **Numbers and statistics** - E.g., "Fetched 5295 observations"
- **Red text** - Errors that need attention
- **"WARNING:"** - Problems that might need fixing

### Common Patterns

**Script stops early?**
- Scroll up in Console to find the red error text
- The error usually explains what went wrong

**Script seems frozen?**
- Check if RStudio shows [BUSY] in the console
- If busy, be patient - it's working!
- If truly frozen (minutes without any output), press ESC to stop

### Documentation References

- **iNaturalist**: https://www.inaturalist.org/pages/help
- **R Documentation**: https://www.r-project.org/help.html
- **RStudio Help**: Help → RStudio Docs
- **Quarto**: https://quarto.org/docs/guide/

---

## Appendix: Quick Reference

### Configuration Quick Checklist

Must configure for first run:
- [ ] `project_slug` - Your iNaturalist project ID
- [ ] `hq_lon` - Headquarters longitude
- [ ] `hq_lat` - Headquarters latitude
- [ ] `bioblitz_logo` - Your logo filename (optional)

Often adjusted:
- [ ] `n_photos` - Number of slides (25-100)
- [ ] `fresh_run` - TRUE first time, FALSE after
- [ ] `auto_advance_ms` - Seconds per slide

### Common Setting Combinations

**First time setup:**
```r
project_slug <- "your-project-name-here"
n_photos <- 25
fresh_run <- TRUE
fetch_all_observations <- TRUE
cache_observations <- TRUE
use_incremental_fetch <- TRUE
```

**Daily updates (fast):**
```r
fresh_run <- FALSE
use_incremental_fetch <- TRUE
# Everything else stays the same
```

**Testing/development:**
```r
n_photos <- 10
fresh_run <- FALSE
create_pdf <- FALSE
diagnostic_mode <- TRUE
```

**Event display (looping):**
```r
n_photos <- 50
auto_advance_ms <- 5000
slideshow_loop <- TRUE
fresh_run <- FALSE
```

**Large slideshow:**
```r
n_photos <- 100
max_obs_per_observer_abs <- 5
create_pdf <- FALSE
fresh_run <- FALSE
```

---

## Version History

**Version 1.0 (October 2025)**
- Initial release
- iNaturalist API integration
- Satellite base maps with OSM overlays
- Smart diversity sampling
- Incremental caching
- Multiple output formats (HTML, QMD, PDF)
- Comprehensive configuration options

---

## Credits

This script was developed for the Walpole Wilderness Bioblitz 2025 and is designed to work with any iNaturalist project.

**Technologies used:**
- R and RStudio
- Quarto for slideshow generation
- Reveal.js for HTML presentations
- Esri satellite imagery
- OpenStreetMap data
- iNaturalist API

---

**Happy Slideshow Creating! 🦋🌿🦎**

If you create something cool with this script, consider sharing it back with the iNaturalist community!
