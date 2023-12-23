# EPA GHGRP Data Cleaning -----------------------------------------------------
# Purpose: To clean 2022 EPA GHGRP data for use with dashboard
# Author: Sam Ennett
# Date Created: 12-23-2023
# Date updated: 12-23-2023

# To do list:

# Part 1: Load packages and set up code ---------------------------------------

if (!requireNamespace("pacman", quietly = TRUE)) {
  # If not installed, install 'pacman' package
  install.packages("pacman")
}

pacman::p_load(tidyverse, magrittr, sf, tidycensus, janitor, openxlsx, readxl,
               beepr, biscale, cowplot, corrplot, tigris, psych)

census_api_key("0d3711e1f7f03d54ea326708428a15bcec0c0621") # Key registered to Sam Ennett, do not distribute

options(tigris_use_cache = TRUE)

# Clear global environment
rm(list=ls())
gc()

# Create date variable
date <- str_sub(Sys.Date(), 1, 10)

# Part 2: Import data ---------------------------------------------------------

## Import EPA GHGRP data ------------------------------------------------------

# Files names
ghg_files <- list.files("Data/2022_data_summary_spreadsheets/")

# Sheet names
sheet_names <- excel_sheets("Data/2022_data_summary_spreadsheets/ghgp_data_2022.xlsx")[1:4] # Keep only direct emitters, oil and gas, gathering and boosting, and transmission pipelines

# sheet nicknames
sheet_nicknames <- c("DE", "OandG", "TP")

# Import annual files
for (f in 1:length(ghg_files)) {
  
  # get sheet names for each year of data
  sheet_names_raw <- excel_sheets(paste0("Data/2022_data_summary_spreadsheets/", ghg_files[f]))
  
  # Keep sheets related to direct emitters, oil and gas, 
  sheet_names <- sheet_names_raw[grep("Direct|Oil|Transmission", sheet_names_raw)]
  
  for (s in 1:length(sheet_names)) {
   
    temp_file <- read.xlsx(paste0("Data/2022_data_summary_spreadsheets/", ghg_files[f]),
                           sheet = sheet_names[s],
                           startRow = 4) %>%
      janitor::clean_names()
    
    assign(paste0(str_sub(ghg_files[f], 1, 14), "_", sheet_nicknames[s]), temp_file)
    
  }
}

# Part 3: Map out facility distribution ---------------------------------------

# Create US state boundary file
all_states <- tigris::states(cb = T) 

state_shapes <- all_states %>%
  filter(NAME != "Guam" |
           NAME != "Puerto Rico" |
           NAME != "American Samoa" |
           NAME != "United States Virgin Islands" |
           NAME != "Commonwealth of the Northern Mariana Islands")

