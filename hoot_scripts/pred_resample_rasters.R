# These steps will ensure that each of our predictor layers have
# the same extent, resolution, and CRS

# Create base layer -------------------------------------------------------

# Going to start by creating a base layer. This will be like the "master"
# layer that all other layers will be matched to.

# Import the AUS boundary shape file
aus_boundary <- vect("data/rasters-float32/AUS_boundary.shp")

# I'm going to use bioclim_17_full to create the base layer
# because it already has a spatial resolution of 250m.
# Note: if you didn't have a layer with your target resolution,
# you could use the terra::disagg or terra::aggregate functions 
# to up or downscale a raster. 

base1 <- crop(bioclim_17_full, aus_boundary)
base2 <- base1/base1
plot(base2)

# mask the base layer to the aus_boundary
base3 <- mask(base2, aus_boundary)
plot(base3)

# project to our project's crs: "epsg:4326"
base4 <- terra::project(base3, y = "epsg:4326")

# bioclim17 ---------------------------------------------------------------
# project bioclim 17 to the base layer
bioclim_17_full_new <-
        terra::project(
                bioclim_17_full,
                base4,
                verbose = TRUE,
                threads = TRUE
        )


# bioclim5 ----------------------------------------------------------------
# resample bioclim 5 to the base layer
# bioclim 5 has a spatial resoltuion of 1000m, which is why 
# we need to use the resample function
# the default method is bilinear interpolation if numeric data is detected
bioclim_05_full_250m_new <-
        terra::resample(
                bioclim_05_full,
                base4,
                threads = TRUE,
                verbose = TRUE
        )



# bioclim6 ----------------------------------------------------------------
# resample bioclim 6 to the base layer
bioclim_06_full_250m_new <-
        terra::resample(
                bioclim_06_full,
                base4,
                threads = TRUE,
                verbose = TRUE
        )

# forest cover ------------------------------------------------------------
# forest canopy cover and height come at a resolution of 25m
# the default resample method of bilinear interpolation can result in NA values
# when aggregating the data.
# So here I use the method "average", because it will only include
# the non-NA contributing grid cells
forest_cover_full_250m_final_new <-
        terra::resample(
                forest_cover_default,
                base4,
                verbose = TRUE,
                threads = TRUE,
                method = "average"
        )

# mask to base layer to remove values in ocean
forest_cover_full_250m_final_new_2 <- mask(forest_cover_full_250m_final_new, base4)

# forest height -----------------------------------------------------------

forest_height_full_250m_final_new <-
        terra::resample(
                forest_height_default,
                base4,
                verbose = TRUE,
                threads = TRUE,
                method = "average",
        )

# mask to base layer to remove values in ocean
forest_height_full_250m_final_new_2 <- mask(forest_height_full_250m_final_new, base4)

# NVIS --------------------------------------------------------------------
# NVIS is categorical, so when projecting I specify the method "near", 
# for nearest neighbour method

nvis_default_2 <- as.factor(nvis_default)
is.factor(nvis_default_2)

nvis_250m <-
        terra::project(
                nvis_default_2,
                base4,
                verbose = TRUE,
                threads = TRUE,
                method = "near",
        )

plot(nvis_250m)


# Focal function ----------------------------------------------------------
# Here we use a focal function on the forest height and cover layers
# to get a proxy measure of connectivity

forest_ht_connectivity_new <-
        focal(
                forest_height_full_250m_final_new_2,
                w = matrix(1, nrow = 21, ncol = 21),
                fun = sum,
                na.rm = TRUE
        ) 

writeRaster(forest_ht_connectivity_new, file = "data/rasters-float32-250m/forest_ht_connectivity_new.tif")
plot(forest_ht_connectivity_new)

forest_cover_connectivity_new <-
        focal(
                forest_cover_full_250m_final_new_2,
                w = matrix(1, nrow = 21, ncol = 21),
                fun = sum,
                na.rm = TRUE
        ) 
writeRaster(forest_cover_connectivity_new, file = "data/rasters-float32-250m/forest_cover_connectivity_new.tif")
plot(forest_cover_connectivity_new)
