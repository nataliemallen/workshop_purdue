# setup -------------------------------------------------------------------

rm(list = ls())

library(CoordinateCleaner)
library(scrubr)
library(tidyverse)

# data --------------------------------------------------------------------

my_species <- 'Pseudacris_crucifer'

inat_pre_clean <- 
  read_csv(
    paste0(
          'data/raw/',
          my_species,
          '_inat_raw.csv')) |>
  select(
    id,
    species = scientific_name,
    date = datetime,
    x = longitude,
    y = latitude,
    accuracy = positional_accuracy, 
    coordinates_obscured) |> 
  mutate(
    date = as_date(date),
    year = year(date), 
    .before = date) |> 
  select(!date)
  
inat_pre_clean2 <- 
  inat_pre_clean |>
  filter(
    !if_any(
      c(
        x, 
        y, 
        accuracy, 
        year), 
      is.na)) |>  
  filter(x < 0, y > 0) |> 
  filter(  
    year >= 1980,
    accuracy <= 5000,
    coordinates_obscured == 'FALSE') |>
  mutate(source = 'INaturalist') |> 
  distinct(x, y, year, .keep_all = TRUE)

inat_clean <- 
  inat_pre_clean2 |>
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

inat_clean |>
  write_csv(
    paste0(
      'data/processed/',
      my_species,
      '_inat_clean.csv'))
