
# setup -------------------------------------------------------------------

rm(list = ls())

library(rinat)
library(tidyverse)

# data --------------------------------------------------------------------

#total of observations

inat_metadata <- 
  get_inat_obs(
    query = 'Pseudacris crucifer', 
    meta = TRUE) |> 
  pluck('meta')

# download data

inat_data <-
  get_inat_obs(
    query = 'Pseudacris crucifer',
    quality = 'research',
    geo = TRUE,
    maxresults = 10000,
    meta = FALSE) |> 
  as_tibble()

# save data ---------------------------------------------------------------

my_species <- 'Pseudacris_crucifer'

inat_data |>
  write_csv(
    paste0(
      'data/raw/',
      my_species,
      '_inat_raw.csv'))
  