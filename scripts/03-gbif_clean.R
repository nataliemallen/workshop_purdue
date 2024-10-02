
# setup -------------------------------------------------------------------

rm(list = ls())

library(CoordinateCleaner)
library(scrubr)
library(rgbif)
library(tidyverse)

# data --------------------------------------------------------------------

my_species <- 'Pseudacris_crucifer'

gbif_raw <- 
  read_csv(
    paste0(
      'data/raw/',
      my_species,
      '_gbif_raw.csv'))
  
gbif_pre_clean <- 
  gbif_raw |> 
  select(
    id = gbifID,
    datasetKey,
    species, 
    status = occurrenceStatus,
    x = decimalLongitude,
    y = decimalLatitude,
    accuracy = coordinateUncertaintyInMeters,
    year = year, 
    institution = institutionCode)

gbif_pre_clean2 <- 
  gbif_pre_clean |>
  filter(
    !if_any(
      c(
        x, 
        y, 
        accuracy, 
        year), 
      ~ is.na(.x))) |>  
  filter(x < 0, y > 0) |> 
  filter(  
    status == 'PRESENT',
    institution != 'iNaturalist',
    year >= 1980,
    accuracy <= 5000) |> 
  select(
    id:species,
    x:institution) |> 
  mutate(source = 'gbif') |> 
  distinct(x, y, year, .keep_all = TRUE)

gbif_clean <- 
  gbif_pre_clean2 |>
  clean_coordinates(
    lon = 'x',
    lat = 'y',
    tests = c(
      'capitals', 
      'centroids',
      'equal', 
      'gbif', 
      'institutions', 
      'outliers', 
      'seas', 
      'zeros'),
    value = 'clean') |> 
  coord_incomplete() |> 
  coord_imprecise() |> 
  coord_impossible() |> 
  coord_unlikely()

# save data ---------------------------------------------------------------

gbif_clean |> 
  write_csv(
  paste0(
    'data/processed/',
    my_species,
    '_gbif_clean.csv'))

# create derived dataset --------------------------------------------------

# https://www.gbif.org/derived-dataset/about)

derived_data <-
  gbif_clean |>
  summarize(
    n = n(),
    .by = datasetKey)

# test derived dataset
   
derived_dataset_prep(
  citation_data = derived_data,
  title = 'Derived Dataset Pseudacris crucifer',
  description = 
    'This data was filtered using CoordinateCleaner and scrubr',
  source_url = 
    'https://github.com/hzumbado/workshop_purdue/data/processed/gbif_clean.csv',
  gbif_download_doi = '10.15468/dl.r9hsxv')

# If output looks ok, run derived_dataset 

derived_dataset(
  citation_data = derived_data,
  title = 'Derived Dataset Pseudacris crucifer',
  description = 
    'This data was filtered using CoordinateCleaner and scrubr',
  source_url = 
    'https://github.com/hzumbado/workshop_purdue/data/processed/gbif_clean.csv',
  gbif_download_doi = '10.15468/dl.r9hsxv')
