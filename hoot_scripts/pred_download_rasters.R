# download / source rasters in their default formatting
# Besides NVIS, these rasters are sourced from the ecocommons api

# BIOCLIM ----
# These bioclim layers come at 1000m resolution
# bioclim 1 is listed here but ended up not being used
bioclim <-
        list(bioclim1 = "https://api.data-ingester.app.ecocommons.org.au/api/data/90317596-ddef-5666-91c5-9cbc25c24fbc/download/current_1976-2005_bioclim-01.tif",
             bioclim5 = "https://api.data-ingester.app.ecocommons.org.au/api/data/cc081daa-f524-58c2-939e-166a2b2e79eb/download/current_1976-2005_bioclim-05.tif",
             bioclim6 = "https://api.data-ingester.app.ecocommons.org.au/api/data/476e4343-99f2-578e-b44a-951a55c6b7c2/download/current_1976-2005_bioclim-06.tif")

# bioclim_01_full <- rast(bioclim[[1]])
bioclim_05_full <- rast(bioclim[[2]])
bioclim_06_full <- rast(bioclim[[3]])

# This one comes at 250m resolution
bioclim_17_full <- rast("https://api.data-ingester.app.ecocommons.org.au/api/data/8527eb02-b694-58df-8cca-ef4e5191d500/download/AusClim_bioclim_17_9s_1976-2005.tif")

# forest height----
forest_height_default <- rast("https://api.data-ingester.dev.ecocommons.org.au/api/data/345f6405-0980-598c-a836-fc969a2524a7/download/Forest_height_AUS_2019_1s.tif")

# forest canopy cover----
forest_cover_default <- rast("https://api.data-ingester.dev.ecocommons.org.au/api/data/d24225fe-2766-5a1d-98d5-195dda789d14/download/Hansen_GFC-2020-v1.8_tree_canopy_cover_2000_2000_Australia_1s.tif")

# NVIS --------------------------------------------------------------------
# the NVIS major vegetation groups layer is available online
nvis_default <- terra::rast("data/rasters-float32/NVIS-001.asc")
crs(nvis_default)  <- "epsg:3577" # this layer comes at epsg:3577
