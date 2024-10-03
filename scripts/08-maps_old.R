# setup -------------------------------------------------------------------

rm(list = ls())

library(sf)
library(terra)
library(tmap)
library(tidyverse)

# data --------------------------------------------------------------------

#shapefiles

world <- 
  read_sf('shapefiles/world.gpkg') |> 
  st_make_valid() 

list.files(
  'shapefiles/processed',
  pattern = 'cou|usa|cv|salton',
  full.names = TRUE) |> 
  map(~ .x |> 
        read_sf()) |> 
  set_names(
    'counties',
    'cv',
    'salton',
    'usa') |>
  map(~ .x |> 
        st_transform(
          crs = st_crs(world))) |> 
  list2env(.GlobalEnv)

# rasters

list.files(
  'rasters/processed',
  pattern = '.tif$',
  full.names = TRUE) |> 
  map(
    ~ .x |> 
      rast()) |> 
  set_names(
    'elevation_usa', 
    'hillshade_usa') |> 
  list2env(.GlobalEnv)

# Abronia occurrences

occs <- 
  read_csv('data/processed/abronia_clean.csv')

occs_sf <- 
  occs |> 
  filter(y < 40) |> 
    st_as_sf(
    coords = c(
      x = 'x',
      y = 'y'),
    crs = 4326) 
  
tm_shape(occs_sf) +
  tm_grid() +
  tm_dots(
    col = 'blue', 
    size = 0.2, 
    shape = 21)

# map 1 -------------------------------------------------------------------

#tmap_mode('plot')
tmap_mode('view')

ab_usa <- 
  occs_sf |> 
  st_filter(usa)

abronia_usa <- 
  tm_shape(usa) +
  tm_grid(lines = FALSE) +
  tm_polygons() +
  tm_shape(ab_usa) +
  tm_dots(
    col = 'blue', 
    size = 0.2, 
    shape = 21) +
  tm_scale_bar(
      text.size = 0.5,
      position = c('left', 'bottom'))

# map 2 -------------------------------------------------------------------

california <- 
  usa |>
  filter(state == 'California')

abronia_cal <- 
  tm_shape(world) +
  tm_grid(lines = FALSE) +
  tm_polygons('gray') +
  tm_shape(
    hillshade_usa %>%
      mask(california)) +
  tm_grid(lines = FALSE) +
  tm_raster(
    palette = gray(0:100 / 100),
    n = 100,
    legend.show = FALSE) +
  tm_shape(
    elevation_usa |>
      crop(california, mask = TRUE),
    raster.downsample = FALSE) +
  tm_raster(
    title = 'Elevation (m)',
    palette = terrain.colors(500),
    style = 'cont',
    alpha = 0.7) +
  tm_shape(
    california, is.master = T) +
  tm_borders() +
  tm_shape(
    occs_sf |> 
      st_filter(california)) +
  tm_dots(
    col = 'blue', 
    size = 0.2, 
    shape = 21) +
  tm_scale_bar(
    text.size = 0.5,
    breaks = c(0, 100, 200),
    position = c('left', 'bottom')) +
  tm_layout(
    legend.outside = TRUE,
    bg.color = 'lightblue')

abronia_cal

# map 3 -------------------------------------------------------------------

riverside <- 
  counties |> 
  filter(
    state == 'California',
    name == 'Riverside')
  
study_area <-  
  st_bbox(
    c(
      xmin = -119, 
      xmax = -113,
      ymin = 32.5, 
      ymax = 36),
    crs = st_crs(world)) %>%  
  st_as_sfc()

abronia_cv <-
  usa |> 
  tm_shape(bb = study_area) +
  tm_grid(lines = FALSE) +
  tm_polygons('gray') +
  tm_shape(
    hillshade_usa %>%
      mask(california)) +
  tm_grid(lines = FALSE) +
  tm_raster(
    palette = gray(0:100 / 100),
    n = 100,
    legend.show = FALSE) +
  tm_shape(
    elevation_usa |>
      crop(california, mask = TRUE),
    raster.downsample = FALSE) +
  tm_raster(
    title = 'Elevation (m)',
    palette = terrain.colors(500),
    style = 'cont',
    alpha = 0.7) +
  tm_shape(california) +
  tm_borders() +
  tm_shape(
    counties |> 
      filter(state == 'California')) +
  tm_borders() +
  tm_shape(riverside) +
  tm_borders('red', lwd = 2) +
  tm_shape(cv) +
  tm_borders('black') +
  tm_shape(salton) +
  tm_polygons('lightblue') +
  tm_shape(
    occs_sf |> 
      st_filter(riverside)) +
  tm_dots(
    'Source',
    col = 'source', 
    size = 0.2, 
    shape = 21) +
  tm_scale_bar(
    text.size = 0.5,
    position = c(0.05, 0.1),
    breaks = c(0, 100)) +
  tm_layout(
    legend.outside = TRUE,
    bg.color = 'lightblue')

abronia_cv

tmap_arrange(
  abronia_cal, 
  abronia_cv,
  ncol = 1)

# try tmap_mode('view')

tmap_save(
  abronia_cv,
  filename = 'output/figures/abronia_cv.jpg',
  dpi = 400)

tmap_save(
  abronia_cv,
  filename = 'output/figures/abronia_cv.html')
