
# stack 1 -----------------------------------------------------------------

preds_current_250m_new <- raster::stack(
        c(
                forest_height_full_250m_final_new_2,
                forest_cover_full_250m_final_new_2,
                bioclim_06_full_250m_new,
                bioclim_05_full_250m_new,
                bioclim_17_full_new
        )
)

# write the full aus stack, stack 1
preds_current_250m_new <- rast(preds_current_250m_new)
writeRaster(preds_current_250m_new, 
            file = "data/rasters-float32-250m/stack_1_powl_full.tif", 
            overwrite = TRUE)

# stack 2 -----------------------------------------------------------------

# import reclassified NVIS data
# NVIS values were reclassified in QGIS
# NVIS binary: 1: forest, 2: non-forest
# NVIS grouped: broad classification groups:
        # 1: Forest
        # 2: Shrubland
        # 3: Grasslands
        # 4: Mangrove
        # 5: Water
        # 6: Building
        # 7: Unclassified, native
        # 8: Naturally bare
        # 9: Regrowth
        # 99: Unknown

nvis_binary <- rast("data/rasters-float32-250m/nvis_250m_reclass_binary.tif")
nvis_grouped <- rast("data/rasters-float32-250m/nvis_250m_reclass_allhabitat.tif")

preds_current_250m_connectivity <- raster::stack(
        c(
                forest_ht_connectivity_new,
                forest_cover_connectivity_new,
                bioclim_06_full_250m_new,
                bioclim_05_full_250m_new,
                bioclim_17_full_new,
                nvis_grouped
        )
)

# write the full aus stack, stack 2
test_B <- rast(preds_current_250m_connectivity)
writeRaster(test_B, file = "data/rasters-float32-250m/stack_2_powl_full.tif", 
            overwrite = TRUE)
