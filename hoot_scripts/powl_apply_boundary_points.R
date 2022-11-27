# POWL --------------------------------------------------------------------

# apply a species specific boundary to the raster stack
# remove positive observations that are outside of the known distribution
# (e.g. no powerful owls in WA)

# import powl boundary ----------------------------------------------------
powl_boundary <- terra::vect(x = "data/boundary-powl/248Clip.shp")

# set crs
powl_boundary_v2 <- terra::project(powl_boundary, "epsg:4326")


# apply boundary to presence data -----------------------------------------

# convert the powl boundary to a simple features object
powl_boundary_v3 <- st_as_sf(powl_boundary_v2)

# stored as $geometry
plot(powl_boundary_v3$geometry)

# store in a new object
powl_boundary_geom <- powl_boundary_v3$geometry

# filter powl data for presences only
# and format the data as a simple features object
powl_df_pres <- hoot_data$powl %>% dplyr::filter(pres == 1)
powl_df_pres_sf <- st_as_sf(
        powl_df_pres,
        coords = c("lon", "lat"),
        crs = 4326,
        agr = "constant"
)

# use st_intersection to crop the presence data to the boundary
powl_df_pres_sf_crop <- st_intersection(powl_df_pres_sf, powl_boundary_geom)

# lets check the results. prescences that are within the crop boundary are red
# presences that were outside of the boundary are in blue
ggplot(data = powl_df_pres_sf) +
        geom_sf(aes(color = pres, size = pres)) +
        geom_sf(data = powl_df_pres_sf_crop, color = "red", size = 6) +
        geom_sf(data = powl_boundary_geom, fill = NA) 

# It looks like there is a point just outside of the boundary.
# This is again where you should check to confirm the record.
# For this example I would like to demonstrate how to buffer
# the boundary, and therefore include records that lie just 
# outside of it. I'm also going to fill holes, which may
# not be appropriate depending on the distribution or boundary
# that you are working with. 

# convert boundary to vector
powl_boundary_vect <- vect(powl_boundary_geom)

# it contains two geometries, so I'm going to merge them.
geo1 <- powl_boundary_vect[1]
geo2 <- fillHoles(geo1)

geo3 <- powl_boundary_vect[2]
geo4 <- fillHoles(geo3)
geo_combined <- combineGeoms(geo2, geo4, dissolve = TRUE)
plot(geo_combined)

# now I will apply a 100000m buffer
powl_boundary_buffered <- buffer(geo_combined, 100000)
crs(powl_boundary_buffered) <- "epsg:4326"

# check the result and compare with the original geometries
plot(powl_boundary_buffered)
lines(geo2, col = "red")
lines(geo4, col = "green")

# I can now export this vector for future use
writeVector(powl_boundary_buffered, filename = "output/powl_boundary_buffered.shp")

# Now I will run the intersection again, but this time using the buffered boundary
# convert boundary to sf
powl_boundary_buffered_sf <- st_as_sf(powl_boundary_buffered)

# run the intersection
powl_intersected <- st_intersection(powl_df_pres_sf, powl_boundary_buffered_sf)

# now I have 10 features
# I'll check once again:
ggplot() +
        geom_sf(data = powl_df_pres_sf, color = "red") +
        geom_sf(data = powl_intersected, color = "blue") +
        geom_sf(data = powl_boundary_buffered_sf, color = "green", fill = NA)
# I can see that there is only one record that was in the original unfiltered data (coloured in red) that has been removed. The remaining presences are found within the buffered boundary, and are therefore coloured in blue.

# I'll join the absence records back with the now filtered presence records
# And export the data frame as a .csv
powl_abs <- hoot_data$powl %>% filter(pres == 0)

powl_intersected_pres_abs <-
        powl_intersected %>% as_Spatial() %>% as.data.frame() %>%
        select(lat = coords.x2, lon = coords.x1, pres) %>%
        rbind(powl_abs) %>% 
        select(pres, coords.x1 = lon, coords.x2 = lat) %>% 
        write.csv(file = "output/filtered_data/powl_pres_abs_cropped.csv", 
                  row.names = FALSE)


