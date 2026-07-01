# ==============================================================================
# iNaturalist Bioblitz Photo Slideshow Generator - Shiny App (V4)
# ==============================================================================
#
# PURPOSE:
#   A graphical front-end for Walpole_Bioblitz_Photo_Slideshow_Script_V4.R.
#   Point it at the slideshow script, set your project details, and generate a
#   polished reveal.js HTML slideshow - without editing the script by hand.
#
# USAGE:
#   1. Open this file in RStudio and click "Run App".
#   2. In the Configuration tab, browse for the slideshow script (V4) and set
#      your project details and output folder.
#   3. Click "Generate slideshow" in the Run & progress tab.
#   4. When it finishes, the app switches to the Outputs tab automatically.
#
# WHAT CHANGED FOR V4:
#   - V4 of the slideshow script begins with source("bioblitz_style.R"), a
#     shared palette / PhyloPic-icon helper that lives BESIDE the script. This
#     app now runs the script from its own folder so that relative source()
#     resolves, sources the style file into the same environment that holds the
#     app's locked settings (so force_rebuild_icons is visible to it), and warns
#     you up-front if bioblitz_style.R is not found next to the script.
#   - Added two new controls the V4 script understands:
#       * Map edge padding (map_pad_m)
#       * Rebuild taxon icons (force_rebuild_icons)
#   - Re-themed with a Wes Anderson "Zissou1" palette for a calmer, more
#     harmonious look.
# ==============================================================================

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinyFiles)

# ------------------------------------------------------------------------------
# Wes Anderson "Zissou1" palette (wesanderson::wes_palette("Zissou1"))
# Used both as R values (for any server-side styling) and, below, as the CSS
# design tokens that drive the whole dashboard theme.
# ------------------------------------------------------------------------------
zissou <- list(
  blue      = "#3B9AB2",  # deep sea blue  (primary)
  teal      = "#78B7C5",  # shallow water  (info)
  sand      = "#EBCC2A",  # sunlit yellow
  gold      = "#E1AF00",  # brass          (accent / generate)
  red       = "#F21A00"   # signal red     (danger / stop)
)

# ==============================================================================
# THEME  (Zissou1 applied to the AdminLTE / shinydashboard skeleton)
# ==============================================================================
zissou_css <- HTML("
  @import url('https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600;9..144,700&family=Inter:wght@400;500;600;700&display=swap');

  :root {
    --z-blue:#3B9AB2; --z-teal:#78B7C5; --z-sand:#EBCC2A; --z-gold:#E1AF00; --z-red:#F21A00;
    --z-navy:#12343B;         /* header / deep teal-navy */
    --z-navy-2:#0C2429;       /* sidebar */
    --z-navy-3:#183F48;       /* sidebar hover */
    --z-ink:#173A42;          /* body text */
    --z-parchment:#F3EEE3;    /* page background (warm) */
    --z-card:#FFFFFF;
    --z-border:#E3DAC7;
    --z-muted:#7C7460;
    --display:'Fraunces', Georgia, serif;
    --body:'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  }

  /* ---- base ---- */
  body, .content-wrapper, .right-side { background-color: var(--z-parchment) !important;
    font-family: var(--body); color: var(--z-ink); }
  .content-wrapper { padding-top: 6px; }
  h1,h2,h3,h4,h5, .box-title { font-family: var(--body); }

  /* ---- header ---- */
  .skin-blue .main-header .logo,
  .skin-blue .main-header .navbar { background: var(--z-navy) !important; }
  .skin-blue .main-header .logo { border-bottom: 3px solid var(--z-gold);
    font-family: var(--display); }
  .skin-blue .main-header .logo:hover { background: var(--z-navy) !important; }
  .skin-blue .main-header .navbar { border-bottom: 3px solid var(--z-gold); }
  .skin-blue .main-header .navbar .sidebar-toggle:hover { background: var(--z-navy-3) !important; }
  .main-header .logo .brand-main { font-family: var(--display); font-weight: 600; }

  /* ---- sidebar ---- */
  .skin-blue .main-sidebar { background-color: var(--z-navy-2) !important; }
  .skin-blue .sidebar-menu > li > a { color: #CFE3E8; border-left: 3px solid transparent; }
  .skin-blue .sidebar-menu > li:hover > a,
  .skin-blue .sidebar-menu > li.active > a {
    background: var(--z-navy-3) !important; color: #FFFFFF !important;
    border-left-color: var(--z-gold) !important; }
  .skin-blue .sidebar-menu > li > a > .fa { color: var(--z-sand); }

  /* ---- boxes ---- */
  .box { border-radius: 12px !important; border-top: none;
    box-shadow: 0 2px 10px rgba(18,52,59,.08) !important; background: var(--z-card);
    margin-bottom: 22px; }
  .box.box-solid > .box-header { border-radius: 12px 12px 0 0; }
  .box > .box-header { border-radius: 12px 12px 0 0; }
  .box-header .box-title { font-weight: 600; letter-spacing: .2px; }

  /* status header colours mapped to Zissou tones (white title text) */
  .box.box-solid.box-primary > .box-header,
  .box.box-primary { border-top-color: var(--z-blue); }
  .box.box-solid.box-primary > .box-header { background: var(--z-blue); }

  .box.box-solid.box-info > .box-header { background: #4E94A6; }        /* deepened teal for contrast */
  .box.box-info { border-top-color: var(--z-teal); }

  .box.box-solid.box-warning > .box-header { background: var(--z-gold); color:#3A2E00; }
  .box.box-solid.box-warning > .box-header .box-title { color:#3A2E00; }
  .box.box-warning { border-top-color: var(--z-gold); }

  .box.box-solid.box-danger > .box-header { background: var(--z-red); }
  .box.box-danger { border-top-color: var(--z-red); }

  .box.box-solid.box-success > .box-header { background: #2E8B7F; }     /* harmonising teal-green */
  .box.box-success { border-top-color: #2E8B7F; }

  /* ---- buttons ---- */
  .btn { border-radius: 8px !important; font-weight: 600; border: none;
    transition: transform .05s ease, box-shadow .15s ease; }
  .btn:active { transform: translateY(1px); }
  .btn-success { background: linear-gradient(180deg, var(--z-sand), var(--z-gold)) !important;
    color:#3A2E00 !important; box-shadow: 0 2px 6px rgba(225,175,0,.35); }
  .btn-success:hover { color:#3A2E00 !important; box-shadow: 0 4px 12px rgba(225,175,0,.5); }
  .btn-primary { background: var(--z-blue) !important; color:#fff !important; }
  .btn-primary:hover { background:#337F94 !important; }
  .btn-info { background: var(--z-teal) !important; color:#0C2429 !important; }
  .btn-info:hover { background:#67a7b6 !important; color:#0C2429 !important; }
  .btn-danger { background: var(--z-red) !important; color:#fff !important; }
  .btn-danger:hover { background:#c81600 !important; }
  .btn-warning { background: var(--z-gold) !important; color:#3A2E00 !important; }
  .btn-default { background: var(--z-card) !important; color: var(--z-ink) !important;
    border: 1px solid var(--z-border) !important; }
  .btn-default:hover { background:#FBF8F1 !important; border-color:#CBBFA3; }

  /* ---- inputs ---- */
  .form-control { border-radius: 8px; border:1px solid var(--z-border); }
  .form-control:focus { border-color: var(--z-blue); box-shadow: 0 0 0 2px rgba(59,154,178,.18); }
  .irs-bar, .irs-bar-edge, .irs-single, .irs-from, .irs-to { background: var(--z-blue) !important;
    border-color: var(--z-blue) !important; }
  .irs-single, .irs-from, .irs-to { color:#fff; }

  /* ---- helper + banner styles ---- */
  .help-text { color: var(--z-muted); font-size: .88em; margin-top: 5px; }
  .required-label:after { content:' *'; color: var(--z-red); }
  .advanced-explain {
    background:#FBF6E7; border-left:4px solid var(--z-gold); padding:8px 12px;
    margin:6px 0 10px 0; font-size:.86em; color:#5b5340; border-radius:0 6px 6px 0; }

  .zissou-banner {
    background: linear-gradient(120deg, var(--z-navy) 0%, var(--z-blue) 62%, #4E94A6 100%);
    color:#F3EEE3; border-radius:12px; padding:18px 22px;
    box-shadow:0 3px 14px rgba(18,52,59,.18); position:relative; overflow:hidden; }
  .zissou-banner h2 { font-family: var(--display); font-weight:600; margin:0 0 4px 0;
    font-size:1.5rem; letter-spacing:.3px; }
  .zissou-banner p { margin:0; opacity:.94; font-size:1.02em; max-width:70ch; }
  .zissou-swatch { position:absolute; top:0; right:0; height:100%; display:flex; }
  .zissou-swatch span { width:14px; height:100%; display:block; }

  /* ---- path display chips ---- */
  .path-display { background:#FBF8F1; border:1px solid var(--z-border); border-radius:8px;
    padding:7px 11px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size:.84em; word-break:break-all; min-height:34px; color:#3f3a2d; margin-top:4px; }
  .path-display.not-set { color:#a79f8b; font-style:italic; }

  /* ---- info boxes ---- */
  .info-box { min-height:96px !important; border-radius:12px !important;
    box-shadow:0 2px 10px rgba(18,52,59,.08) !important; background: var(--z-card); }
  .info-box-icon { display:none !important; }
  .info-box-content { margin-left:14px !important; padding:14px 10px !important; }
  .info-box-text { font-weight:600 !important; font-size:15px !important;
    letter-spacing:.3px !important; color: var(--z-ink) !important; text-transform:none; }
  .info-box-number { font-family: var(--display); font-weight:700 !important;
    font-size:40px !important; color: var(--z-blue) !important; margin-top:6px !important; }

  /* progress stage list + verbatim log */
  .stage-done  { color:#2E8B7F; }
  .stage-todo  { color:#a79f8b; }
  pre { background:#0C2429; color:#CFE3E8; border:none; border-radius:10px; }
  .seed-card { margin:12px 0; padding:12px 16px; background:#EAF3F5;
    border-left:4px solid var(--z-blue); border-radius:8px; }
  hr { border-top:1px solid var(--z-border); }
")

# ==============================================================================
# USER INTERFACE
# ==============================================================================

ui <- dashboardPage(
  skin = "blue",

  dashboardHeader(
    title = tags$div(
      tags$span(class = "brand-main", "Bioblitz Slideshow",
                style = "font-size:16px; font-weight:600; display:block; line-height:1.25;"),
      tags$span("iNaturalist photo presenter",
                style = "font-size:11px; opacity:.85; display:block;")
    ),
    titleWidth = 280
  ),

  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "sidebar",
      menuItem("Configuration",  tabName = "config",  icon = icon("cog")),
      menuItem("Run & progress",  tabName = "run",     icon = icon("play")),
      menuItem("Outputs",         tabName = "outputs", icon = icon("file-image")),
      menuItem("Help",            tabName = "help",    icon = icon("question-circle"))
    )
  ),

  dashboardBody(
    tags$head(tags$style(zissou_css)),

    tabItems(

      # ======================================================================
      # CONFIGURATION TAB
      # ======================================================================
      tabItem(tabName = "config",

        # -- Banner --
        fluidRow(column(12,
          div(class = "zissou-banner",
            div(class = "zissou-swatch",
                tags$span(style="background:#3B9AB2"),
                tags$span(style="background:#78B7C5"),
                tags$span(style="background:#EBCC2A"),
                tags$span(style="background:#E1AF00"),
                tags$span(style="background:#F21A00")),
            tags$h2(icon("leaf"), " Bioblitz photo slideshow generator"),
            tags$p("Set up your project below, then head to Run & progress to build a ",
                   "reveal.js slideshow from your iNaturalist observations. Each slide pairs a ",
                   "species photo with a satellite location map.")
          ),
          br()
        )),

        fluidRow(
          # -- Script selection --
          box(
            title = "Slideshow script", status = "danger", solidHeader = TRUE, width = 12,
            p(strong("Point the app at the V4 slideshow script."),
              " Browse to select it, or type the path directly."),
            fluidRow(
              column(9, div(class = "path-display", uiOutput("script_path_display_ui"))),
              column(3, br(),
                shinyFilesButton("script_file_btn", label = "Browse...",
                  title = "Select the bioblitz photo slideshow R script",
                  multiple = FALSE, icon = icon("folder-open"),
                  class = "btn-default btn-block"))
            ),
            div(class = "help-text",
                "Select the R script (e.g. Walpole_Bioblitz_Photo_Slideshow_Script_V4.R)."),
            uiOutput("script_status_ui"),
            uiOutput("style_status_ui")   # V4: checks bioblitz_style.R sits beside the script
          )
        ),

        fluidRow(
          # -- Project settings --
          box(
            title = "Project settings", status = "primary", solidHeader = TRUE, width = 6,
            textInput("project_slug",
              tags$span(class = "required-label", "iNaturalist project slug"),
              value = "walpole-wilderness-bioblitz-2025", placeholder = "e.g. my-bioblitz-2025"),
            div(class = "help-text",
                "From your project URL: inaturalist.org/projects/YOUR-SLUG"),
            textInput("bioblitz_name",
              tags$span(class = "required-label", "Bioblitz name"),
              value = "Walpole Wilderness Bioblitz", placeholder = "e.g. My Town Bioblitz"),
            div(class = "help-text",
                "Shown on the welcome slide. The year is appended automatically, ",
                "e.g. \"Walpole Wilderness Bioblitz 2025\"."),
            numericInput("n_photos", "Number of photos in slideshow",
              value = 50, min = 1, max = 1000, step = 1),
            div(class = "help-text", "How many observations to include (chosen at random)."),
            fileInput("bioblitz_logo", "Upload bioblitz logo (optional)",
              accept = c("image/png", "image/jpeg", "image/jpg")),
            div(class = "help-text",
                "Appears top-right on the welcome slide. JPG or PNG.")
          ),

          # -- Date display --
          box(
            title = "Observation date display", status = "primary", solidHeader = TRUE, width = 6,
            checkboxInput("bioblitz_dates_auto",
              "Derive the date range automatically from observations", value = TRUE),
            div(class = "help-text", style = "margin-bottom:12px;",
                HTML("<b>Recommended.</b> The earliest and latest observation dates are read ",
                "from the fetched data and shown on the welcome slide, e.g. ",
                "<em>\"Observations recorded 4-5 October 2025\"</em>.<br><br>",
                "Turn this off if the project has outlier records (e.g. historical ",
                "observations added later) that would skew the range.")),
            conditionalPanel("input.bioblitz_dates_auto == false",
              dateInput("bioblitz_date_start", "Start date", value = Sys.Date()),
              dateInput("bioblitz_date_end",   "End date",   value = Sys.Date()),
              div(class = "help-text",
                  "These dates will be shown on the welcome slide instead of the derived range."))
          )
        ),

        fluidRow(
          # -- Output directory --
          box(
            title = "Output folder", status = "primary", solidHeader = TRUE, width = 6,
            p("Where all slideshow files are saved."),
            fluidRow(
              column(9, div(class = "path-display", uiOutput("out_dir_display_ui"))),
              column(3, br(),
                shinyDirButton("out_dir_btn", label = "Browse...",
                  title = "Select output folder", icon = icon("folder-open"),
                  class = "btn-default btn-block"))
            ),
            div(class = "help-text",
                "Photos, maps, slides and the final slideshow.html all land here. ",
                "Created if it does not exist.")
          ),

          # -- Location / map settings --
          box(
            title = "Location & maps", status = "primary", solidHeader = TRUE, width = 6,
            numericInput("hq_lat", tags$span(class = "required-label", "Headquarters latitude"),
              value = -34.992854, step = 0.000001),
            div(class = "help-text", "Decimal degrees, e.g. -34.992854"),
            numericInput("hq_lon", tags$span(class = "required-label", "Headquarters longitude"),
              value = 116.634398, step = 0.000001),
            div(class = "help-text", "Decimal degrees, e.g. 116.634398"),
            numericInput("base_map_zoom", "Base map zoom level",
              value = 14, min = 10, max = 18, step = 1),
            div(class = "help-text", "13-15 recommended. Higher = more detail but slower."),
            numericInput("default_dist_m", "Closest map radius (metres)",
              value = 4000, min = 500, max = 10000, step = 500),
            div(class = "help-text",
                "The most zoomed-in level (window half-width). Distant observations zoom out from here."),
            numericInput("map_zoom_n", "Number of map zoom levels",
              value = 4, min = 1, max = 10, step = 1),
            div(class = "help-text",
                "Discrete zoom steps. Each map snaps to the smallest level that frames both HQ and the observation."),
            numericInput("map_pad_m", "Map edge padding (metres)",
              value = 1000, min = 0, max = 5000, step = 250),
            div(class = "help-text",
                "Margin kept between HQ / the observation and the window edge, so neither sits hard against the border."),
            numericInput("map_margin_frac", "Map edge margin (fraction)",
              value = 0.20, min = 0, max = 0.4, step = 0.05),
            div(class = "help-text",
                "Keeps HQ and the observation inside the inner part of each map. Higher = more margin, slightly more zoomed out.")
          )
        ),

        fluidRow(
          # -- Diversity --
          box(
            title = "Selection diversity", status = "info", solidHeader = TRUE, width = 6,
            sliderInput("max_obs_per_observer_pct", "Max % of photos from one observer",
              value = 15, min = 5, max = 100, step = 5, post = "%"),
            div(class = "help-text", "Spreads the slideshow across many observers."),
            numericInput("max_obs_per_observer_abs", "Absolute max photos per observer",
              value = 5, min = 1, max = 50, step = 1),
            div(class = "help-text", "Hard cap - overrides the percentage if lower."),
            sliderInput("max_plants_pct", "Max % plant photos",
              value = 40, min = 0, max = 100, step = 5, post = "%"),
            div(class = "help-text", "Keeps the mix taxonomically varied rather than plant-heavy.")
          ),

          # -- Slideshow playback --
          box(
            title = "Slideshow playback", status = "info", solidHeader = TRUE, width = 6,
            numericInput("auto_advance_ms", "Auto-advance time (seconds)",
              value = 7, min = 1, max = 60, step = 1),
            div(class = "help-text", "How long each slide shows before advancing."),
            checkboxInput("auto_slide_stoppable", "Let the viewer pause auto-advance", value = TRUE),
            checkboxInput("slideshow_loop",       "Loop back to the start at the end", value = TRUE),
            numericInput("max_collage", "Max photos in the final collage",
              value = 25, min = 5, max = 100, step = 5),
            div(class = "help-text", "The closing slide is a collage of random photos.")
          )
        ),

        fluidRow(
          # -- Run mode --
          box(
            title = "Run mode & performance", status = "warning", solidHeader = TRUE, width = 6,
            checkboxInput("fresh_run", "Fresh run (delete old artefacts)", value = FALSE),
            div(class = "help-text",
                HTML("<b>On:</b> deletes previous photos, maps and slides and re-downloads ",
                "everything. Use for a brand-new slideshow or when the observation pool changed a lot.<br><br>",
                "<b>Off (incremental):</b> keeps cached data and only processes what changed - ",
                "much faster for repeat runs.")),
            checkboxInput("fetch_all_observations", "Fetch all observations", value = TRUE),
            div(class = "help-text", "Uncheck to fetch a subset - handy for quick tests."),
            checkboxInput("cache_observations", "Cache observations", value = TRUE),
            div(class = "help-text", "Saves fetched data to disk for faster reruns."),
            checkboxInput("use_incremental_fetch", "Fetch only new observations", value = TRUE),
            div(class = "help-text",
                "Only pulls observations added since the last run. Applies when Fresh run is off.")
          ),

          # -- Advanced rebuild options --
          box(
            title = "Advanced rebuild options", status = "warning", solidHeader = TRUE, width = 6,
            checkboxInput("force_rebuild_base_map", "Rebuild satellite base map", value = FALSE),
            div(class = "advanced-explain",
                HTML("Re-downloads the satellite tiles and rebuilds the cached base map. ",
                "Check it on the first run, if the survey area changed, or if the base map looks wrong. ",
                "Leaving it off saves 30-120s per run.")),
            checkboxInput("force_rebuild_maps", "Rebuild all observation maps", value = TRUE),
            div(class = "advanced-explain",
                HTML("Re-renders every individual map image. Check after changing HQ, zoom or map ",
                "styling. Leave off to reuse correct maps and save minutes.")),
            checkboxInput("force_rebuild_slides", "Rebuild all slide compositions", value = FALSE),
            div(class = "advanced-explain",
                HTML("Re-composites every slide (photo + map + captions). Check after changing slide ",
                "layout or captions.")),
            checkboxInput("force_rebuild_collage", "Rebuild the closing collage", value = TRUE),
            div(class = "advanced-explain",
                HTML("Regenerates the polaroid collage from the current photo selection.")),
            checkboxInput("force_rebuild_icons", "Rebuild taxon icons", value = FALSE),
            div(class = "advanced-explain",
                HTML("Re-fetches and recolours the PhyloPic taxon silhouettes used on slides. ",
                "The first run fetches them regardless; only check this after a palette change ",
                "or to refresh the icon cache.")),
            checkboxInput("skip_osm_overlays", "Skip OpenStreetMap overlays (faster)", value = FALSE),
            div(class = "advanced-explain",
                HTML("Omits road and waterway lines. Check when the OSM API is slow, the area is ",
                "remote, or you want faster test runs."))
          )
        ),

        fluidRow(
          # -- PDF --
          box(
            title = "PDF output", status = "success", solidHeader = TRUE, width = 6,
            checkboxInput("create_pdf", "Also create a PDF version", value = FALSE),
            div(class = "help-text", "Needs Chrome/Chromium. Can be slow for large slideshows."),
            numericInput("pdf_size_limit_mb", "PDF size limit (MB, 0 = no limit)",
              value = 50, min = 0, max = 500, step = 10),
            div(class = "help-text", "Skip the PDF if the estimate exceeds this.")
          ),

          # -- Seed --
          box(
            title = "Reproducibility (random seed)", status = "success", solidHeader = TRUE, width = 6,
            checkboxInput("use_random_seed", "Random selection each run", value = TRUE),
            div(class = "help-text", "Different photos every run. Uncheck to use R's current state."),
            numericInput("random_seed", "Specific seed (optional)",
              value = NA, min = 1, max = 999999),
            div(class = "help-text",
                "Set a number to reproduce the exact same slideshow. Leave blank for random.")
          )
        ),

        fluidRow(
          box(width = 12, solidHeader = TRUE, status = "primary",
            actionButton("save_config", "Save configuration", icon = icon("save"),
                         class = "btn-primary btn-lg", width = "220px"),
            actionButton("load_config", "Load configuration", icon = icon("upload"),
                         class = "btn-default btn-lg", width = "220px"),
            div(class = "help-text", style = "margin-top:10px;",
                "Saved as bioblitz_config.rds for reuse.")
          )
        )
      ),

      # ======================================================================
      # RUN & PROGRESS TAB
      # ======================================================================
      tabItem(tabName = "run",
        fluidRow(
          box(
            title = "Quick presets", status = "primary", solidHeader = TRUE, width = 12,
            p(class = "help-text", style = "margin-bottom:12px;",
              "Presets set all the rebuild switches for you. Pick one, then press Generate slideshow."),
            fluidRow(
              column(2, actionButton("preset_html_only", "Regenerate HTML",
                class = "btn-primary btn-block",
                title = "Same observations and seed - just rewrite slideshow.html. Fastest.")),
              column(2, actionButton("preset_new_collage", "New collage only",
                class = "btn-primary btn-block",
                title = "Rebuild the collage, reuse existing slides.")),
              column(2, actionButton("preset_quick_test", "Quick test (3 slides)",
                class = "btn-warning btn-block",
                title = "Fetch 3 photos and build fresh. Good for checking settings.")),
              column(2, actionButton("preset_update", "Update new obs",
                class = "btn-info btn-block",
                title = "Incrementally fetch and process only new observations.")),
              column(2, actionButton("preset_full_rebuild", "Full rebuild",
                class = "btn-danger btn-block",
                title = "Rebuild base map, maps, slides, collage and HTML from cached photos.")),
              column(2, actionButton("preset_fresh_run", "Fresh run",
                class = "btn-danger btn-block",
                title = "Delete all cached files and start completely fresh."))
            ),
            tags$style(".btn-block{width:100%; margin-bottom:6px; white-space:normal;
                        min-height:54px; font-size:.85rem;}")
          )
        ),

        fluidRow(
          box(
            title = "Generate slideshow", status = "success", solidHeader = TRUE, width = 12,
            actionButton("run_script", "Generate slideshow", icon = icon("play"),
                         class = "btn-success btn-lg", width = "250px"),
            actionButton("stop_script", "Stop", icon = icon("stop"),
                         class = "btn-danger btn-lg", width = "200px"),
            hr(),
            uiOutput("seed_warning_banner"),

            div(class = "seed-card",
              fluidRow(
                column(1, style = "padding-top:6px;",
                  icon("seedling", style = "color:var(--z-blue); font-size:1.4rem;")),
                column(5, checkboxInput("use_random_seed2",
                  "Random selection (new seed each run)", value = TRUE)),
                column(3, numericInput("random_seed2", "Specific seed (blank = random)",
                  value = NA, min = 1, max = .Machine$integer.max, step = 1)),
                column(3, br(),
                  actionButton("use_last_seed", "Use last run seed",
                    class = "btn-default btn-sm", title = "Read the seed from the last run's log"))
              ),
              div(style = "color:#2c6470; font-size:.82rem; margin-top:4px;",
                  "To reuse the same photos, enter your last seed above or click Use last run seed.")
            ),
            hr(),
            h4("Current status"),
            textOutput("status_text"),
            hr(),
            h4("Progress"),
            uiOutput("progress_stages")
          )
        ),

        fluidRow(
          infoBoxOutput("obs_count_box",         width = 3),
          infoBoxOutput("observer_count_box",    width = 3),
          infoBoxOutput("photos_downloaded_box", width = 3),
          infoBoxOutput("maps_created_box",      width = 3)
        ),
        fluidRow(
          infoBoxOutput("slides_created_box",    width = 3)
        ),

        fluidRow(
          box(
            title = "Live progress log", status = "info", solidHeader = TRUE, width = 12,
            collapsible = TRUE,
            verbatimTextOutput("progress_log"),
            hr(),
            actionButton("refresh_counts", "Refresh file counts",
                         icon = icon("sync"), class = "btn-info"),
            div(class = "help-text", style = "margin-top:10px;",
                "Manually refresh the counts if they look stuck.")
          )
        ),

        fluidRow(
          box(
            title = "Debugging information", status = "warning", solidHeader = TRUE, width = 12,
            collapsible = TRUE, collapsed = TRUE,
            verbatimTextOutput("debug_info"),
            p("If progress seems stuck:"),
            tags$ul(
              tags$li("Check the live log above for errors"),
              tags$li("Click Refresh file counts to force an update"),
              tags$li("Open the output folder to see the files actually created"),
              tags$li("The script may still be working even if counts pause")
            )
          )
        )
      ),

      # ======================================================================
      # OUTPUTS TAB
      # ======================================================================
      tabItem(tabName = "outputs",
        fluidRow(
          box(
            title = "Generated files", status = "success", solidHeader = TRUE, width = 12,
            h4("Output location"),
            verbatimTextOutput("output_path"),
            hr(),
            h4("Available files"),
            uiOutput("output_files_ui"),
            hr(),
            actionButton("open_html", "Open slideshow in browser",
                         icon = icon("external-link-alt"),
                         class = "btn-success btn-lg", width = "260px"),
            actionButton("open_folder", "Open output folder",
                         icon = icon("folder-open"),
                         class = "btn-primary btn-lg", width = "240px"),
            div(class = "help-text", style = "margin-top:15px;",
                "slideshow.html opens in any browser - photos, maps and styling are embedded, ",
                "so the file is self-contained.")
          )
        ),
        fluidRow(
          box(
            title = "Housekeeping", status = "warning", solidHeader = TRUE, width = 12,
            collapsible = TRUE, collapsed = TRUE,
            p("Clear cached figures if a layout change is not showing up on a rebuild."),
            actionButton("clear_maps",   "Clear cached maps",   class = "btn-default"),
            actionButton("clear_slides", "Clear cached slides", class = "btn-default"),
            actionButton("clear_collage","Clear cached collage",class = "btn-default"),
            div(class = "help-text", style = "margin-top:10px;",
                "These only remove cached images in the output folder; your observations cache is kept.")
          )
        )
      ),

      # ======================================================================
      # HELP TAB
      # ======================================================================
      tabItem(tabName = "help",
        fluidRow(
          box(
            title = "Quick start", status = "info", solidHeader = TRUE, width = 12,
            h4("1. Configure your project"),
            tags$ul(
              tags$li("Browse for the V4 slideshow R script"),
              tags$li(HTML("Make sure <b>bioblitz_style.R</b> sits in the same folder as the script - ",
                           "V4 loads it for the shared palette and taxon icons")),
              tags$li("Enter your iNaturalist project slug (required)"),
              tags$li("Set the bioblitz name - it appears on the welcome slide"),
              tags$li("Set the number of photos and choose an output folder"),
              tags$li("Optionally upload a logo and adjust location / diversity settings")
            ),
            h4("2. Choose a run mode"),
            tags$ul(
              tags$li(tags$b("First time / full rebuild:"), " use the Fresh run preset"),
              tags$li(tags$b("Repeat runs:"), " leave Fresh run off and keep Fetch only new observations on"),
              tags$li(tags$b("Testing:"), " use the Quick test preset for a fast 3-slide check")
            ),
            h4("3. Generate"),
            p("On Run & progress, click Generate slideshow. The script will fetch observations, ",
              "download photos, build satellite maps, compose slides, and write an interactive HTML slideshow."),
            h4("4. View"),
            p("The app switches to Outputs when it finishes. From there, open the slideshow in your browser ",
              "or open the output folder."),
            hr(),
            h4("About bioblitz_style.R"),
            p("V4 begins with ", tags$code("source(\"bioblitz_style.R\")"), ". This app runs the script ",
              "from its own folder so that relative reference resolves, and it checks the file is present ",
              "before starting. If the check is red, put bioblitz_style.R next to the slideshow script."),
            hr(),
            h4("Required R packages"),
            p("Installed automatically if missing:"),
            tags$code("httr2, jsonlite, dplyr, purrr, tidyr, stringr, lubridate, janitor, glue, readr, ",
                      "tibble, ggplot2, sf, maptiles, terra, tidyterra, osmdata, magick, ggspatial, ",
                      "wesanderson, quarto, pagedown, shinyFiles")
          )
        )
      )
    )
  )
)

# ==============================================================================
# SERVER
# ==============================================================================

server <- function(input, output, session) {

  `%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

  volumes <- tryCatch(
    c("Working Directory" = getwd(), shinyFiles::getVolumes()()),
    error = function(e) c("Working Directory" = getwd(), "Root" = "/")
  )

  rv <- reactiveValues(
    running = FALSE, log = "", status = "Ready",
    obs_count = 0, observer_count = 0,
    photos_downloaded = 0, maps_created = 0, slides_created = 0,
    initial_photos = 0, initial_maps = 0, initial_slides = 0,
    output_dir = NULL, start_time = NULL, pid_file = NULL,
    script_path = NULL, out_dir_path = NULL, preset_needs_seed = FALSE
  )

  # --------------------------------------------------------------------------
  # Script selection + V4 style-file check
  # --------------------------------------------------------------------------
  shinyFileChoose(input, "script_file_btn", roots = volumes, session = session,
                  filetypes = c("R", "r"))

  observe({
    if (!is.integer(input$script_file_btn) && !is.null(input$script_file_btn)) {
      parsed <- parseFilePaths(volumes, input$script_file_btn)
      if (nrow(parsed) > 0) rv$script_path <- as.character(parsed$datapath[1])
    }
  })

  output$script_path_display_ui <- renderUI({
    if (is.null(rv$script_path))
      span(class = "not-set", "No script selected - click Browse to choose.")
    else span(rv$script_path)
  })

  output$script_status_ui <- renderUI({
    path <- rv$script_path
    if (is.null(path) || !file.exists(path)) {
      div(style = "color:var(--z-red); font-weight:600; margin-top:8px;",
          icon("exclamation-triangle"),
          if (is.null(path)) " No script selected yet."
          else paste0(" Script not found: ", path))
    } else {
      div(style = "color:#2E8B7F; font-weight:600; margin-top:8px;",
          icon("check-circle"), " Script found: ", basename(path))
    }
  })

  # V4 needs bioblitz_style.R beside the script
  style_ok <- reactive({
    p <- rv$script_path
    if (is.null(p) || !file.exists(p)) return(NA)
    file.exists(file.path(dirname(p), "bioblitz_style.R"))
  })

  output$style_status_ui <- renderUI({
    ok <- style_ok()
    if (is.na(ok)) return(NULL)
    if (isTRUE(ok)) {
      div(style = "color:#2E8B7F; font-weight:600; margin-top:6px;",
          icon("check-circle"), " bioblitz_style.R found in the script folder.")
    } else {
      div(style = "color:var(--z-red); font-weight:600; margin-top:6px;",
          icon("exclamation-triangle"),
          " bioblitz_style.R is missing from the script folder. ",
          "V4 needs it for the shared palette and taxon icons - put it next to the script.")
    }
  })

  # --------------------------------------------------------------------------
  # Output directory selection
  # --------------------------------------------------------------------------
  shinyDirChoose(input, "out_dir_btn", roots = volumes, session = session,
                 allowDirCreate = TRUE)

  observe({
    if (!is.integer(input$out_dir_btn) && !is.null(input$out_dir_btn)) {
      parsed <- parseDirPath(volumes, input$out_dir_btn)
      if (length(parsed) > 0 && nchar(parsed[1]) > 0)
        rv$out_dir_path <- as.character(parsed[1])
    }
  })

  output$out_dir_display_ui <- renderUI({
    if (is.null(rv$out_dir_path))
      span(class = "not-set", "No folder selected - click Browse to choose.")
    else span(rv$out_dir_path)
  })

  # --------------------------------------------------------------------------
  # File-count helpers
  # --------------------------------------------------------------------------
  count_output_files <- function(output_dir) {
    if (is.null(output_dir) || !dir.exists(output_dir))
      return(list(photos = 0, maps = 0, slides = 0))
    d <- function(sub, pat) {
      p <- file.path(output_dir, sub)
      if (dir.exists(p)) length(list.files(p, pattern = pat, ignore.case = TRUE)) else 0
    }
    list(
      photos = d("photos", "\\.(jpg|jpeg|png)$"),
      maps   = d("maps",   "\\.(png|jpg|jpeg)$"),
      slides = d("slides", "\\.(png|jpg|jpeg)$")
    )
  }

  get_cached_obs_info <- function(output_dir) {
    if (is.null(output_dir) || !dir.exists(output_dir))
      return(list(obs_count = 0, observer_count = 0))
    f <- file.path(output_dir, "observations_cache.rds")
    if (file.exists(f)) {
      tryCatch({
        cached <- readRDS(f)
        obs_v  <- cached$observer[!is.na(cached$observer) & nchar(trimws(cached$observer)) > 0]
        list(obs_count = nrow(cached), observer_count = length(unique(obs_v)))
      }, error = function(e) list(obs_count = 0, observer_count = 0))
    } else list(obs_count = 0, observer_count = 0)
  }

  # --------------------------------------------------------------------------
  # Progress monitor
  # --------------------------------------------------------------------------
  progress_timer <- reactiveTimer(300)

  observe({
    progress_timer()
    if (rv$running && !is.null(rv$output_dir)) {
      log_file <- file.path(rv$output_dir, "console_log.txt")
      if (file.exists(log_file)) {
        tryCatch({
          lc <- readLines(log_file, warn = FALSE)
          rv$log <- paste(lc, collapse = "\n")
          if (any(grepl("SCRIPT COMPLETED SUCCESSFULLY|ERROR OCCURRED", lc))) {
            rv$running <- FALSE
            if (any(grepl("SCRIPT COMPLETED SUCCESSFULLY", lc))) {
              rv$status <- "Complete!"
            } else {
              rv$status <- "Error occurred"
              showNotification("An error occurred. Check the log for details.",
                               type = "error", duration = 10)
            }
          }
          obs_lines <- grep("Total observations:", lc, value = TRUE)
          if (length(obs_lines) > 0) {
            m <- regmatches(obs_lines[length(obs_lines)],
                            regexpr("[0-9]+", obs_lines[length(obs_lines)]))
            if (length(m) > 0) rv$obs_count <- as.integer(m[1])
          }
          ob_lines <- grep("Unique observers:\\s*[0-9]+", lc, value = TRUE)
          if (length(ob_lines) > 0) {
            m <- regmatches(ob_lines[length(ob_lines)],
                            regexpr("[0-9]+", ob_lines[length(ob_lines)]))
            if (length(m) > 0) {
              nc <- as.integer(m[1]); if (nc > rv$observer_count) rv$observer_count <- nc
            }
          }
        }, error = function(e) {})
      } else {
        elapsed <- as.numeric(Sys.time() - rv$start_time)
        if (elapsed < 30) {
          rv$log <- paste0("Waiting for the background process to start...\nElapsed: ",
                           round(elapsed, 1), "s")
        } else {
          rv$log <- "The process may have failed to start. Check the R console."
          rv$running <- FALSE; rv$status <- "Failed to start"
        }
      }

      fc <- count_output_files(rv$output_dir)
      rv$photos_downloaded <- max(0, fc$photos - rv$initial_photos)
      rv$maps_created      <- max(0, fc$maps   - rv$initial_maps)
      rv$slides_created    <- max(0, fc$slides - rv$initial_slides)

      if (!grepl("Complete|Error", rv$status)) {
        if      (rv$slides_created    > 0) rv$status <- paste0("Composing slides (", rv$slides_created, " this run)...")
        else if (rv$maps_created      > 0) rv$status <- paste0("Creating maps (", rv$maps_created, " this run)...")
        else if (rv$photos_downloaded > 0) rv$status <- paste0("Downloading photos (", rv$photos_downloaded, " this run)...")
        else if (rv$obs_count         > 0) rv$status <- paste0("Fetching observations (", rv$obs_count, " found)...")
        else rv$status <- "Processing..."
      }
    } else if (!is.null(rv$output_dir) && !rv$running) {
      fc <- count_output_files(rv$output_dir)
      rv$photos_downloaded <- max(0, fc$photos - rv$initial_photos)
      rv$maps_created      <- max(0, fc$maps   - rv$initial_maps)
      rv$slides_created    <- max(0, fc$slides - rv$initial_slides)
    }
  })

  observeEvent(rv$status, {
    if (rv$status == "Complete!") {
      showNotification("Slideshow generated. Switching to Outputs...",
                       type = "message", duration = 6)
      updateTabItems(session, "sidebar", "outputs")
    }
  })

  # --------------------------------------------------------------------------
  # Save / load configuration
  # --------------------------------------------------------------------------
  observeEvent(input$save_config, {
    config <- list(
      script_path = rv$script_path, out_dir_path = rv$out_dir_path,
      project_slug = input$project_slug, bioblitz_name = input$bioblitz_name,
      bioblitz_dates_auto = input$bioblitz_dates_auto,
      bioblitz_date_start = as.character(input$bioblitz_date_start),
      bioblitz_date_end   = as.character(input$bioblitz_date_end),
      n_photos = input$n_photos, hq_lat = input$hq_lat, hq_lon = input$hq_lon,
      max_obs_per_observer_pct = input$max_obs_per_observer_pct,
      max_obs_per_observer_abs = input$max_obs_per_observer_abs,
      max_plants_pct = input$max_plants_pct,
      base_map_zoom = input$base_map_zoom, default_dist_m = input$default_dist_m,
      map_zoom_n = input$map_zoom_n, map_pad_m = input$map_pad_m,
      map_margin_frac = input$map_margin_frac,
      auto_advance_ms = input$auto_advance_ms,
      auto_slide_stoppable = input$auto_slide_stoppable,
      slideshow_loop = input$slideshow_loop, max_collage = input$max_collage,
      create_pdf = input$create_pdf, pdf_size_limit_mb = input$pdf_size_limit_mb,
      use_random_seed = input$use_random_seed, random_seed = input$random_seed,
      fresh_run = input$fresh_run, fetch_all_observations = input$fetch_all_observations,
      cache_observations = input$cache_observations,
      use_incremental_fetch = input$use_incremental_fetch,
      force_rebuild_base_map = input$force_rebuild_base_map,
      force_rebuild_maps = input$force_rebuild_maps,
      force_rebuild_slides = input$force_rebuild_slides,
      force_rebuild_collage = input$force_rebuild_collage,
      force_rebuild_icons = input$force_rebuild_icons,
      skip_osm_overlays = input$skip_osm_overlays
    )
    saveRDS(config, "bioblitz_config.rds")
    showNotification("Configuration saved.", type = "message", duration = 3)
  })

  observeEvent(input$load_config, {
    if (!file.exists("bioblitz_config.rds")) {
      showNotification("No saved configuration found.", type = "warning", duration = 3); return()
    }
    config <- readRDS("bioblitz_config.rds")
    if (!is.null(config$script_path)  && file.exists(config$script_path))  rv$script_path  <- config$script_path
    if (!is.null(config$out_dir_path) && dir.exists(config$out_dir_path))  rv$out_dir_path <- config$out_dir_path

    updateTextInput(session, "project_slug",  value = config$project_slug)
    updateTextInput(session, "bioblitz_name", value = config$bioblitz_name %||% "My Bioblitz")
    updateCheckboxInput(session, "bioblitz_dates_auto", value = config$bioblitz_dates_auto %||% TRUE)
    if (!is.null(config$bioblitz_date_start)) updateDateInput(session, "bioblitz_date_start", value = as.Date(config$bioblitz_date_start))
    if (!is.null(config$bioblitz_date_end))   updateDateInput(session, "bioblitz_date_end",   value = as.Date(config$bioblitz_date_end))
    updateNumericInput(session, "n_photos",  value = config$n_photos)
    updateNumericInput(session, "hq_lat",    value = config$hq_lat)
    updateNumericInput(session, "hq_lon",    value = config$hq_lon)
    updateSliderInput( session, "max_obs_per_observer_pct", value = config$max_obs_per_observer_pct)
    updateNumericInput(session, "max_obs_per_observer_abs", value = config$max_obs_per_observer_abs)
    updateSliderInput( session, "max_plants_pct", value = config$max_plants_pct)
    updateNumericInput(session, "base_map_zoom",  value = config$base_map_zoom)
    updateNumericInput(session, "default_dist_m", value = config$default_dist_m)
    if (!is.null(config$map_zoom_n))      updateNumericInput(session, "map_zoom_n",      value = config$map_zoom_n)
    if (!is.null(config$map_pad_m))       updateNumericInput(session, "map_pad_m",       value = config$map_pad_m)
    if (!is.null(config$map_margin_frac)) updateNumericInput(session, "map_margin_frac", value = config$map_margin_frac)
    updateNumericInput(session, "auto_advance_ms", value = config$auto_advance_ms)
    updateCheckboxInput(session, "auto_slide_stoppable", value = config$auto_slide_stoppable)
    updateCheckboxInput(session, "slideshow_loop",       value = config$slideshow_loop)
    updateNumericInput(session, "max_collage",       value = config$max_collage)
    updateCheckboxInput(session, "create_pdf",       value = config$create_pdf)
    updateNumericInput(session, "pdf_size_limit_mb", value = config$pdf_size_limit_mb)
    updateCheckboxInput(session, "use_random_seed",  value = config$use_random_seed)
    updateNumericInput(session, "random_seed",       value = config$random_seed)
    updateCheckboxInput(session, "fresh_run",              value = config$fresh_run)
    updateCheckboxInput(session, "fetch_all_observations", value = config$fetch_all_observations)
    updateCheckboxInput(session, "cache_observations",     value = config$cache_observations)
    updateCheckboxInput(session, "use_incremental_fetch",  value = config$use_incremental_fetch)
    updateCheckboxInput(session, "force_rebuild_base_map", value = config$force_rebuild_base_map)
    updateCheckboxInput(session, "force_rebuild_maps",     value = config$force_rebuild_maps)
    updateCheckboxInput(session, "force_rebuild_slides",   value = config$force_rebuild_slides)
    updateCheckboxInput(session, "force_rebuild_collage",  value = isTRUE(config$force_rebuild_collage))
    updateCheckboxInput(session, "force_rebuild_icons",    value = isTRUE(config$force_rebuild_icons))
    updateCheckboxInput(session, "skip_osm_overlays",      value = config$skip_osm_overlays)
    showNotification("Configuration loaded.", type = "message", duration = 3)
  })

  # --------------------------------------------------------------------------
  # Presets
  # --------------------------------------------------------------------------
  apply_preset <- function(cfg) {
    bool_inputs <- c("fresh_run","fetch_all_observations","cache_observations",
                     "use_incremental_fetch","force_rebuild_base_map","force_rebuild_maps",
                     "force_rebuild_slides","force_rebuild_collage","force_rebuild_icons",
                     "skip_osm_overlays","use_random_seed")
    for (nm in bool_inputs)
      if (!is.null(cfg[[nm]])) updateCheckboxInput(session, nm, value = cfg[[nm]])
    if (!is.null(cfg$n_photos)) updateNumericInput(session, "n_photos", value = cfg$n_photos)
    showNotification(cfg$.msg, type = "message", duration = 5)
  }

  read_last_seed <- function() {
    log_path <- file.path(rv$output_dir %||% "", "console_log.txt")
    if (is.null(rv$output_dir) || !file.exists(log_path)) return(NA)
    lines <- tryCatch(readLines(log_path, warn = FALSE), error = function(e) character(0))
    sl <- grep("Random seed.*being used:|Random seed set to:|Random seed:", lines, value = TRUE)
    if (length(sl) == 0) return(NA)
    m <- regmatches(sl[length(sl)], regexpr("[0-9]{4,}", sl[length(sl)]))
    if (length(m) > 0) as.integer(m[1]) else NA
  }

  fill_last_seed <- function() {
    seed <- read_last_seed()
    if (!is.na(seed)) {
      updateNumericInput(session, "random_seed",  value = seed)
      updateNumericInput(session, "random_seed2", value = seed)
      showNotification(paste0("Last run seed (", seed, ") applied - same photos will be reused."),
                       type = "message", duration = 6)
    }
  }

  observeEvent(input$preset_html_only, {
    apply_preset(list(fresh_run = FALSE, fetch_all_observations = TRUE, cache_observations = TRUE,
      use_incremental_fetch = FALSE, force_rebuild_base_map = FALSE, force_rebuild_maps = FALSE,
      force_rebuild_slides = FALSE, force_rebuild_collage = FALSE, force_rebuild_icons = FALSE,
      skip_osm_overlays = FALSE, use_random_seed = TRUE,
      .msg = "Regenerate HTML - all caches reused. A specific seed is applied so the same observations are picked."))
    fill_last_seed()
  })

  observeEvent(input$preset_new_collage, {
    apply_preset(list(fresh_run = FALSE, fetch_all_observations = TRUE, cache_observations = TRUE,
      use_incremental_fetch = FALSE, force_rebuild_base_map = FALSE, force_rebuild_maps = FALSE,
      force_rebuild_slides = FALSE, force_rebuild_collage = TRUE, force_rebuild_icons = FALSE,
      skip_osm_overlays = FALSE, use_random_seed = TRUE,
      .msg = "New collage - only the collage image is rebuilt. Seed applied so the same slides are reused."))
    fill_last_seed()
  })

  observeEvent(input$preset_quick_test, {
    apply_preset(list(fresh_run = FALSE, fetch_all_observations = FALSE, cache_observations = FALSE,
      use_incremental_fetch = FALSE, force_rebuild_base_map = TRUE, force_rebuild_maps = TRUE,
      force_rebuild_slides = TRUE, force_rebuild_collage = TRUE, force_rebuild_icons = FALSE,
      skip_osm_overlays = TRUE, n_photos = 3, use_random_seed = FALSE,
      .msg = "Quick test - 3 slides, full rebuild, no OSM. Good for checking layout and settings."))
  })

  observeEvent(input$preset_update, {
    apply_preset(list(fresh_run = FALSE, fetch_all_observations = FALSE, cache_observations = TRUE,
      use_incremental_fetch = TRUE, force_rebuild_base_map = FALSE, force_rebuild_maps = FALSE,
      force_rebuild_slides = FALSE, force_rebuild_collage = TRUE, force_rebuild_icons = FALSE,
      skip_osm_overlays = FALSE, use_random_seed = TRUE,
      .msg = "Update new observations - fetches new obs only, then rebuilds collage and HTML."))
  })

  observeEvent(input$preset_full_rebuild, {
    apply_preset(list(fresh_run = FALSE, fetch_all_observations = TRUE, cache_observations = TRUE,
      use_incremental_fetch = FALSE, force_rebuild_base_map = TRUE, force_rebuild_maps = TRUE,
      force_rebuild_slides = TRUE, force_rebuild_collage = TRUE, force_rebuild_icons = FALSE,
      skip_osm_overlays = FALSE, use_random_seed = TRUE,
      .msg = "Full rebuild - rebuilds maps, slides, collage and HTML. Photos reused from cache."))
  })

  observeEvent(input$preset_fresh_run, {
    apply_preset(list(fresh_run = TRUE, fetch_all_observations = TRUE, cache_observations = FALSE,
      use_incremental_fetch = FALSE, force_rebuild_base_map = TRUE, force_rebuild_maps = TRUE,
      force_rebuild_slides = TRUE, force_rebuild_collage = TRUE, force_rebuild_icons = FALSE,
      skip_osm_overlays = FALSE, use_random_seed = FALSE,
      .msg = "Fresh run - all cached files deleted. Everything is re-downloaded and rebuilt."))
  })

  # --------------------------------------------------------------------------
  # Run the script
  # --------------------------------------------------------------------------
  observeEvent(input$run_script, {
    if (rv$running) {
      showNotification("A slideshow is already being generated.", type = "warning", duration = 5); return()
    }
    script_path <- rv$script_path
    if (is.null(script_path) || !file.exists(script_path)) {
      showNotification("Script not found. Select the slideshow R script in Configuration.",
                       type = "error", duration = 8)
      rv$status <- "Error: script not selected"; return()
    }
    if (!isTRUE(style_ok())) {
      showNotification(paste0("bioblitz_style.R was not found beside the script. ",
                              "V4 needs it - put it in the same folder as the slideshow script."),
                       type = "error", duration = 10)
      rv$status <- "Error: bioblitz_style.R missing"; return()
    }
    out_dir_path <- rv$out_dir_path
    if (is.null(out_dir_path) || !nzchar(out_dir_path)) {
      showNotification("Select an output folder in Configuration.", type = "error", duration = 8); return()
    }
    if (nchar(input$project_slug) == 0) {
      showNotification("Enter a project slug.", type = "error", duration = 5); return()
    }
    if (is.na(input$n_photos) || input$n_photos < 1) {
      showNotification("Number of photos must be at least 1.", type = "error", duration = 5); return()
    }

    needs_seed <- !isTRUE(input$fresh_run) && !isTRUE(input$force_rebuild_maps) &&
                  !isTRUE(input$force_rebuild_slides)
    has_seed   <- !is.null(input$random_seed) && !is.na(input$random_seed) &&
                  nchar(trimws(as.character(input$random_seed))) > 0
    if (needs_seed && !has_seed) {
      showModal(modalDialog(
        title = "No seed set - confirm you want to continue",
        HTML("Without a specific seed, a <b>new random selection of photos</b> will be drawn. ",
             "Any newly selected photos without cached slides or maps will be <b>rebuilt ",
             "automatically</b>, even with Force rebuild off.<br><br>",
             "<b>Options:</b><ul>",
             "<li>Cancel and click <b>Use last run seed</b> to reuse the previous seed</li>",
             "<li>Or enter a seed in the Specific seed field</li>",
             "<li>Or use the <b>Full rebuild</b> preset for a deliberate full regeneration</li></ul>"),
        footer = tagList(
          modalButton("Cancel - let me set a seed"),
          actionButton("confirm_no_seed", "Continue anyway", class = "btn-warning")
        ), easyClose = FALSE
      )); return()
    }
    launch_run()
  })

  observeEvent(input$confirm_no_seed, { removeModal(); launch_run() })

  # --------------------------------------------------------------------------
  # Core run launcher
  # --------------------------------------------------------------------------
  launch_run <- function() {
    out_dir_path <- rv$out_dir_path
    if (is.null(out_dir_path) || !nzchar(out_dir_path)) return()

    rv$running <- TRUE
    rv$log <- "Initializing slideshow generation...\n\n"
    rv$status <- "Initializing..."
    rv$start_time <- Sys.time()
    script_path <- rv$script_path
    script_dir  <- dirname(normalizePath(script_path, winslash = "/"))

    dir.create(out_dir_path, recursive = TRUE, showWarnings = FALSE)
    out_dir_norm <- normalizePath(out_dir_path, winslash = "/", mustWork = FALSE)
    rv$output_dir <- out_dir_norm

    if (!input$fresh_run) {
      baseline <- count_output_files(out_dir_norm)
      rv$initial_photos <- baseline$photos
      rv$initial_maps   <- baseline$maps
      rv$initial_slides <- baseline$slides
      ci <- get_cached_obs_info(out_dir_norm)
      rv$obs_count <- ci$obs_count; rv$observer_count <- ci$observer_count
    } else {
      rv$initial_photos <- 0; rv$initial_maps <- 0; rv$initial_slides <- 0
      rv$obs_count <- 0; rv$observer_count <- 0
    }
    rv$photos_downloaded <- 0; rv$maps_created <- 0; rv$slides_created <- 0

    log_file      <- file.path(out_dir_norm, "console_log.txt")
    progress_file <- file.path(out_dir_norm, "progress.txt")
    writeLines("=== Slideshow generation started ===\n", log_file)
    writeLines("STATUS:Initializing...", progress_file)
    showNotification("Starting generation. Watch live progress below.",
                     type = "message", duration = 5)

    # Logo: copy the upload into the output folder and pass an ABSOLUTE path,
    # since we run the script from its own directory (see setwd below).
    logo_file <- ""
    if (!is.null(input$bioblitz_logo)) {
      ext  <- tools::file_ext(input$bioblitz_logo$name); if (!nzchar(ext)) ext <- "jpg"
      dest <- file.path(out_dir_norm, paste0("bioblitz_logo.", ext))
      file.copy(input$bioblitz_logo$datapath, dest, overwrite = TRUE)
      logo_file <- normalizePath(dest, winslash = "/", mustWork = FALSE)
    }

    script_full_path <- normalizePath(script_path, winslash = "/")
    log_file_path    <- normalizePath(log_file,    winslash = "/", mustWork = FALSE)
    out_dir_escaped  <- gsub("\\\\", "/", out_dir_norm)

    fmt_bool <- function(x) if (isTRUE(x)) "TRUE" else "FALSE"
    fmt_seed <- function(x) if (is.null(x) || is.na(x)) "NULL" else as.character(x)
    fmt_date <- function(x) if (is.null(x) || is.na(x) || !nzchar(as.character(x))) "NULL"
                            else paste0('"', as.character(x), '"')
    fmt_str  <- function(x) paste0('"', gsub('"', '\\\\"', x), '"')

    dates_auto  <- input$bioblitz_dates_auto
    date_start  <- if (!dates_auto) as.character(input$bioblitz_date_start) else NULL
    date_end    <- if (!dates_auto) as.character(input$bioblitz_date_end)   else NULL

    wrapper_script     <- file.path(out_dir_norm, "run_wrapper.R")
    pid_file_path      <- normalizePath(file.path(out_dir_norm, "process.pid"), winslash = "/", mustWork = FALSE)
    progress_file_path <- normalizePath(progress_file, winslash = "/", mustWork = FALSE)

    wrapper_content <- paste0('
# Run from the SCRIPT folder so V4\'s source("bioblitz_style.R"),
# the default logo path and any other relative references resolve exactly as
# they do when the script is sourced standalone in RStudio.
setwd("', script_dir, '")

log_file      <- "', log_file_path, '"
progress_file <- "', progress_file_path, '"
script_path   <- "', script_full_path, '"
pid_file      <- "', pid_file_path, '"

writeLines(as.character(Sys.getpid()), pid_file)
writeLines("STATUS:Initializing...", progress_file)

write_log      <- function(text) write(text, file = log_file,      append = TRUE)
write_progress <- function(text) write(text, file = progress_file, append = TRUE)
write_log("=== Slideshow generation started ===")
write_log(paste("Script folder:", getwd()))
write_log("")

script_env <- new.env(parent = .GlobalEnv)

make_locked_param <- function(env, name, value) {
  makeActiveBinding(name, local({
    val <- value
    function(v) { if (missing(v)) val else val }
  }), env)
}

make_locked_param(script_env, "project_slug",             ', fmt_str(input$project_slug), ')
make_locked_param(script_env, "bioblitz_name",            ', fmt_str(input$bioblitz_name), ')
make_locked_param(script_env, "bioblitz_dates_auto",      ', fmt_bool(dates_auto), ')
make_locked_param(script_env, "bioblitz_dates_start",     ', fmt_date(date_start), ')
make_locked_param(script_env, "bioblitz_dates_end",       ', fmt_date(date_end), ')
make_locked_param(script_env, "n_photos",                 ', input$n_photos, ')
make_locked_param(script_env, "bioblitz_logo",            "', logo_file, '")
make_locked_param(script_env, "hq_lon",                   ', input$hq_lon, ')
make_locked_param(script_env, "hq_lat",                   ', input$hq_lat, ')
make_locked_param(script_env, "max_obs_per_observer_pct", ', input$max_obs_per_observer_pct / 100, ')
make_locked_param(script_env, "max_obs_per_observer_abs", ', input$max_obs_per_observer_abs, ')
make_locked_param(script_env, "max_plants_pct",           ', input$max_plants_pct / 100, ')
make_locked_param(script_env, "use_random_seed",          ', fmt_bool(input$use_random_seed), ')
make_locked_param(script_env, "random_seed",              ', fmt_seed(input$random_seed), ')
make_locked_param(script_env, "fresh_run",                ', fmt_bool(input$fresh_run), ')
make_locked_param(script_env, "fetch_all_observations",   ', fmt_bool(input$fetch_all_observations), ')
make_locked_param(script_env, "cache_observations",       ', fmt_bool(input$cache_observations), ')
make_locked_param(script_env, "use_incremental_fetch",    ', fmt_bool(input$use_incremental_fetch), ')
make_locked_param(script_env, "force_rebuild_base_map",   ', fmt_bool(input$force_rebuild_base_map), ')
make_locked_param(script_env, "force_rebuild_maps",       ', fmt_bool(input$force_rebuild_maps), ')
make_locked_param(script_env, "force_rebuild_slides",     ', fmt_bool(input$force_rebuild_slides), ')
make_locked_param(script_env, "force_rebuild_collage",    ', fmt_bool(input$force_rebuild_collage), ')
make_locked_param(script_env, "force_rebuild_icons",      ', fmt_bool(input$force_rebuild_icons), ')
make_locked_param(script_env, "skip_osm_overlays",        ', fmt_bool(input$skip_osm_overlays), ')
make_locked_param(script_env, "base_map_zoom",            ', input$base_map_zoom, ')
make_locked_param(script_env, "default_dist_m",           ', input$default_dist_m, ')
make_locked_param(script_env, "map_zoom_n",               ', input$map_zoom_n, ')
make_locked_param(script_env, "map_pad_m",                ', input$map_pad_m, ')
make_locked_param(script_env, "map_margin_frac",          ', input$map_margin_frac, ')
make_locked_param(script_env, "auto_advance_ms",          ', input$auto_advance_ms * 1000, ')
make_locked_param(script_env, "auto_slide_stoppable",     ', fmt_bool(input$auto_slide_stoppable), ')
make_locked_param(script_env, "slideshow_loop",           ', fmt_bool(input$slideshow_loop), ')
make_locked_param(script_env, "max_collage",              ', input$max_collage, ')
make_locked_param(script_env, "create_pdf",               ', fmt_bool(input$create_pdf), ')
make_locked_param(script_env, "pdf_size_limit_mb",        ', input$pdf_size_limit_mb, ')
make_locked_param(script_env, "out_dir",                  "', out_dir_escaped, '")
make_locked_param(script_env, "diagnostic_mode",          TRUE)

write_log("Parameters set. Sourcing script...")
write_log("")

filter_patterns <- c(
  "^Attaching package:", "^The following object", "^Linking to (GEOS|ImageMagick|GDAL|PROJ)",
  "^terra [0-9]", "^Enabled features:", "^Disabled features:",
  "^Data \\\\(c\\\\) OpenStreetMap", "resampled to [0-9]+ cells",
  "Coordinate system already present", "Adding new coordinate system"
)
should_filter <- function(line) {
  line <- trimws(line); if (nchar(line) == 0) return(FALSE)
  for (p in filter_patterns) if (grepl(p, line, perl = TRUE)) return(TRUE)
  FALSE
}
update_progress <- function(line) {
  line <- trimws(line)
  if (grepl("Total observations:", line, fixed = TRUE)) {
    m <- regmatches(line, regexpr("[0-9]+", line))
    if (length(m) > 0) write_progress(paste0("OBS_COUNT:", m[1]))
  }
  if (grepl("nique observers", line)) {
    m <- regmatches(line, regexpr("[0-9]+", line))
    if (length(m) > 0) write_progress(paste0("OBSERVER_COUNT:", m[1]))
  }
  if (grepl("^===", line)) {
    st <- trimws(gsub("^=== | ===$", "", line))
    if (nchar(st) > 0) write_progress(paste0("STATUS:", st))
  }
}

# Route the script\'s console output to the log file.
script_env$cat <- function(..., sep = " ", fill = FALSE, labels = NULL, append = FALSE) {
  text  <- paste(..., sep = sep, collapse = "")
  lines <- strsplit(text, "\\n")[[1]]
  for (line in lines) {
    update_progress(line)
    if (!should_filter(line)) write(line, file = log_file, append = TRUE)
  }
}
script_env$library <- function(..., character.only = FALSE) {
  suppressPackageStartupMessages(base::library(..., character.only = character.only))
}
# IMPORTANT (V4): make the script\'s source("bioblitz_style.R") load INTO
# script_env so the style file can see the locked settings (e.g. force_rebuild_icons)
# and its palette / icon helpers are visible to the rest of the script.
script_env$source <- function(file, ...) {
  base::source(file, local = script_env, chdir = TRUE)
}

tryCatch({
  source(script_path, local = script_env)
  write_log("")
  write_log("=== SCRIPT COMPLETED SUCCESSFULLY ===")
  write_log(paste("Output directory:", script_env$out_dir))
  write_progress("STATUS:Complete")
}, error = function(e) {
  write_log("")
  write_log("=== ERROR OCCURRED ===")
  write_log(paste("Error message:", conditionMessage(e)))
  write_progress("STATUS:Error")
})

if (file.exists(pid_file)) file.remove(pid_file)
')

    writeLines(wrapper_content, wrapper_script)
    rv$pid_file <- pid_file_path
    wrapper_full_path <- normalizePath(wrapper_script, winslash = "/")

    # Use the SAME R that runs this app, so geospatial packages resolve.
    rscript_bin <- file.path(R.home("bin"),
                             if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
    wrapper_console <- normalizePath(file.path(out_dir_norm, "wrapper_console.log"),
                                     winslash = "/", mustWork = FALSE)

    if (.Platform$OS.type == "windows") {
      cmd <- sprintf('"%s" "%s" > "%s" 2>&1', rscript_bin, wrapper_full_path, wrapper_console)
      result <- system(cmd, wait = FALSE, invisible = TRUE)
    } else {
      cmd <- sprintf('"%s" "%s" > "%s" 2>&1 &', rscript_bin, wrapper_full_path, wrapper_console)
      result <- system(cmd)
    }

    if (!is.null(result) && result != 0) {
      rv$running <- FALSE; rv$status <- "Failed to start"
      showNotification(paste0("Failed to start background process. Code: ", result),
                       type = "error", duration = 10); return()
    }

    Sys.sleep(1)
    if (!file.exists(log_file)) {
      rv$running <- FALSE; rv$status <- "Failed to start - no log file"
      showNotification("The script may have failed to start. Log file not found.",
                       type = "warning", duration = 10)
    }
    rv$status <- "Running in background..."
  }

  # --------------------------------------------------------------------------
  # Stop button
  # --------------------------------------------------------------------------
  observeEvent(input$stop_script, {
    if (!rv$running) {
      showNotification("No process is running.", type = "warning", duration = 3); return()
    }
    killed <- FALSE
    if (!is.null(rv$pid_file) && file.exists(rv$pid_file)) {
      tryCatch({
        pid <- readLines(rv$pid_file, warn = FALSE)[1]
        if (!is.na(pid) && nchar(trimws(pid)) > 0 && grepl("^[0-9]+$", pid)) {
          res <- if (.Platform$OS.type == "windows")
            system(sprintf("taskkill /F /PID %s", pid), ignore.stdout = TRUE, ignore.stderr = TRUE)
          else system(sprintf("kill -9 %s", pid), ignore.stdout = TRUE, ignore.stderr = TRUE)
          killed <- (res == 0)
        }
        if (file.exists(rv$pid_file)) file.remove(rv$pid_file)
      }, error = function(e) {})
    }
    rv$running <- FALSE
    rv$status  <- if (killed) "Stopped by user" else "Stop requested"
    showNotification(if (killed) "Process stopped." else "Stop signal sent.",
                     type = if (killed) "message" else "warning", duration = 5)
  })

  # --------------------------------------------------------------------------
  # Seed sync + last-seed button
  # --------------------------------------------------------------------------
  observeEvent(input$use_random_seed2, updateCheckboxInput(session, "use_random_seed", value = input$use_random_seed2))
  observeEvent(input$random_seed2,     updateNumericInput(session, "random_seed",  value = input$random_seed2))
  observeEvent(input$use_random_seed,  updateCheckboxInput(session, "use_random_seed2", value = input$use_random_seed))
  observeEvent(input$random_seed,      updateNumericInput(session, "random_seed2", value = input$random_seed))

  observeEvent(input$use_last_seed, {
    seed <- read_last_seed()
    if (!is.na(seed)) {
      updateNumericInput(session, "random_seed2", value = seed)
      updateNumericInput(session, "random_seed",  value = seed)
      updateCheckboxInput(session, "use_random_seed2", value = TRUE)
      updateCheckboxInput(session, "use_random_seed",  value = TRUE)
      showNotification(paste0("Seed ", seed, " loaded from the last run."),
                       type = "message", duration = 6)
    } else {
      showNotification("No previous run log found in the output folder. Run once first.",
                       type = "warning", duration = 6)
    }
  })

  output$seed_warning_banner <- renderUI({
    needs_seed <- !isTRUE(input$fresh_run) && !isTRUE(input$force_rebuild_maps) &&
                  !isTRUE(input$force_rebuild_slides) && isTRUE(input$use_random_seed)
    has_seed <- !is.null(input$random_seed2) && !is.na(input$random_seed2) &&
                nchar(as.character(input$random_seed2)) > 0
    if (needs_seed && !has_seed) {
      div(style = "background:#FBECE9; color:#7a1c0d; border-radius:8px; padding:12px 18px;
                   margin-bottom:12px; border-left:5px solid var(--z-red);",
        tags$b("No specific seed set - photos may differ from your last run."), tags$br(),
        "Without a fixed seed, a new random selection is drawn each run, and any observations ",
        "without cached slides or maps get rebuilt. ",
        tags$br(), tags$br(),
        "Click ", tags$b("Use last run seed"), " to reuse the previous seed, or enter one below.")
    } else if (needs_seed && has_seed) {
      div(style = "background:#EAF3ED; color:#2E8B7F; border-radius:8px; padding:8px 18px;
                   margin-bottom:12px; border-left:5px solid #2E8B7F;",
        paste0("Seed ", input$random_seed2, " is set - the same photos will be reused."))
    }
  })

  # --------------------------------------------------------------------------
  # Status + progress outputs
  # --------------------------------------------------------------------------
  output$status_text  <- renderText(rv$status)
  output$progress_log <- renderText(rv$log)

  output$progress_stages <- renderUI({
    if (!rv$running && nchar(rv$log) < 50)
      return(p("Click Generate slideshow to begin.", style = "color:#a79f8b;"))
    lt <- rv$log
    stages <- list(
      list(name = "Initializing",                complete = nchar(lt) > 0),
      list(name = "Fetching observations",       complete = grepl("observations|Fetched|FETCHING", lt)),
      list(name = "Downloading photos",          complete = rv$photos_downloaded > 0 || grepl("DOWNLOADING PHOTOS|Downloading", lt)),
      list(name = "Creating maps",               complete = rv$maps_created > 0 || grepl("CREATING MAPS|satellite", lt)),
      list(name = "Composing slides",            complete = rv$slides_created > 0 || grepl("COMPOSING SLIDES", lt)),
      list(name = "Building slideshow",          complete = grepl("GENERATING HTML|slideshow.html|Rendering", lt)),
      list(name = "Complete",                    complete = grepl("SCRIPT COMPLETED SUCCESSFULLY|=== COMPLETE ===", lt))
    )
    tagList(lapply(stages, function(s) {
      if (s$complete)
        tags$div(style = "margin:5px 0;", class = "stage-done", icon("check-circle"), " ", tags$b(s$name))
      else
        tags$div(style = "margin:5px 0;", class = "stage-todo", icon("circle"), " ", s$name)
    }))
  })

  mk_box <- function(title, value) infoBox(title, value,
    icon = shiny::icon("circle", class = "hidden-icon"), color = "blue", fill = FALSE)
  output$obs_count_box         <- renderInfoBox(mk_box("Observations",   rv$obs_count))
  output$observer_count_box    <- renderInfoBox(mk_box("Observers",      rv$observer_count))
  output$photos_downloaded_box <- renderInfoBox(mk_box("Photos (run)",   rv$photos_downloaded))
  output$maps_created_box      <- renderInfoBox(mk_box("Maps (run)",     rv$maps_created))
  output$slides_created_box    <- renderInfoBox(mk_box("Slides (run)",   rv$slides_created))

  output$output_files_ui <- renderUI({
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir))
      return(p("No outputs yet. Run the generator first."))
    files <- list.files(rv$output_dir, full.names = FALSE)
    if (length(files) == 0) return(p("No files in the output directory."))
    ul <- tags$ul()
    if ("slideshow.html" %in% files) ul <- tagAppendChild(ul, tags$li(tags$b("slideshow.html"), " - main slideshow (open in a browser)"))
    if ("slideshow.pdf"  %in% files) ul <- tagAppendChild(ul, tags$li(tags$b("slideshow.pdf"),  " - PDF version"))
    if ("collage.png"    %in% files) ul <- tagAppendChild(ul, tags$li(tags$b("collage.png"),    " - closing photo collage"))
    ul <- tagAppendChild(ul, tags$li(paste("Total files:", length(files))))
    ul
  })

  output$output_path <- renderText({
    if (is.null(rv$output_dir)) "Not yet generated"
    else normalizePath(rv$output_dir, mustWork = FALSE)
  })

  output$debug_info <- renderText({
    if (is.null(rv$output_dir)) return("No slideshow generated yet.")
    info <- paste0("Script path: ", rv$script_path %||% "(not set)", "\n",
                   "Output dir:  ", rv$output_dir, "\n",
                   "Exists:      ", dir.exists(rv$output_dir), "\n\n")
    for (sub in c("photos", "maps", "slides")) {
      d <- file.path(rv$output_dir, sub)
      n <- if (dir.exists(d)) length(list.files(d, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE)) else 0
      info <- paste0(info, sub, " dir: ", d, "\n  exists: ", dir.exists(d), ", files: ", n, "\n")
    }
    info
  })

  # --------------------------------------------------------------------------
  # Refresh counts
  # --------------------------------------------------------------------------
  observeEvent(input$refresh_counts, {
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      showNotification("No output directory set.", type = "warning", duration = 5); return()
    }
    fc <- count_output_files(rv$output_dir)
    rv$photos_downloaded <- max(0, fc$photos - rv$initial_photos)
    rv$maps_created      <- max(0, fc$maps   - rv$initial_maps)
    rv$slides_created    <- max(0, fc$slides - rv$initial_slides)
    showNotification(paste0("Refreshed. Photos: ", rv$photos_downloaded,
                            "  Maps: ", rv$maps_created, "  Slides: ", rv$slides_created),
                     type = "message", duration = 5)
  })

  # --------------------------------------------------------------------------
  # Housekeeping: clear cached images
  # --------------------------------------------------------------------------
  clear_dir_images <- function(sub, label) {
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      showNotification("No output directory set.", type = "warning", duration = 4); return()
    }
    d <- file.path(rv$output_dir, sub)
    if (!dir.exists(d)) { showNotification(paste0("No ", label, " cache found."), type = "message", duration = 4); return() }
    fs <- list.files(d, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE, full.names = TRUE)
    unlink(fs)
    showNotification(paste0("Cleared ", length(fs), " cached ", label, "."), type = "message", duration = 4)
  }
  observeEvent(input$clear_maps,   clear_dir_images("maps",   "maps"))
  observeEvent(input$clear_slides, clear_dir_images("slides", "slides"))
  observeEvent(input$clear_collage, {
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      showNotification("No output directory set.", type = "warning", duration = 4)
    } else {
      f <- file.path(rv$output_dir, "collage.png")
      if (file.exists(f)) { unlink(f); showNotification("Cleared cached collage.", type = "message", duration = 4) }
      else showNotification("No collage.png found.", type = "message", duration = 4)
    }
  })

  # --------------------------------------------------------------------------
  # Open HTML / folder
  # --------------------------------------------------------------------------
  observeEvent(input$open_html, {
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      showNotification("No output directory found.", type = "warning", duration = 5); return()
    }
    html_file <- file.path(rv$output_dir, "slideshow.html")
    if (!file.exists(html_file)) {
      showNotification("slideshow.html not found yet. Wait for generation to finish.",
                       type = "warning", duration = 5); return()
    }
    tryCatch({
      hp <- normalizePath(html_file, winslash = "/")
      if (.Platform$OS.type == "windows") shell.exec(normalizePath(html_file, winslash = "\\"))
      else if (Sys.info()["sysname"] == "Darwin") system2("open", shQuote(hp))
      else system2("xdg-open", shQuote(hp))
      showNotification("Opening slideshow in your browser...", type = "message", duration = 3)
    }, error = function(e) {
      showNotification(paste0("Could not open a browser automatically.\nFile: ", normalizePath(html_file)),
                       type = "error", duration = 10)
    })
  })

  observeEvent(input$open_folder, {
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      showNotification("Output directory not found.", type = "warning", duration = 5); return()
    }
    fp <- normalizePath(rv$output_dir, winslash = "\\")
    tryCatch({
      if (.Platform$OS.type == "windows") shell.exec(fp)
      else if (Sys.info()["sysname"] == "Darwin") system2("open", shQuote(fp))
      else system2("xdg-open", shQuote(fp))
      showNotification("Opening the output folder...", type = "message", duration = 3)
    }, error = function(e) {
      showNotification(paste0("Could not open the folder automatically.\nLocation: ", fp),
                       type = "warning", duration = 10)
    })
  })

  # --------------------------------------------------------------------------
  # Session cleanup
  # --------------------------------------------------------------------------
  session$onSessionEnded(function() {
    pid_file_path <- isolate(rv$pid_file)
    if (!is.null(pid_file_path) && file.exists(pid_file_path)) {
      tryCatch({
        pid <- readLines(pid_file_path, warn = FALSE)[1]
        if (!is.na(pid) && nchar(trimws(pid)) > 0 && grepl("^[0-9]+$", pid)) {
          if (.Platform$OS.type == "windows")
            system(sprintf("taskkill /F /PID %s", pid), ignore.stdout = TRUE, ignore.stderr = TRUE)
          else system(sprintf("kill -9 %s", pid), ignore.stdout = TRUE, ignore.stderr = TRUE)
        }
        if (file.exists(pid_file_path)) file.remove(pid_file_path)
      }, error = function(e) {})
    }
  })
}

# ==============================================================================
# RUN APP
# ==============================================================================
shinyApp(ui = ui, server = server)
