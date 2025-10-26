# 🌿🔍 iNaturalist Bioblitz Slideshow Generator

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

## 🎯 What It Does

The script connects to iNaturalist's API to:

1. Download observation data from your specified bioblitz project
2. Randomly select observations with diversity controls (prevents one observer from dominating, balances plant vs. animal ratio)
3. Download high-quality photos of each selected observation
4. Generate custom maps showing observation locations, your bioblitz HQ, roads, and waterways
5. Create professional slideshow presentations organized by iconic taxon groups (Plants, Insects, Birds, etc.)
6. Output in multiple formats perfect for event displays or presentations

**New in Version 2.0:**
- Fast map providers for large area bioblitzes (10-20x faster)
- Fully generalizable to any bioblitz project worldwide
- Configurable bioblitz name and year on slides
- Automatic high-resolution photo downloading

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

*First-time setup may take 10-15 minutes while packages install.*

## 🚀 Quick Start

### 1. Installation

Clone or download this repository:

```bash
git clone https://github.com/yourusername/inaturalist-bioblitz-slideshow.git
cd inaturalist-bioblitz-slideshow
```

### 2. Configure Your Bioblitz

Open `iNaturalist_Bioblitz_Slideshow_Generator.R` in RStudio and edit the configuration section:

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

### 3. Run the Script

In RStudio:
1. Open the R script file
2. Click **Source** (top right of the script pane), or press `Ctrl+Shift+S` (Windows/Linux) or `Cmd+Shift+S` (Mac)
3. Wait for the script to complete (progress messages will appear in the Console)
4. Find your slideshow in the `outputs/slideshow/` folder

### 4. View Your Slideshow

Open `outputs/slideshow/slideshow.html` in your web browser:
- Press `F` for fullscreen
- Press `Space` or arrow keys to navigate
- Press `ESC` to exit fullscreen

## 📖 Documentation

For detailed instructions, configuration options, and troubleshooting, see:

- **[📘 Complete User Guide](Bioblitz_photo_show_user_guide.md)** - Comprehensive documentation covering:
  - Step-by-step setup instructions
  - All configuration options explained
  - Map customization and performance optimization
  - Troubleshooting common issues
  - Tips for daily event displays and presentations

## 🎛️ Key Configuration Options

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

### Performance Optimization
For large bioblitz areas, use these settings for 10-20x faster generation:

```r
map_provider <- "OpenStreetMap"     # Fast map provider
skip_osm_overlays <- TRUE           # Skip road/waterway overlays
base_map_zoom <- 12                 # Lower zoom level
buffer_km <- 2.5                    # Smaller area
force_rebuild_base_map <- FALSE     # After first run
```

## 💡 Common Use Cases

### Daily Event Display
```r
# First day
fresh_run <- TRUE
n_photos <- 50
slideshow_loop <- TRUE
auto_advance_ms <- 5000

# Following days (fast updates)
fresh_run <- FALSE
use_incremental_fetch <- TRUE  # Only fetch new observations
```

### One-Time Presentation
```r
n_photos <- 25
fresh_run <- TRUE
create_pdf <- TRUE
slideshow_loop <- FALSE
auto_advance_ms <- 7000
```

### Large Slideshow (100+ photos)
```r
n_photos <- 100
max_obs_per_observer_abs <- 5
create_pdf <- FALSE  # PDFs of large slideshows can be huge
fresh_run <- FALSE   # Use cached data
```

## 📊 Output Files

The script creates the following files in `outputs/slideshow/`:

- `slideshow.html` - Interactive HTML presentation (main output)
- `slideshow.qmd` - Quarto source file (editable)
- `slideshow.pdf` - PDF version (if enabled)
- `slides/` - Individual slide images
- `maps/` - Generated location maps
- `photos/` - Downloaded observation photos
- Cache files (`.rds`) - For faster reruns

## 🛠️ Troubleshooting

### Common Issues

**"Cannot connect to iNaturalist"**
- Check your internet connection
- Verify your `project_slug` is correct
- Check iNaturalist API status

**"No observations found"**
- Verify your project has observations
- Check date filters if using them
- Ensure `fetch_all_observations <- TRUE` for first run

**Script is slow**
- For large bioblitzes, use `map_provider <- "OpenStreetMap"`
- Set `skip_osm_overlays <- TRUE`
- Reduce `base_map_zoom` to 12 or 13
- See [Performance Optimization](Bioblitz_photo_show_user_guide.md#optimizing-performance) in the user guide

**Package installation fails**
- Update R and RStudio to latest versions
- Try installing packages manually: `install.packages("package_name")`
- Check the Console for specific error messages

For more help, see the [Troubleshooting section](Bioblitz_photo_show_user_guide.md#troubleshooting) in the complete user guide.

## 📁 Repository Structure

```
.
├── iNaturalist_Bioblitz_Slideshow_Generator.R  # Main script
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

## 🌟 Examples

This script was originally developed for the **Walpole Wilderness Bioblitz 2025** and has been generalized to work with any iNaturalist bioblitz project worldwide.

Share your slideshows with the iNaturalist community and help celebrate biodiversity discoveries! 🦋🌿🦎

## 🤝 Contributing

Contributions are welcome! If you've made improvements or have suggestions:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

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

## 👥 Authors

**Olly Berry** and **Claude**

## 🙏 Acknowledgements

- Thanks to all organizers and participants in the **Walpole Wilderness Bioblitzes**
- [iNaturalist](https://www.inaturalist.org/) for providing the API and platform
- The R community for excellent mapping and data processing packages
- [Quarto](https://quarto.org/) and [Reveal.js](https://revealjs.com/) for slideshow capabilities
- Map data providers: Esri, OpenStreetMap, CartoDB

## 📞 Support

- **Documentation**: See [Bioblitz_photo_show_user_guide.md](Bioblitz_photo_show_user_guide.md)
- **Issues**: Open an issue on GitHub
- **Questions**: Contact through GitHub discussions

## 🔗 Related Resources

- [iNaturalist Help](https://www.inaturalist.org/pages/help)
- [R Documentation](https://www.r-project.org/help.html)
- [RStudio Documentation](https://support.posit.co/hc/en-us)
- [Quarto Documentation](https://quarto.org/docs/guide/)

---

**Happy Slideshow Creating!** 🦋🌿🦎

*If you create something cool with this script, please consider sharing it back with the iNaturalist community!*
