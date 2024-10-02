
# setup -------------------------------------------------------------------

rm(list = ls())

library(rgbif)
library(tidyverse)

# data --------------------------------------------------------------------

my_species <- 'Pseudacris_crucifer'

key <- 
  name_backbone(my_species) |> 
  pull(usageKey)

key

gbif_download <- 
  occ_download(
    pred('taxonKey', key), 
    format = 'SIMPLE_CSV')
    # user = NULL,
    # pwd = NULL,
    # email = NULL)

gbif_download

# save citation -----------------------------------------------------------

gbif_download |> 
  write_rds(
    paste0(
      'data/raw/',
      my_species,
      '_key.rds'))

read_rds(
  paste0(
  'data/raw/',
  my_species,
  '_key.rds'))

# check download processing -----------------------------------------------

occ_download_wait(gbif_download)

data <- 
  occ_download_get(
    gbif_download, 
    path = 'data/raw', 
    overwrite = TRUE) |> 
  occ_download_import()

# data <- 
#   occ_download_get(
#     '0037423-240906103802322',
#     path = 'data/raw',
#     overwrite = TRUE)

# save data ---------------------------------------------------------------

data |>
  write_csv(
    paste0(
      'data/raw/',
      my_species,
      '_gbif_raw.csv'))
