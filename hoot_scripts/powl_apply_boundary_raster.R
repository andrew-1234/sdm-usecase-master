# I can use the boundary created in powl_apply_boundary_points.R 
# And also crop/mask my predictor layers. 

# Import the raster stacks
predictors_stack_1_AUS <- stack("data/rasters-float32-250m/stack_1_powl_full.tif")
predictors_stack_2_AUS <- stack("data/rasters-float32-250m/stack_2_powl_full.tif")

# I will check that the boundary is going to overlap where it should:
plot(predictors_stack_1_AUS[[1]])
plot(powl_boundary_buffered, add=T)

# get the extent of the buffered boundary
# crop the raster stack of your choice, or a single raster
# going to use powl_boundary_buffered_sf to crop (created in powl_apply_boundary_points.R)

predictors_stack_1_AUS_v2 <-
        terra::crop(predictors_stack_1_AUS, powl_boundary_buffered_sf)

predictors_stack_1_crop_bound <-
        terra::mask(predictors_stack_1_AUS_v2, powl_boundary_buffered_sf)

# write the now cropped to boundary stack: stack 1
writeRaster(predictors_stack_1_crop_bound,
            file = "data/rasters-float32-250m/stack_1_powl_boundary.tif",
            overwrite = TRUE)

# you can read the stack back in at any time using stack()
my_stack <- stack(x = "data/rasters-float32-250m/stack_1_powl_boundary.tif")

# stack version 2 ---------------------------------------------------------
# repeat as above for stack 2:
predictors_stack_2_AUS_v2 <-
        terra::crop(predictors_stack_2_AUS, powl_boundary_buffered_sf)

predictors_stack_2_crop_bound <-
        terra::mask(predictors_stack_2_AUS_v2,
                    powl_boundary_buffered_sf)

# write the boundary stack, stack 2
writeRaster(predictors_stack_2_crop_bound, 
            file = "data/rasters-float32-250m/stack_2_powl_boundary.tif", 
            overwrite = TRUE)