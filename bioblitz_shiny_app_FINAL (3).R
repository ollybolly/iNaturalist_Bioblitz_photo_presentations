# ==============================================================================
# iNaturalist Bioblitz Slideshow Generator - Shiny App (FINAL)
# ==============================================================================
#
# IMPROVEMENTS:
# 1. Shows cached observation count when Fresh Run is unchecked
# 2. Tracks only NEW files created in current run (not cumulative)
# 3. Displays number of observers in addition to observations
# 4. Better explanation of Fresh Run option
# 5. COLORFUL EMOJI ICONS - telescope, people, camera, map, film for visual appeal
# 6. Full verbosity (prevents hanging during execution)
#
# ==============================================================================

library(shiny)
library(shinydashboard)
library(shinyWidgets)

# ==============================================================================
# USER INTERFACE
# ==============================================================================

ui <- dashboardPage(
  skin = "green",
  
  dashboardHeader(title = "iNaturalist Bioblitz Slideshow Generator"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Configuration", tabName = "config", icon = icon("cog")),
      menuItem("Run & Progress", tabName = "run", icon = icon("play")),
      menuItem("Outputs", tabName = "outputs", icon = icon("file-image")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .info-box { 
          min-height: 90px !important;
          border-radius: 10px !important;
          box-shadow: 0 3px 10px rgba(0,0,0,0.15) !important;
        }
        .box { margin-bottom: 20px; }
        .help-text { color: #666; font-size: 0.9em; margin-top: 5px; }
        .required-label:after { content: ' *'; color: red; }
        
        /* Hide the icon box since we're using emojis in labels */
        .info-box-icon {
          display: none !important;
        }
        
        /* Make the content take full width without icon */
        .info-box-content {
          margin-left: 10px !important;
        }
        
        /* Make emoji labels larger and more prominent */
        .info-box-text {
          font-weight: 600 !important;
          font-size: 16px !important;
          letter-spacing: 0.5px !important;
          color: #2c3e50 !important;
        }
        
        /* Enhanced numbers */
        .info-box-number {
          font-weight: 800 !important;
          font-size: 42px !important;
          color: #2c3e50 !important;
          margin-top: 8px !important;
        }
      "))
    ),
    
    tabItems(
      # ========================================================================
      # CONFIGURATION TAB
      # ========================================================================
      tabItem(tabName = "config",
        fluidRow(
          box(
            title = "Script Location", 
            status = "danger", 
            solidHeader = TRUE, 
            width = 12,
            
            p(strong("IMPORTANT:"), "The app needs the original slideshow R script to work."),
            
            textInput(
              "script_path",
              "Script Filename (in same folder as app)",
              value = "Final_Walpole_Bioblitz_Slideshow_Script.R",
              placeholder = "e.g., Final_Walpole_Bioblitz_Slideshow_Script.R"
            ),
            div(class = "help-text", 
                "The original R script must be in the same folder as this Shiny app"),
            
            uiOutput("script_status_ui")
          )
        ),
        
        fluidRow(
          box(
            title = "Project Settings", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 6,
            
            textInput(
              "project_slug",
              tags$span(class = "required-label", "iNaturalist Project Slug"),
              value = "walpole-wilderness-bioblitz-2025",
              placeholder = "e.g., my-bioblitz-2025"
            ),
            div(class = "help-text", 
                "Find this in your iNaturalist project URL: inaturalist.org/projects/YOUR-PROJECT-SLUG"),
            
            numericInput(
              "n_photos",
              "Number of Photos in Slideshow",
              value = 3,
              min = 1,
              max = 1000,
              step = 1
            ),
            div(class = "help-text", 
                "Total number of randomly selected observations to include"),
            
            fileInput(
              "bioblitz_logo",
              "Upload Bioblitz Logo (Optional)",
              accept = c("image/png", "image/jpeg", "image/jpg")
            ),
            div(class = "help-text", 
                "Logo will appear on the welcome slide. JPG or PNG format."),
            
            textInput(
              "out_dir",
              "Output Directory Name",
              value = "bioblitz_slideshow_output",
              placeholder = "e.g., my_bioblitz_slideshow"
            ),
            div(class = "help-text", 
                "Folder name where outputs will be saved (inside ./outputs/ subdirectory)."),
            div(class = "help-text", style = "margin-top: 10px; font-style: italic;",
                "NOTE: This uses a different default folder than the original script 
                 ('bioblitz_slideshow_output' vs 'walpole_wilderness_bioblitz_2025_slideshow'). 
                 This keeps Shiny app runs separate from manual script runs.")
          ),
          
          box(
            title = "Location Settings (for Maps)", 
            status = "primary", 
            solidHeader = TRUE, 
            width = 6,
            
            numericInput(
              "hq_lat",
              tags$span(class = "required-label", "Headquarters Latitude"),
              value = -34.992854,
              step = 0.000001
            ),
            div(class = "help-text", 
                "Decimal degrees (e.g., -34.992854)"),
            
            numericInput(
              "hq_lon",
              tags$span(class = "required-label", "Headquarters Longitude"),
              value = 116.634398,
              step = 0.000001
            ),
            div(class = "help-text", 
                "Decimal degrees (e.g., 116.634398)"),
            
            numericInput(
              "base_map_zoom",
              "Base Map Zoom Level",
              value = 14,
              min = 10,
              max = 18,
              step = 1
            ),
            div(class = "help-text", 
                "13-15 recommended. Higher = more detail but slower."),
            
            numericInput(
              "buffer_km",
              "Map Buffer (km)",
              value = 3.5,
              min = 1,
              max = 20,
              step = 0.5
            ),
            div(class = "help-text", 
                "Buffer around observations for map extent (3-5 km recommended)"),
            
            numericInput(
              "default_dist_m",
              "Individual Map Radius (meters)",
              value = 4000,
              min = 500,
              max = 10000,
              step = 500
            ),
            div(class = "help-text", 
                "Radius for individual observation maps")
          )
        ),
        
        fluidRow(
          box(
            title = "Diversity Settings", 
            status = "info", 
            solidHeader = TRUE, 
            width = 6,
            
            sliderInput(
              "max_obs_per_observer_pct",
              "Max % Photos from Single Observer",
              value = 15,
              min = 5,
              max = 100,
              step = 5,
              post = "%"
            ),
            div(class = "help-text", 
                "Ensures diversity of observers in slideshow"),
            
            numericInput(
              "max_obs_per_observer_abs",
              "Absolute Max Photos per Observer",
              value = 5,
              min = 1,
              max = 50,
              step = 1
            ),
            div(class = "help-text", 
                "Hard limit, overrides percentage if lower"),
            
            sliderInput(
              "max_plants_pct",
              "Max % Plant Photos",
              value = 50,
              min = 0,
              max = 100,
              step = 5,
              post = "%"
            ),
            div(class = "help-text", 
                "Prevents plant-heavy slideshows, ensures taxonomic diversity")
          ),
          
          box(
            title = "Slideshow Settings", 
            status = "info", 
            solidHeader = TRUE, 
            width = 6,
            
            numericInput(
              "auto_advance_ms",
              "Auto-Advance Time (seconds)",
              value = 7,
              min = 1,
              max = 60,
              step = 1
            ),
            div(class = "help-text", 
                "How long each slide displays before advancing"),
            
            checkboxInput(
              "auto_slide_stoppable",
              "Allow User to Stop Auto-Advance",
              value = TRUE
            ),
            
            checkboxInput(
              "slideshow_loop",
              "Loop Slideshow",
              value = FALSE
            ),
            
            numericInput(
              "max_collage",
              "Max Photos in Final Collage",
              value = 25,
              min = 5,
              max = 100,
              step = 5
            ),
            div(class = "help-text", 
                "Final slide shows collage of random photos")
          )
        ),
        
        fluidRow(
          box(
            title = "Run Mode & Performance", 
            status = "warning", 
            solidHeader = TRUE, 
            width = 6,
            
            checkboxInput(
              "fresh_run",
              "Fresh Run (Delete Old Artifacts)",
              value = TRUE
            ),
            div(class = "help-text", 
                HTML("<b>Fresh Run (checked):</b> Deletes all previous output files (photos, maps, slides) 
                and re-downloads all observations from iNaturalist. Use this for a completely new slideshow.<br><br>
                <b>Incremental Update (unchecked):</b> Keeps existing cached data and only identifies 
                observations that have been added to the bioblitz since the last run. This is much faster 
                for daily updates. Previously downloaded photos, maps, and slides are reused where possible. 
                Note: When unchecked, 'Use Incremental Fetch' must be enabled to fetch only new observations.")),
            
            checkboxInput(
              "fetch_all_observations",
              "Fetch All Observations",
              value = TRUE
            ),
            div(class = "help-text", 
                "Uncheck to fetch subset (faster for testing)"),
            
            checkboxInput(
              "cache_observations",
              "Cache Observations",
              value = TRUE
            ),
            div(class = "help-text", 
                "Saves API data for faster reruns"),
            
            checkboxInput(
              "use_incremental_fetch",
              "Use Incremental Fetch",
              value = TRUE
            ),
            div(class = "help-text", 
                "Only fetch NEW observations since last run (much faster for daily updates)")
          ),
          
          box(
            title = "Advanced Options", 
            status = "warning", 
            solidHeader = TRUE, 
            width = 6,
            
            checkboxInput(
              "force_rebuild_base_map",
              "Force Rebuild Base Map",
              value = TRUE
            ),
            
            checkboxInput(
              "force_rebuild_maps",
              "Force Rebuild All Maps",
              value = FALSE
            ),
            
            checkboxInput(
              "force_rebuild_slides",
              "Force Rebuild All Slides",
              value = FALSE
            ),
            
            checkboxInput(
              "skip_osm_overlays",
              "Skip OpenStreetMap Overlays (Faster)",
              value = FALSE
            )
          )
        ),
        
        fluidRow(
          box(
            title = "PDF Output Settings", 
            status = "success", 
            solidHeader = TRUE, 
            width = 6,
            
            checkboxInput(
              "create_pdf",
              "Create PDF Version",
              value = FALSE
            ),
            div(class = "help-text", 
                "Requires Chrome/Chromium. Can be slow for large slideshows."),
            
            numericInput(
              "pdf_size_limit_mb",
              "PDF Size Limit (MB, 0 = No Limit)",
              value = 50,
              min = 0,
              max = 500,
              step = 10
            ),
            div(class = "help-text", 
                "Skip PDF if estimated size exceeds this limit")
          ),
          
          box(
            title = "Random Seed (Reproducibility)", 
            status = "success", 
            solidHeader = TRUE, 
            width = 6,
            
            checkboxInput(
              "use_random_seed",
              "Use Random Selection",
              value = TRUE
            ),
            div(class = "help-text", 
                "Different photos each run. Uncheck to use R's current state."),
            
            numericInput(
              "random_seed",
              "Specific Random Seed (Optional)",
              value = NA,
              min = 1,
              max = 999999
            ),
            div(class = "help-text", 
                "Set a number to reproduce exact same slideshow. Leave blank for random.")
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            solidHeader = TRUE,
            status = "primary",
            actionButton(
              "save_config",
              "Save Configuration",
              icon = icon("save"),
              class = "btn-primary btn-lg",
              width = "200px"
            ),
            actionButton(
              "load_config",
              "Load Configuration",
              icon = icon("upload"),
              class = "btn-default btn-lg",
              width = "200px"
            ),
            div(class = "help-text", style = "margin-top: 10px;",
                "Save/load your settings for future use")
          )
        )
      ),
      
      # ========================================================================
      # RUN & PROGRESS TAB
      # ========================================================================
      tabItem(tabName = "run",
        fluidRow(
          box(
            title = "Generate Slideshow",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            
            actionButton(
              "run_script",
              "Generate Slideshow",
              icon = icon("play"),
              class = "btn-success btn-lg",
              width = "250px"
            ),
            
            actionButton(
              "stop_script",
              "Stop Process",
              icon = icon("stop"),
              class = "btn-danger btn-lg",
              width = "250px"
            ),
            
            hr(),
            
            h4("Current Status:"),
            textOutput("status_text"),
            
            hr(),
            
            h4("Progress Stages:"),
            uiOutput("progress_stages")
          )
        ),
        
        fluidRow(
          infoBoxOutput("obs_count_box", width = 3),
          infoBoxOutput("observer_count_box", width = 3),
          infoBoxOutput("photos_downloaded_box", width = 3),
          infoBoxOutput("maps_created_box", width = 3)
        ),
        
        fluidRow(
          infoBoxOutput("slides_created_box", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Live Progress Log",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            
            verbatimTextOutput("progress_log"),
            
            hr(),
            
            actionButton(
              "refresh_counts",
              "Refresh File Counts",
              icon = icon("sync"),
              class = "btn-info"
            ),
            div(class = "help-text", style = "margin-top: 10px;",
                "Click to manually refresh the file counts if they seem stuck")
          )
        ),
        
        fluidRow(
          box(
            title = "Debugging Information",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            collapsed = TRUE,
            
            verbatimTextOutput("debug_info"),
            
            p("If progress seems stuck:"),
            tags$ul(
              tags$li("Check the live log above for errors"),
              tags$li("Click 'Refresh File Counts' to force an update"),
              tags$li("Look in the output folder directly to see actual files created"),
              tags$li("The script may be working even if counts don't update immediately")
            )
          )
        )
      ),
      
      # ========================================================================
      # OUTPUTS TAB
      # ========================================================================
      tabItem(tabName = "outputs",
        fluidRow(
          box(
            title = "Generated Files",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            
            h4("Output Location:"),
            verbatimTextOutput("output_path"),
            
            hr(),
            
            h4("Available Files:"),
            uiOutput("output_files_ui"),
            
            hr(),
            
            actionButton(
              "open_html",
              "Open Slideshow in Browser",
              icon = icon("external-link-alt"),
              class = "btn-success btn-lg",
              width = "250px"
            ),
            
            actionButton(
              "open_folder",
              "Open Output Folder",
              icon = icon("folder-open"),
              class = "btn-primary btn-lg",
              width = "250px"
            ),
            
            div(class = "help-text", style = "margin-top: 15px;",
                "The slideshow.html file can be opened in any web browser. 
                 All photos, maps, and styling are embedded - the file is self-contained!")
          )
        )
      ),
      
      # ========================================================================
      # HELP TAB
      # ========================================================================
      tabItem(tabName = "help",
        fluidRow(
          box(
            title = "Quick Start Guide",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            
            h4("1. Configure Your Project"),
            p("In the 'Configuration' tab:"),
            tags$ul(
              tags$li("Enter your iNaturalist project slug (required)"),
              tags$li("Set the number of photos for your slideshow"),
              tags$li("Optionally upload a logo and adjust settings")
            ),
            
            h4("2. Set Run Mode"),
            p("Choose your run mode based on your needs:"),
            tags$ul(
              tags$li(tags$b("First time / Full rebuild:"), " Keep 'Fresh Run' checked"),
              tags$li(tags$b("Daily updates:"), " Uncheck 'Fresh Run' and enable 'Use Incremental Fetch'"),
              tags$li(tags$b("Testing:"), " Uncheck 'Fetch All Observations' for faster subset testing")
            ),
            
            h4("3. Generate Slideshow"),
            p("Go to 'Run & Progress' tab and click 'Generate Slideshow'. The script will:"),
            tags$ul(
              tags$li("Fetch observations from iNaturalist"),
              tags$li("Download photos"),
              tags$li("Create maps for each observation"),
              tags$li("Compose slide images"),
              tags$li("Generate an interactive HTML slideshow")
            ),
            
            h4("4. View Your Slideshow"),
            p("Once complete, go to the 'Outputs' tab to:"),
            tags$ul(
              tags$li("Open the HTML slideshow in your browser"),
              tags$li("Download the PDF version (if enabled)"),
              tags$li("Access individual photos and maps")
            ),
            
            hr(),
            
            h4("Tips & Tricks"),
            tags$ul(
              tags$li(tags$b("First Run:"), " Use 'Fresh Run' and set a small number of photos (e.g., 3-5) to test"),
              tags$li(tags$b("Daily Updates:"), " Uncheck 'Fresh Run' and enable 'Use Incremental Fetch' for faster updates"),
              tags$li(tags$b("Large Projects:"), " Disable PDF creation or increase size limit for 100+ photos"),
              tags$li(tags$b("Reproducibility:"), " Set a specific random seed to generate the same slideshow again"),
              tags$li(tags$b("Performance:"), " Enable 'Skip OpenStreetMap Overlays' for faster processing")
            ),
            
            hr(),
            
            h4("Required R Packages"),
            p("This app requires the following packages. They will be installed automatically if missing:"),
            tags$code("httr2, jsonlite, dplyr, purrr, tidyr, stringr, lubridate, 
                      janitor, glue, readr, tibble, ggplot2, sf, maptiles, terra, 
                      tidyterra, osmdata, magick, ggspatial, quarto, pagedown")
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
  
  # Reactive values to store state
  rv <- reactiveValues(
    running = FALSE,
    log = "",
    status = "Ready",
    obs_count = 0,
    observer_count = 0,
    photos_downloaded = 0,
    maps_created = 0,
    slides_created = 0,
    # Track baseline counts at start of run
    initial_photos = 0,
    initial_maps = 0,
    initial_slides = 0,
    output_dir = NULL,
    progress_file = NULL,
    start_time = NULL,
    pid_file = NULL  # Track process ID file for stopping
  )
  
  # Reactive timer for monitoring progress (checks every 300ms for responsive updates)
  progress_timer <- reactiveTimer(300)
  
  # Helper function to count files in output directories
  count_output_files <- function(output_dir) {
    if (is.null(output_dir) || !dir.exists(output_dir)) {
      return(list(photos = 0, maps = 0, slides = 0))
    }
    
    photos_dir <- file.path(output_dir, "photos")
    maps_dir <- file.path(output_dir, "maps")
    slides_dir <- file.path(output_dir, "slides")
    
    photos_count <- if (dir.exists(photos_dir)) {
      length(list.files(photos_dir, pattern = "\\.(jpg|jpeg|png)$", ignore.case = TRUE))
    } else {
      0
    }
    
    maps_count <- if (dir.exists(maps_dir)) {
      length(list.files(maps_dir, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE))
    } else {
      0
    }
    
    slides_count <- if (dir.exists(slides_dir)) {
      length(list.files(slides_dir, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE))
    } else {
      0
    }
    
    list(photos = photos_count, maps = maps_count, slides = slides_count)
  }
  
  # Helper function to get cached observation info
  get_cached_obs_info <- function(output_dir) {
    if (is.null(output_dir) || !dir.exists(output_dir)) {
      return(list(obs_count = 0, observer_count = 0))
    }
    
    obs_cache_file <- file.path(output_dir, "observations_cache.rds")
    
    if (file.exists(obs_cache_file)) {
      tryCatch({
        cached_obs <- readRDS(obs_cache_file)
        obs_count <- nrow(cached_obs)
        # Exclude NA values and empty strings when counting unique observers
        valid_observers <- cached_obs$observer[!is.na(cached_obs$observer) & nchar(trimws(cached_obs$observer)) > 0]
        observer_count <- length(unique(valid_observers))
        return(list(obs_count = obs_count, observer_count = observer_count))
      }, error = function(e) {
        return(list(obs_count = 0, observer_count = 0))
      })
    }
    
    return(list(obs_count = 0, observer_count = 0))
  }
  
  # Monitor progress - IMPROVED to track incremental changes
  observe({
    progress_timer()  # Trigger every 300ms
    
    if (rv$running && !is.null(rv$output_dir)) {
      
      # Read console log file for live output
      log_file <- file.path(rv$output_dir, "console_log.txt")
      if (file.exists(log_file)) {
        tryCatch({
          log_content <- readLines(log_file, warn = FALSE)
          rv$log <- paste(log_content, collapse = "\n")
          
          # Check if script completed
          if (any(grepl("SCRIPT COMPLETED SUCCESSFULLY|ERROR OCCURRED", log_content))) {
            rv$running <- FALSE
            if (any(grepl("SCRIPT COMPLETED SUCCESSFULLY", log_content))) {
              rv$status <- "Complete!"
              showNotification("Slideshow generated successfully!", type = "message", duration = 10)
            } else {
              rv$status <- "Error occurred"
              showNotification("An error occurred. Check the log for details.", type = "error", duration = 10)
            }
          }
          
          # Extract observation count from log
          obs_lines <- grep("Total observations:", log_content, value = TRUE)
          if (length(obs_lines) > 0) {
            obs_match <- regmatches(obs_lines[length(obs_lines)], regexpr("[0-9]+", obs_lines[length(obs_lines)]))
            if (length(obs_match) > 0) {
              rv$obs_count <- as.integer(obs_match[1])
            }
          }
          
          # Extract observer count from log (if it's printed)
          # Look specifically for "Unique observers: <number>" format (must be at start of line, ends after number)
          observer_lines <- grep("^\\s*Unique observers:\\s*([0-9]+)\\s*$", log_content, value = TRUE, ignore.case = TRUE, perl = TRUE)
          if (length(observer_lines) > 0) {
            # Extract just the number after "Unique observers:"
            last_line <- observer_lines[length(observer_lines)]
            obs_match <- regmatches(last_line, regexpr("[0-9]+", last_line))
            if (length(obs_match) > 0) {
              new_count <- as.integer(obs_match[1])
              # SAFEGUARD: Only update if new count is higher (prevents false decreases)
              if (new_count > rv$observer_count) {
                rv$observer_count <- new_count
              }
            }
          }
        }, error = function(e) {})
      } else {
        # Log file doesn't exist yet
        elapsed <- as.numeric(Sys.time() - rv$start_time)
        if (elapsed < 30) {
          rv$log <- paste0("Waiting for background process to start...\n",
                          "Elapsed time: ", round(elapsed, 1), " seconds")
        } else {
          rv$log <- "Process may have failed to start. Check R console for errors."
          rv$running <- FALSE
          rv$status <- "Failed to start"
        }
      }
      
      # Count actual files in directories and calculate INCREMENTAL counts
      file_counts <- count_output_files(rv$output_dir)
      
      # Update counts showing only files created in THIS run
      if (file_counts$photos != rv$photos_downloaded + rv$initial_photos) {
        rv$photos_downloaded <- max(0, file_counts$photos - rv$initial_photos)
      }
      if (file_counts$maps != rv$maps_created + rv$initial_maps) {
        rv$maps_created <- max(0, file_counts$maps - rv$initial_maps)
      }
      if (file_counts$slides != rv$slides_created + rv$initial_slides) {
        rv$slides_created <- max(0, file_counts$slides - rv$initial_slides)
      }
      
      # Update status based on activity
      if (!grepl("Complete|Error", rv$status)) {
        if (rv$slides_created > 0) {
          rv$status <- paste0("Composing slides (", rv$slides_created, " created this run)...")
        } else if (rv$maps_created > 0) {
          rv$status <- paste0("Creating maps (", rv$maps_created, " created this run)...")
        } else if (rv$photos_downloaded > 0) {
          rv$status <- paste0("Downloading photos (", rv$photos_downloaded, " downloaded this run)...")
        } else if (rv$obs_count > 0) {
          # Observations found but photos not downloading yet = still fetching data
          rv$status <- paste0("Fetching observation data (", rv$obs_count, " found)...")
        } else if (file.exists(log_file) && file.size(log_file) > 100) {
          rv$status <- "Processing..."
        }
      }
    } else if (!is.null(rv$output_dir) && !rv$running) {
      # After completion, do final count
      file_counts <- count_output_files(rv$output_dir)
      rv$photos_downloaded <- max(0, file_counts$photos - rv$initial_photos)
      rv$maps_created <- max(0, file_counts$maps - rv$initial_maps)
      rv$slides_created <- max(0, file_counts$slides - rv$initial_slides)
    }
  })
  
  # Check script status reactively
  script_exists <- reactive({
    file.exists(input$script_path)
  })
  
  # Display script status
  output$script_status_ui <- renderUI({
    if (script_exists()) {
      div(
        style = "color: green; font-weight: bold; margin-top: 10px;",
        icon("check-circle"), " Script found: ", input$script_path
      )
    } else {
      div(
        style = "color: red; font-weight: bold; margin-top: 10px;",
        icon("exclamation-triangle"), " Script NOT found: ", input$script_path,
        br(),
        "Current directory: ", getwd(),
        br(),
        "Please ensure the script file is in the same folder as this app."
      )
    }
  })
  
  # Save configuration
  observeEvent(input$save_config, {
    config <- list(
      script_path = input$script_path,
      project_slug = input$project_slug,
      n_photos = input$n_photos,
      hq_lat = input$hq_lat,
      hq_lon = input$hq_lon,
      max_obs_per_observer_pct = input$max_obs_per_observer_pct,
      max_obs_per_observer_abs = input$max_obs_per_observer_abs,
      max_plants_pct = input$max_plants_pct,
      base_map_zoom = input$base_map_zoom,
      buffer_km = input$buffer_km,
      default_dist_m = input$default_dist_m,
      auto_advance_ms = input$auto_advance_ms,
      auto_slide_stoppable = input$auto_slide_stoppable,
      slideshow_loop = input$slideshow_loop,
      max_collage = input$max_collage,
      create_pdf = input$create_pdf,
      pdf_size_limit_mb = input$pdf_size_limit_mb,
      use_random_seed = input$use_random_seed,
      random_seed = input$random_seed,
      out_dir = input$out_dir,
      fresh_run = input$fresh_run,
      fetch_all_observations = input$fetch_all_observations,
      cache_observations = input$cache_observations,
      use_incremental_fetch = input$use_incremental_fetch,
      force_rebuild_base_map = input$force_rebuild_base_map,
      force_rebuild_maps = input$force_rebuild_maps,
      force_rebuild_slides = input$force_rebuild_slides,
      skip_osm_overlays = input$skip_osm_overlays
    )
    
    saveRDS(config, "bioblitz_config.rds")
    showNotification("Configuration saved!", type = "message", duration = 3)
  })
  
  # Load configuration
  observeEvent(input$load_config, {
    if (file.exists("bioblitz_config.rds")) {
      config <- readRDS("bioblitz_config.rds")
      
      if (!is.null(config$script_path)) {
        updateTextInput(session, "script_path", value = config$script_path)
      }
      updateTextInput(session, "project_slug", value = config$project_slug)
      updateNumericInput(session, "n_photos", value = config$n_photos)
      updateNumericInput(session, "hq_lat", value = config$hq_lat)
      updateNumericInput(session, "hq_lon", value = config$hq_lon)
      updateSliderInput(session, "max_obs_per_observer_pct", value = config$max_obs_per_observer_pct)
      updateNumericInput(session, "max_obs_per_observer_abs", value = config$max_obs_per_observer_abs)
      updateSliderInput(session, "max_plants_pct", value = config$max_plants_pct)
      updateNumericInput(session, "base_map_zoom", value = config$base_map_zoom)
      updateNumericInput(session, "buffer_km", value = config$buffer_km)
      updateNumericInput(session, "default_dist_m", value = config$default_dist_m)
      updateNumericInput(session, "auto_advance_ms", value = config$auto_advance_ms)
      updateCheckboxInput(session, "auto_slide_stoppable", value = config$auto_slide_stoppable)
      updateCheckboxInput(session, "slideshow_loop", value = config$slideshow_loop)
      updateNumericInput(session, "max_collage", value = config$max_collage)
      updateCheckboxInput(session, "create_pdf", value = config$create_pdf)
      updateNumericInput(session, "pdf_size_limit_mb", value = config$pdf_size_limit_mb)
      updateCheckboxInput(session, "use_random_seed", value = config$use_random_seed)
      updateNumericInput(session, "random_seed", value = config$random_seed)
      updateTextInput(session, "out_dir", value = config$out_dir)
      updateCheckboxInput(session, "fresh_run", value = config$fresh_run)
      updateCheckboxInput(session, "fetch_all_observations", value = config$fetch_all_observations)
      updateCheckboxInput(session, "cache_observations", value = config$cache_observations)
      updateCheckboxInput(session, "use_incremental_fetch", value = config$use_incremental_fetch)
      updateCheckboxInput(session, "force_rebuild_base_map", value = config$force_rebuild_base_map)
      updateCheckboxInput(session, "force_rebuild_maps", value = config$force_rebuild_maps)
      updateCheckboxInput(session, "force_rebuild_slides", value = config$force_rebuild_slides)
      updateCheckboxInput(session, "skip_osm_overlays", value = config$skip_osm_overlays)
      
      showNotification("Configuration loaded!", type = "message", duration = 3)
    } else {
      showNotification("No saved configuration found.", type = "warning", duration = 3)
    }
  })
  
  # Run the slideshow generation script
  observeEvent(input$run_script, {
    
    # GUARD: Prevent starting a new process while one is already running
    if (rv$running) {
      showNotification(
        "A slideshow is already being generated. Please wait for it to complete or stop it first.",
        type = "warning",
        duration = 5
      )
      return()
    }
    
    # Check if original script exists
    script_path <- input$script_path
    if (!file.exists(script_path)) {
      showNotification(
        paste0("ERROR: Cannot find '", script_path, "'.\n",
               "Please ensure the script is in the same folder as this Shiny app.\n",
               "Current directory: ", getwd()),
        type = "error",
        duration = 10
      )
      rv$log <- paste0("ERROR: Script not found!\n",
                       "Looking for: ", normalizePath(script_path, mustWork = FALSE), "\n",
                       "Current directory: ", getwd(), "\n",
                       "Files in directory:\n",
                       paste(list.files(pattern = "*.R"), collapse = "\n"))
      rv$status <- "Error: Script not found"
      return()
    }
    
    # Validation
    if (nchar(input$project_slug) == 0) {
      showNotification("Please enter a project slug!", type = "error", duration = 5)
      return()
    }
    
    if (input$n_photos < 1) {
      showNotification("Number of photos must be at least 1!", type = "error", duration = 5)
      return()
    }
    
    rv$running <- TRUE
    rv$log <- "Initializing slideshow generation...\n\n"
    rv$status <- "Initializing..."
    rv$start_time <- Sys.time()
    
    # Build the output directory path
    output_dir_name <- input$out_dir
    output_base <- file.path(getwd(), "outputs", output_dir_name)
    dir.create(output_base, recursive = TRUE, showWarnings = FALSE)
    output_base_norm <- normalizePath(output_base, winslash = "/", mustWork = FALSE)
    rv$output_dir <- output_base_norm
    
    # IMPROVEMENT: Get baseline file counts and cached observation info
    if (!input$fresh_run) {
      # When not doing a fresh run, get current file counts to track incremental changes
      baseline_counts <- count_output_files(rv$output_dir)
      rv$initial_photos <- baseline_counts$photos
      rv$initial_maps <- baseline_counts$maps
      rv$initial_slides <- baseline_counts$slides
      
      # Get cached observation info
      cached_info <- get_cached_obs_info(rv$output_dir)
      rv$obs_count <- cached_info$obs_count
      rv$observer_count <- cached_info$observer_count
      
      cat("Incremental run - Baseline counts:\n")
      cat("  Photos:", rv$initial_photos, "\n")
      cat("  Maps:", rv$initial_maps, "\n")
      cat("  Slides:", rv$initial_slides, "\n")
      cat("  Cached observations:", rv$obs_count, "\n")
      cat("  Cached observers:", rv$observer_count, "\n")
    } else {
      # Fresh run - start from zero
      rv$initial_photos <- 0
      rv$initial_maps <- 0
      rv$initial_slides <- 0
      rv$obs_count <- 0
      rv$observer_count <- 0
    }
    
    # Reset current run counts
    rv$photos_downloaded <- 0
    rv$maps_created <- 0
    rv$slides_created <- 0
    
    # Create log file in the normalized path
    log_file <- file.path(output_base_norm, "console_log.txt")
    progress_file <- file.path(output_base_norm, "progress.txt")
    
    # Initialize files
    writeLines("=== Slideshow Generation Started ===\n", log_file)
    writeLines("STATUS:Initializing...", progress_file)
    
    showNotification("Starting slideshow generation. Watch live progress below...", 
                    type = "message", duration = 5)
    
    # Handle logo upload
    logo_file <- ""
    if (!is.null(input$bioblitz_logo)) {
      logo_dest <- file.path(getwd(), "bioblitz_logo.jpg")
      file.copy(input$bioblitz_logo$datapath, logo_dest, overwrite = TRUE)
      logo_file <- "bioblitz_logo.jpg"
    }
    
    # Get paths
    working_dir <- getwd()
    script_full_path <- normalizePath(script_path, winslash = "/")
    log_file_path <- normalizePath(log_file, winslash = "/", mustWork = FALSE)
    relative_out_dir <- file.path("outputs", output_dir_name)
    
    # Helper functions to format values for sprintf
    fmt_bool <- function(x) if(x) "TRUE" else "FALSE"
    fmt_seed <- function(x) if(is.na(x)) "NULL" else as.character(x)
    
    # Create wrapper script IN THE NORMALIZED OUTPUT DIRECTORY
    wrapper_script <- file.path(output_base_norm, "run_wrapper.R")
    
    # Build wrapper script content
    wrapper_content <- paste0('
# Set working directory to Shiny app directory
setwd("', working_dir, '")

# Setup paths
log_file <- "', log_file_path, '"
progress_file <- "', normalizePath(progress_file, winslash = "/", mustWork = FALSE), '"
script_path <- "', script_full_path, '"
pid_file <- "', normalizePath(file.path(rv$output_dir, "process.pid"), winslash = "/", mustWork = FALSE), '"

# Write PID file so Shiny can stop this process
writeLines(as.character(Sys.getpid()), pid_file)

# Initialize progress file
writeLines("STATUS:Initializing...", progress_file)

cat("=== Slideshow Generation Started ===\\n")
cat("PID:", Sys.getpid(), "\\n")
cat("Working directory:", getwd(), "\\n\\n")

# Helper to append to log file
write_log <- function(text) {
  write(text, file = log_file, append = TRUE)
}

# Helper to append to progress file
write_progress <- function(text) {
  write(text, file = progress_file, append = TRUE)
}

write_log("=== Slideshow Generation Started ===")
write_log(paste("Working directory:", getwd()))
write_log("")

# Create environment for script execution
script_env <- new.env(parent = .GlobalEnv)

# Helper to create an active binding that ignores reassignment attempts
make_locked_param <- function(env, name, value) {
  makeActiveBinding(name, local({
    val <- value
    function(v) {
      if (missing(v)) {
        val  # Return our value when read
      } else {
        # Silently ignore assignment attempts - don\'t even warn
        val  # Still return our value
      }
    }
  }), env)
}

# Create active bindings for all parameters
make_locked_param(script_env, "project_slug", "', input$project_slug, '")
make_locked_param(script_env, "n_photos", ', input$n_photos, ')
make_locked_param(script_env, "bioblitz_logo", "', logo_file, '")
make_locked_param(script_env, "hq_lon", ', input$hq_lon, ')
make_locked_param(script_env, "hq_lat", ', input$hq_lat, ')
make_locked_param(script_env, "max_obs_per_observer_pct", ', input$max_obs_per_observer_pct / 100, ')
make_locked_param(script_env, "max_obs_per_observer_abs", ', input$max_obs_per_observer_abs, ')
make_locked_param(script_env, "max_plants_pct", ', input$max_plants_pct / 100, ')
make_locked_param(script_env, "use_random_seed", ', fmt_bool(input$use_random_seed), ')
make_locked_param(script_env, "random_seed", ', fmt_seed(input$random_seed), ')
make_locked_param(script_env, "fresh_run", ', fmt_bool(input$fresh_run), ')
make_locked_param(script_env, "fetch_all_observations", ', fmt_bool(input$fetch_all_observations), ')
make_locked_param(script_env, "cache_observations", ', fmt_bool(input$cache_observations), ')
make_locked_param(script_env, "use_incremental_fetch", ', fmt_bool(input$use_incremental_fetch), ')
make_locked_param(script_env, "force_rebuild_base_map", ', fmt_bool(input$force_rebuild_base_map), ')
make_locked_param(script_env, "force_rebuild_maps", ', fmt_bool(input$force_rebuild_maps), ')
make_locked_param(script_env, "force_rebuild_slides", ', fmt_bool(input$force_rebuild_slides), ')
make_locked_param(script_env, "skip_osm_overlays", ', fmt_bool(input$skip_osm_overlays), ')
make_locked_param(script_env, "base_map_zoom", ', input$base_map_zoom, ')
make_locked_param(script_env, "buffer_km", ', input$buffer_km, ')
make_locked_param(script_env, "default_dist_m", ', input$default_dist_m, ')
make_locked_param(script_env, "auto_advance_ms", ', input$auto_advance_ms * 1000, ')
make_locked_param(script_env, "auto_slide_stoppable", ', fmt_bool(input$auto_slide_stoppable), ')
make_locked_param(script_env, "slideshow_loop", ', fmt_bool(input$slideshow_loop), ')
make_locked_param(script_env, "max_collage", ', input$max_collage, ')
make_locked_param(script_env, "create_pdf", ', fmt_bool(input$create_pdf), ')
make_locked_param(script_env, "pdf_size_limit_mb", ', input$pdf_size_limit_mb, ')
make_locked_param(script_env, "out_dir", "', relative_out_dir, '")
make_locked_param(script_env, "diagnostic_mode", TRUE)

msg <- paste0("Active parameter bindings created\\n",
              "  Project: ", script_env$project_slug, "\\n",
              "  Photos: ", script_env$n_photos, "\\n",
              "  Output: ", script_env$out_dir, "\\n")
cat(msg)
write_log(msg)

cat("Sourcing script (verbose output filtered)\\n\\n")
write_log("Sourcing script (verbose output filtered)")
write_log("")

# Patterns to filter out (regex)
filter_patterns <- c(
  "^Attaching package:",
  "^The following object",
  "^Linking to (GEOS|ImageMagick|GDAL|PROJ)",
  "^terra [0-9]",
  "^Enabled features:",
  "^Disabled features:",
  "^Data \\\\(c\\\\) OpenStreetMap",
  "resampled to [0-9]+ cells",
  "Coordinate system already present",
  "Adding new coordinate system",
  "^pandoc\\\\s*$",
  "^  (to|output-file|standalone|wrap|default-image|html-math|slide-level|css):",
  "^  +method:",
  "^  +url:",
  "^metadata\\\\s*$",
  "^  (link-citations|width|height|margin|center|navigationMode|controls|hash|history|fragment|transition|background|pdfSeparate|lang|auto-|title|theme|slide|loop):",
  "^There were [0-9]+ warnings"
)

# Function to check if line should be filtered
should_filter <- function(line) {
  line <- trimws(line)
  if (nchar(line) == 0) return(FALSE)
  for (pattern in filter_patterns) {
    if (grepl(pattern, line, perl = TRUE)) {
      return(TRUE)
    }
  }
  return(FALSE)
}

# Function to extract and update progress
update_progress <- function(line) {
  line <- trimws(line)
  
  # Extract observation count
  if (grepl("Total observations:", line, fixed = TRUE)) {
    obs_match <- regmatches(line, regexpr("[0-9]+", line))
    if (length(obs_match) > 0) {
      write_progress(paste0("OBS_COUNT:", obs_match[1]))
    }
  }
  
  # Extract observer count (IMPROVEMENT: track unique observers)
  if (grepl("unique observers", line, ignore.case = TRUE)) {
    obs_match <- regmatches(line, regexpr("[0-9]+", line))
    if (length(obs_match) > 0) {
      write_progress(paste0("OBSERVER_COUNT:", obs_match[1]))
    }
  }
  
  # Extract current status from === markers
  if (grepl("^===", line)) {
    status <- gsub("^=== | ===$", "", line)
    status <- trimws(status)
    if (nchar(status) > 0) {
      write_progress(paste0("STATUS:", status))
    }
  }
  
  # Count photos
  if (grepl("Ready: [0-9]+ photos", line)) {
    photo_match <- regmatches(line, regexpr("[0-9]+", line))
    if (length(photo_match) > 0) {
      write_progress(paste0("PHOTOS:", photo_match[1]))
    }
  }
  
  # Count maps
  if (grepl("Maps created: [0-9]+ successful", line)) {
    map_match <- regmatches(line, regexpr("[0-9]+", line))
    if (length(map_match) > 0) {
      write_progress(paste0("MAPS:", map_match[1]))
    }
  }
  
  # Count slides
  if (grepl("Created [0-9]+ slides", line)) {
    slide_match <- regmatches(line, regexpr("[0-9]+", line))
    if (length(slide_match) > 0) {
      write_progress(paste0("SLIDES:", slide_match[1]))
    }
  }
}

# Override cat() in script environment to filter and process in real-time
script_env$cat <- function(..., sep = " ", fill = FALSE, labels = NULL, append = FALSE) {
  # Capture the text
  text <- paste(..., sep = sep, collapse = "")
  lines <- strsplit(text, "\\n")[[1]]
  
  for (line in lines) {
    # Extract progress info
    update_progress(line)
    
    # Write to log if not filtered - REOPEN FILE EACH TIME for immediate write
    if (!should_filter(line)) {
      # Use write with append - this forces immediate disk write
      write(line, file = log_file, append = TRUE)
    }
  }
}

# Suppress package startup messages by overriding library()
script_env$library <- function(..., character.only = FALSE) {
  suppressPackageStartupMessages(
    base::library(..., character.only = character.only)
  )
}

# Run script with real-time output processing
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
  
  # Print traceback if available
  tb <- sys.calls()
  if (length(tb) > 0) {
    write_log("")
    write_log("Call stack:")
    for (i in seq_along(tb)) {
      write_log(paste(i, ":", deparse(tb[[i]])[1]))
    }
  }
})

# Clean up PID file
if (file.exists(pid_file)) file.remove(pid_file)
cat("Log file closed\\n")
')
    
    writeLines(wrapper_content, wrapper_script)
    
    # Store PID file location
    rv$pid_file <- file.path(rv$output_dir, "process.pid")
    
    cat("Wrapper script created at:", wrapper_script, "\n")
    cat("Working directory:", working_dir, "\n")
    cat("Output will be in (absolute):", rv$output_dir, "\n")
    cat("Script will use (relative):", relative_out_dir, "\n")
    cat("Both should resolve to:", file.path(working_dir, relative_out_dir), "\n")
    
    # Run script in background using system command
    wrapper_full_path <- normalizePath(wrapper_script, winslash = "/")
    
    if (.Platform$OS.type == "windows") {
      cmd <- sprintf('Rscript "%s"', wrapper_full_path)
      cat("Running command:", cmd, "\n")
      # FIXED: Set invisible = TRUE to hide the command prompt window
      result <- system(cmd, wait = FALSE, invisible = TRUE)
    } else {
      cmd <- sprintf('Rscript "%s" > /dev/null 2>&1 &', wrapper_full_path)
      cat("Running command:", cmd, "\n")
      result <- system(cmd)
    }
    
    # FIXED: Check if command execution succeeded
    if (!is.null(result) && result != 0) {
      rv$running <- FALSE
      rv$status <- "Failed to start"
      showNotification(
        paste0("Failed to start background process.\n",
               "Error code: ", result, "\n",
               "Please check that Rscript is installed and in your PATH."),
        type = "error",
        duration = 10
      )
      return()
    }
    
    Sys.sleep(1)  # Give it a moment to start
    
    # Verify log file was created (indicates script started)
    if (!file.exists(log_file)) {
      rv$running <- FALSE
      rv$status <- "Failed to start - log file not created"
      showNotification(
        paste0("Script may have failed to start.\n",
               "Log file not found: ", log_file),
        type = "warning",
        duration = 10
      )
    }
    
    rv$status <- "Running in background..."
    cat("Background process started\n")
  })
  
  # Stop button
  observeEvent(input$stop_script, {
    if (!rv$running) {
      showNotification("No process is currently running.", type = "warning", duration = 3)
      return()
    }
    
    # Try to kill the background process
    killed <- FALSE
    
    if (!is.null(rv$pid_file) && file.exists(rv$pid_file)) {
      tryCatch({
        pid <- readLines(rv$pid_file, warn = FALSE)[1]
        
        # Validate PID is numeric and not empty
        if (is.na(pid) || nchar(trimws(pid)) == 0 || !grepl("^[0-9]+$", pid)) {
          cat("Invalid PID in file:", pid, "\n")
          killed <- FALSE
        } else if (.Platform$OS.type == "windows") {
          # Windows: use taskkill
          result <- system(sprintf('taskkill /F /PID %s', pid), intern = FALSE, ignore.stdout = TRUE, ignore.stderr = TRUE)
          killed <- (result == 0)
        } else {
          # Unix/Linux/Mac: use kill
          result <- system(sprintf('kill -9 %s', pid), intern = FALSE, ignore.stdout = TRUE, ignore.stderr = TRUE)
          killed <- (result == 0)
        }
        
        # Clean up PID file
        if (file.exists(rv$pid_file)) {
          file.remove(rv$pid_file)
        }
      }, error = function(e) {
        cat("Error killing process:", conditionMessage(e), "\n")
      })
    }
    
    rv$running <- FALSE
    rv$status <- if (killed) "Stopped by user" else "Stop requested (process may still be running)"
    
    showNotification(
      if (killed) "Process stopped successfully" else "Stop signal sent (background process may take a moment to terminate)",
      type = if (killed) "message" else "warning",
      duration = 5
    )
  })
  
  # Status text
  output$status_text <- renderText({
    rv$status
  })
  
  # Progress log
  output$progress_log <- renderText({
    rv$log
  })
  
  # Progress stages checklist
  output$progress_stages <- renderUI({
    if (!rv$running && nchar(rv$log) < 50) {
      return(p("Click 'Generate Slideshow' to begin.", style = "color: #999;"))
    }
    
    # Determine which stages are complete based on log content and file counts
    log_text <- rv$log
    
    stages <- list(
      list(name = "Initializing", complete = nchar(log_text) > 0),
      list(name = "Fetching observations from iNaturalist", complete = grepl("observations|Fetched", log_text)),
      list(name = "Downloading photos", complete = rv$photos_downloaded > 0 || grepl("Downloading|photo", log_text)),
      list(name = "Creating maps", complete = rv$maps_created > 0 || grepl("Creating maps|satellite", log_text)),
      list(name = "Composing slides", complete = rv$slides_created > 0 || grepl("Composing|slide", log_text)),
      list(name = "Building slideshow", complete = grepl("QMD|slideshow|Rendering", log_text)),
      list(name = "Complete!", complete = grepl("COMPLETE|SCRIPT COMPLETED SUCCESSFULLY", log_text))
    )
    
    stage_html <- lapply(stages, function(stage) {
      if (stage$complete) {
        tags$div(
          style = "margin: 5px 0; color: green;",
          icon("check-circle"), " ", tags$b(stage$name)
        )
      } else {
        tags$div(
          style = "margin: 5px 0; color: #999;",
          icon("circle"), " ", stage$name
        )
      }
    })
    
    tagList(stage_html)
  })
  
  # Info boxes - with colorful emojis in labels
  output$obs_count_box <- renderInfoBox({
    infoBox(
      "🔭 Total Observations",
      rv$obs_count,
      icon = shiny::icon("circle", class = "hidden-icon"),
      color = "blue"
    )
  })
  
  # NEW: Observer count box
  output$observer_count_box <- renderInfoBox({
    infoBox(
      "👥 Total Unique Observers",
      rv$observer_count,
      icon = shiny::icon("circle", class = "hidden-icon"),
      color = "aqua"
    )
  })
  
  output$photos_downloaded_box <- renderInfoBox({
    infoBox(
      "📷 Photos (This Run)",
      rv$photos_downloaded,
      icon = shiny::icon("circle", class = "hidden-icon"),
      color = "green"
    )
  })
  
  output$maps_created_box <- renderInfoBox({
    infoBox(
      "🗺️ Maps (This Run)",
      rv$maps_created,
      icon = shiny::icon("circle", class = "hidden-icon"),
      color = "yellow"
    )
  })
  
  output$slides_created_box <- renderInfoBox({
    infoBox(
      "🎬 Slides (This Run)",
      rv$slides_created,
      icon = shiny::icon("circle", class = "hidden-icon"),
      color = "purple"
    )
  })
  
  # Output files UI
  output$output_files_ui <- renderUI({
    
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      return(p("No outputs generated yet. Run the slideshow generator first."))
    }
    
    files <- list.files(rv$output_dir, full.names = FALSE)
    
    if (length(files) == 0) {
      return(p("No files found in output directory."))
    }
    
    # Key files to highlight
    html_file <- "slideshow.html"
    pdf_file <- "slideshow.pdf"
    collage_file <- "collage.png"
    
    file_list <- tags$ul()
    
    if (html_file %in% files) {
      file_list <- tagAppendChild(file_list, 
        tags$li(tags$b(html_file), " - Main slideshow (open in browser)"))
    }
    
    if (pdf_file %in% files) {
      file_list <- tagAppendChild(file_list,
        tags$li(tags$b(pdf_file), " - PDF version"))
    }
    
    if (collage_file %in% files) {
      file_list <- tagAppendChild(file_list,
        tags$li(tags$b(collage_file), " - Photo collage"))
    }
    
    file_list <- tagAppendChild(file_list,
      tags$li(paste("Additional files:", length(files), "total")))
    
    return(file_list)
  })
  
  # Output path
  output$output_path <- renderText({
    if (is.null(rv$output_dir)) {
      "Not yet generated"
    } else {
      normalizePath(rv$output_dir, mustWork = FALSE)
    }
  })
  
  # Debug info output
  output$debug_info <- renderText({
    if (is.null(rv$output_dir)) {
      "No slideshow generated yet."
    } else {
      info <- paste0(
        "Monitoring paths:\n",
        "  Output dir: ", rv$output_dir, "\n",
        "  Exists: ", dir.exists(rv$output_dir), "\n\n"
      )
      
      photos_dir <- file.path(rv$output_dir, "photos")
      maps_dir <- file.path(rv$output_dir, "maps")
      slides_dir <- file.path(rv$output_dir, "slides")
      
      info <- paste0(info,
        "  Photos dir: ", photos_dir, "\n",
        "    Exists: ", dir.exists(photos_dir), "\n"
      )
      
      if (dir.exists(photos_dir)) {
        total_photos <- length(list.files(photos_dir, pattern = "\\.(jpg|jpeg|png)$", ignore.case = TRUE))
        info <- paste0(info, "    Total files: ", total_photos, 
                      " (Baseline: ", rv$initial_photos, ", New: ", rv$photos_downloaded, ")\n")
      }
      
      info <- paste0(info,
        "  Maps dir: ", maps_dir, "\n",
        "    Exists: ", dir.exists(maps_dir), "\n"
      )
      
      if (dir.exists(maps_dir)) {
        total_maps <- length(list.files(maps_dir, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE))
        info <- paste0(info, "    Total files: ", total_maps,
                      " (Baseline: ", rv$initial_maps, ", New: ", rv$maps_created, ")\n")
      }
      
      info <- paste0(info,
        "  Slides dir: ", slides_dir, "\n",
        "    Exists: ", dir.exists(slides_dir), "\n"
      )
      
      if (dir.exists(slides_dir)) {
        total_slides <- length(list.files(slides_dir, pattern = "\\.(png|jpg|jpeg)$", ignore.case = TRUE))
        info <- paste0(info, "    Total files: ", total_slides,
                      " (Baseline: ", rv$initial_slides, ", New: ", rv$slides_created, ")\n")
      }
      
      info
    }
  })
  
  # Refresh counts button
  observeEvent(input$refresh_counts, {
    if (is.null(rv$output_dir)) {
      showNotification("No output directory set. Generate a slideshow first.", 
                      type = "warning", duration = 5)
      return()
    }
    
    if (!dir.exists(rv$output_dir)) {
      showNotification(
        paste0("Output directory not found: ", rv$output_dir,
               "\nCheck the Debugging Info section below for details."),
        type = "error", duration = 10
      )
      return()
    }
    
    # Use helper function to count files
    file_counts <- count_output_files(rv$output_dir)
    
    # Check if any directories exist (at least one count > 0)
    if (file_counts$photos > 0 || file_counts$maps > 0 || file_counts$slides > 0 ||
        dir.exists(file.path(rv$output_dir, "photos")) ||
        dir.exists(file.path(rv$output_dir, "maps")) ||
        dir.exists(file.path(rv$output_dir, "slides"))) {
      
      # Update with incremental counts
      rv$photos_downloaded <- max(0, file_counts$photos - rv$initial_photos)
      rv$maps_created <- max(0, file_counts$maps - rv$initial_maps)
      rv$slides_created <- max(0, file_counts$slides - rv$initial_slides)
      
      showNotification(
        paste0("Counts refreshed!\nPhotos (this run): ", rv$photos_downloaded, 
               " Maps (this run): ", rv$maps_created, " Slides (this run): ", rv$slides_created),
        type = "message", duration = 5
      )
    } else {
      showNotification(
        "No subdirectories found yet. Script may still be initializing.",
        type = "warning", duration = 5
      )
    }
  })
  
  # Open HTML button
  observeEvent(input$open_html, {
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      showNotification("No output directory found. Generate slideshow first.", 
                      type = "warning", duration = 5)
      return()
    }
    
    html_file <- file.path(rv$output_dir, "slideshow.html")
    
    if (!file.exists(html_file)) {
      showNotification(paste0("HTML file not found at: ", html_file, 
                             "\nPlease wait for slideshow to complete."), 
                      type = "warning", duration = 5)
      return()
    }
    
    # Normalize path for the system
    html_path <- normalizePath(html_file, winslash = "/")
    
    tryCatch({
      # Use browseURL which is more reliable across platforms
      browseURL(paste0("file://", html_path))
      showNotification("Opening slideshow in browser...", type = "message", duration = 3)
    }, error = function(e) {
      showNotification(paste0("Could not open browser automatically.\n",
                             "Please open this file manually:\n", html_path), 
                      type = "error", duration = 10)
    })
  })
  
  # Open folder button
  observeEvent(input$open_folder, {
    if (is.null(rv$output_dir) || !dir.exists(rv$output_dir)) {
      showNotification("Output directory not found. Generate slideshow first.", 
                      type = "warning", duration = 5)
      return()
    }
    
    folder_path <- normalizePath(rv$output_dir, winslash = "\\")
    
    tryCatch({
      # Platform-specific folder opening
      if (.Platform$OS.type == "windows") {
        # Windows
        shell.exec(folder_path)
      } else if (Sys.info()["sysname"] == "Darwin") {
        # macOS
        system2("open", shQuote(folder_path))
      } else {
        # Linux
        system2("xdg-open", shQuote(folder_path))
      }
      showNotification("Opening output folder...", type = "message", duration = 3)
    }, error = function(e) {
      # If automatic opening fails, show the path
      showNotification(paste0("Could not open folder automatically.\n",
                             "Folder location:\n", folder_path,
                             "\n\nPlease navigate to this folder manually."), 
                      type = "warning", duration = 10)
    })
  })
  
  # Cleanup when session ends (browser closed or app stopped)
  session$onSessionEnded(function() {
    cat("\n=== Shiny Session Ended ===\n")
    
    # Use isolate to access reactive values outside of reactive context
    is_running <- isolate(rv$running)
    pid_file_path <- isolate(rv$pid_file)
    
    cat("Running status:", is_running, "\n")
    cat("PID file path:", if (!is.null(pid_file_path)) pid_file_path else "NULL", "\n")
    
    # Always attempt cleanup if PID file exists, regardless of running state
    # (process might have finished but we still want to clean up)
    if (!is.null(pid_file_path) && file.exists(pid_file_path)) {
      cat("Found PID file, attempting to kill background process...\n")
      
      tryCatch({
        pid <- readLines(pid_file_path, warn = FALSE)[1]
        cat("PID read from file:", pid, "\n")
        
        # Validate PID before attempting to kill
        if (!is.na(pid) && nchar(trimws(pid)) > 0 && grepl("^[0-9]+$", pid)) {
          if (.Platform$OS.type == "windows") {
            result <- system(sprintf('taskkill /F /PID %s', pid), ignore.stdout = TRUE, ignore.stderr = TRUE)
            cat("Windows taskkill result:", result, "\n")
          } else {
            result <- system(sprintf('kill -9 %s', pid), ignore.stdout = TRUE, ignore.stderr = TRUE)
            cat("Unix kill result:", result, "\n")
          }
          cat("Background process terminated (PID:", pid, ")\n")
        } else {
          cat("Invalid PID in file, skipping kill\n")
        }
        
        # Always clean up PID file
        if (file.exists(pid_file_path)) {
          file.remove(pid_file_path)
          cat("PID file removed\n")
        }
        
      }, error = function(e) {
        cat("Error during cleanup:", conditionMessage(e), "\n")
      })
    } else {
      cat("No PID file found - background process may have already completed\n")
    }
    
    cat("=== Session Cleanup Complete ===\n\n")
  })
}

# ==============================================================================
# RUN APP
# ==============================================================================

shinyApp(ui = ui, server = server)
