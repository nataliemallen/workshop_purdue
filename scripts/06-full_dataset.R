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

# gbif
# inat

gbif_metadata <- 
  gbif |> 
  select(id, datasetKey, institution)

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

full_dataset |> 
  write_csv(
    paste0(
    'data/processed/final/',
    my_species,
    '_occs_clean.csv'))
