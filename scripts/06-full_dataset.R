# setup -------------------------------------------------------------------

rm(list = ls())

library(sf)
library(tidyverse)

# data --------------------------------------------------------------------

list.files(
  'data/processed',
  pattern = 'clean.csv$',
  full.names = TRUE) |> 
  map(~ .x |> 
        read_csv()) |> 
  set_names('gbif','inat') |> 
  list2env(.GlobalEnv)

#viewing each dataset, we have some information we don't need
# gbif
# inat

#remove metadata and place in a seperate object
gbif_metadata <- 
  gbif |> 
  select(id, datasetKey, institution)

#convert columns to factors
full_dataset <- 
  gbif |> 
  select(!c(datasetKey, institution)) |> 
  bind_rows(
    inat |> 
      select(!coordinates_obscured)) |> 
  mutate(
    across(
      c(id, species, year, source),
      ~ as_factor(.x)))

dir.create('data/processed/final')

my_species <- 'Pseudacris_crucifer'

gbif_metadata |>
  write_csv(
    paste0(
      'data/processed/final/',
      my_species,
      '_occs_clean_metadata.csv'
    )
  )

full_dataset |> 
  write_csv(
    paste0(
    'data/processed/final/',
    my_species,
    '_occs_clean.csv'))
