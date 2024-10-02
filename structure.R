folders <- c('data/raw',
             'data/processed',
             'shapefiles',
             'shapefiles/processed',
             'rasters',
             'rasters/processed',
             'scripts',
             'outputs/figures',
             'docs')

sapply(folders,
       FUN = dir.create,
       recursive = TRUE)