###updated map processing
# setup -------------------------------------------------------------------

rm(list = ls())

library(sf)
library(terra)
library(tmap)
library(tidyverse)

# data --------------------------------------------------------------------

world <- 
  read_sf('shapefiles/world.gpkg') |> 
  st_make_valid() 

list.files(
  'shapefiles',
  pattern = 'cou|usa',
  full.names = TRUE) |> 
  map(~ .x |> 
        read_sf()) |> 
  set_names('counties','usa') |>
  map(~ .x |> 
        st_transform(
          crs = st_crs(world))) |> 
  list2env(.GlobalEnv)

# conterminous us ---------------------------------------------------------

usa |>
  distinct(name) |>
  pull()

#filter out states we DONT want
usa_cont <- 
  usa |> 
  rename(state = name) |> 
  filter(!state %in% c(
    'Hawaii', 
    'Alaska',
    'Guam',
    'Commonwealth of the Northern Mariana Islands',
    'United States Virgin Islands',
    'Puerto Rico',
    'American Samoa'))

# remove extra counties ---------------------------------------------------------

#inner join looks for matches in both datasets to remove extra counties
counties_cont <- 
  counties |> 
  inner_join(
    usa_cont |>
      select(state, geoid) |> 
      as_tibble(), 
    by = c('statefp' = 'geoid')) |>
  select(!geom.y) |> 
  relocate(state, .before = name)

# counties_cont <-
#   counties |>
#   st_filter(
#     usa_cont |>
#       select(state),
#     .predicate = st_intersects)

# plot terra --------------------------------------------------------------

plot(terra::vect(usa_cont))

usa_cont |> 
  ggplot() +
  geom_sf(
    fill = 'darkgreen', 
    col = 'white') +
  theme_bw()

usa_cont |> 
  tm_shape() + 
  tm_borders() +
  tm_fill('gray90')

# save vector files -------------------------------------------------------

usa_cont |> 
  write_sf('shapefiles/processed/usa_cont.gpkg')

counties_cont |>  
  write_sf('shapefiles/processed/counties_cont.gpkg') 

# maps --------------------------------------------------------------------

usa_cont |>
  tm_shape() +
  tm_borders(col = 'white') +
  tm_polygons('darkgreen')

tmap_options(max.categories = 49)

usa_cont |>
  mutate(state = as_factor(state)) |>
  tm_shape() +
  tm_grid(lines = FALSE) +
  tm_borders('white') +
  tm_fill(
    col = 'state',
    palette = 'Set2') +
  tm_layout(
    legend.outside = TRUE,
    bg.color = 'gray80')

tmap_options_reset()

# rasters -----------------------------------------------------------------

elevation <- 
  rast('rasters/elevation_1km.tif')

plot(elevation)

elevation_usa <-
  elevation |>
  crop(
    usa_cont,
    mask = TRUE)

plot(elevation_usa)

slope <- 
  terrain(elevation_usa, "slope", unit="radians")

plot(slope)

aspect <- 
  terrain(elevation_usa, "aspect", unit="radians")

plot(aspect)


hillshade_usa <- 
  shade(slope, aspect, 40, 270)

plot(hillshade_usa, col = grey(0:100/100), legend = FALSE)
plot(elevation_usa, col = terrain.colors(25, alpha = 0.35), add = TRUE)

writeRaster(
  elevation_usa,
  'rasters/processed/elevation_usa.tif',
  overwrite = TRUE)

writeRaster(
  hillshade_usa,
  'rasters/processed/hillshade_usa.tif',
  overwrite = TRUE)

# maps --------------------------------------------------------------------

plot(vect(usa_cont[usa_cont$state == 'Indiana',]))

indiana <- 
  usa_cont |>
  filter(state == 'Indiana') |>
  vect()

indiana_counties <-
  counties_cont |> 
  filter(state == 'Indiana') |> 
  vect()

plot(
  crop(hillshade_usa, indiana, mask = TRUE), 
  col = grey(0:100/100), legend = FALSE)

plot(crop(elevation_usa, indiana, mask = TRUE), add = TRUE, alpha = 0.7)

plot(indiana_counties, border = 'white', add = TRUE)


# tm_shape(world) +
#   tm_grid(lines = FALSE) +
#   tm_polygons('gray') +
tm_shape(
  hillshade_usa %>%
    mask(indiana)) +
  tm_grid(lines = FALSE) +
  tm_raster(
    palette = gray(0:100 / 100),
    n = 100,
    legend.show = FALSE) +
  tm_shape(
    elevation_usa |>
      crop(indiana, mask = TRUE),
    raster.downsample = FALSE) +
  tm_raster(
    title = 'Elevation (m)',
    palette = terrain.colors(500),
    style = 'cont',
    alpha = 0.5) +
  tm_shape(
    usa_cont |>
      filter(state == 'Indiana'), is.master = T) +
  tm_borders() +
  tm_layout(
    legend.outside = TRUE,
    frame = FALSE)
