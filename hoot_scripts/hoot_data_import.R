
# Import the raw data -----------------------------------------------------
hoot_raw <- read.csv("data/hoot_final_reduced_columns.csv")

# Shorten the names
names(hoot_raw) <- c("ID","powl","baow","sbow","ebow","maow","lat","lon")

# Store names in an object
hoot_names <- names(hoot_raw[2:6])

# Generate occurrence set -------------------------------------------------

# Get unique rows per ID/lat/lon for column "powl" (powerful owl)
powl_u <- hoot_raw %>%
        group_by(ID, lat, lon) %>%
        summarise(
                c_lat = length(unique(powl)),
                c_lon = length(unique(powl)),
                u_powl = unique(powl)
        )   

# loop through each owl stored in hoot_names
# get number of unique values of yes/no for each sensor
# if c_lat = 2, then this sensor has both yes and no responses
# if c_lat = 1, then this sensor only has no responses 
# the output of lapply is a list object
hoot_unique <- lapply(hoot_names, function(x) {
        name <- paste0("u_", x)
        data_u <- hoot_raw %>%
                group_by(ID, lat, lon) %>%
                summarise(c_lat = length(unique(!!sym(x))),
                          c_lon = length(unique(!!sym(x))),
                          id = unique(!!sym(x))) %>% 
                rename(!!name := id)
})

# add names to the list
names(hoot_unique) <- hoot_names

# we can inspect each of the objects stored in the list like this:
head(hoot_unique$powl)

# The next step is to filter for presence / absence
# This function will help for looping through species
# It will also export the data as csv files, but this is not required. 
export_pres_abs <- function(data, sp, u_col) {
        
        # set the output path "filtered_data"
        output_path <- file.path(getwd(), "output/filtered_data")
        
        # create the output directory if it doesn't exist
        if (!dir.exists(output_path)) {
                dir.create(output_path)
        }
        
        # prep and export pres data  
        presence <- data %>% dplyr::filter({{u_col}} == "YES") %>%
                dplyr::mutate(pres = 1)
        presence %>% 
                write.csv(file = paste0(output_path, "/hoot_", sp, "_pres.csv"))
        
        # prep and export abs data  
        absence <- data %>% dplyr::filter({{u_col}} == "NO" & c_lat == 1) %>%
                dplyr::mutate(pres = 0)
        absence %>% 
                write.csv(file = paste0(output_path, "/hoot_", sp, "_abs.csv"))
        
        # rbind together and subset
        pa <- rbind(presence, absence)
        pa2 <- as.data.frame(pa[,c(2,3,7)])
        
}

# run our export_pres_abs function for powerful owl to test it
# To access the "powl" list object as a data frame we have to call data.frame
powl_pa <-
        export_pres_abs(data = data.frame(hoot_unique$powl),
                        sp = "powl",
                        u_col = u_powl)
# check the results
head(powl_pa)

# Now we will run this function using a for loop, for all five species
# start by creating an empty list
hoot_pres_abs <- list()

# run the loop:
# this loop will append each of the generated data frames to the empty list

for (hoot_sp in hoot_names) {
        # turn into data frame here then pass to function
        df <- data.frame(hoot_unique[[hoot_sp]]) # using [[]] here to prevent the list prefix
        
        hoot_name <- paste0("u_", hoot_sp)
        
        df_1 <- export_pres_abs(data = df, 
                                sp = hoot_sp,
                                u_col = df[[hoot_name]])
        
        hoot_pres_abs[[length(hoot_pres_abs) + 1]] <- df_1
}

# add names to the list
names(hoot_pres_abs) <- hoot_names

# export the list object for later use if you like
saveRDS(hoot_pres_abs, file = "output/hoot_pres_abs.rds")

# we can also export any of the data frames to csv
# for use on ecocommons
write.csv(hoot_pres_abs$sbow, file = "sbow_pres_abs.csv", row.names = FALSE)

# Generate call frequency set ---------------------------------------------

## POWL -------------------------------------------------------------------
# I'll generate the frequency data for Powerful Owl separately to the other species.
# This is because the data set was filtered to remove potentially anomalous records.

# get unique rows per ID/lat/lon for powl
powl_calls_freq <- hoot_raw %>% 
        group_by(lat, lon) %>%
        count(powl_calls = powl) %>% 
        filter(powl_calls == "YES")

# merge with the already filtered powl dataset 
# (removes records outside of known distribution)
# here I use a left join so that only the rows from `powl_occ_cropped` are kept
# thus removing the frequency data for points that are not in the cropped data
powl_calls_freq_2 <-
        dplyr::left_join(x = powl_occ_cropped,
                         y = powl_calls_freq,
                         by = c("coords.x2" = "lat", "coords.x1" = "lon"))

# replace na values with zeros
powl_calls_freq_2$n <- powl_calls_freq_2$n %>% replace_na(0)

# replace na values with "NO"
powl_calls_freq_2$powl_calls <-
        powl_calls_freq_2$powl_calls %>% replace_na("NO")

# export the final data set
write.csv(powl_calls_freq_2, file = "output/filtered_data/powl_freq.csv", row.names = FALSE)


## All species -----------------------------------------------------------------

# This function will run through all of the hoot detective records.
# It returns a data frame of the total call frequency at each sensor,
# for the specified column name / owl species

call_freq <- function(raw_data, species_name_column) {
  
  owl_calls_freq <- raw_data %>% 
          group_by(lat, lon) %>%
          count(owl_calls = {{species_name_column}}) %>% 
          filter(owl_calls == "YES")
  
  
  owl_true_abs <- raw_data %>%
          group_by(ID, lat, lon) %>%
          summarise(
                  c_lat = length(unique({{species_name_column}})),
                  c_lon = length(unique({{species_name_column}})),
                  owl_column = unique({{species_name_column}})
          )  %>% 
          filter(c_lat == 1) 
  
  owl_true_abs_2 <- owl_true_abs %>% dplyr::select(lat, lon, owl_column)
  owl_true_abs_3 <- owl_true_abs_2 %>% ungroup %>% dplyr::select(-ID) %>% 
          rename(owl_calls = owl_column)
  
  owl_calls_freq_2 <- rbind(owl_calls_freq, owl_true_abs_3)
  owl_calls_freq_2$n <- owl_calls_freq_2$n %>% replace_na(0)
  owl_calls_freq_2 <- owl_calls_freq_2 %>% arrange(desc(n))
  
  #write.csv(owl_calls_freq_2, file = "output/owl_freq.csv", row.names = FALSE)

}

# We can use this function in a loop, to generate the frequency data for 
# each of the species
# start by defining the column names in a character vector:
owl_names <- c("powl","baow","sbow","ebow","maow")

# make an empty list:
hoot_call_freq <- list()

# run the loop
# each iteration will return the data frame of frequencies and append this
# to the list we created

for (SPECIES in owl_names) {
        df <- call_freq(raw_data = hoot_raw,
                  species_name_column = !!sym(SPECIES))
        hoot_call_freq[[length(hoot_call_freq) + 1]] <- df
}

# Now add our names to the list objects
names(hoot_call_freq) <- owl_names

# Now we can export this list for future use
saveRDS(hoot_call_freq, file = "output/hoot_list/hoot_frequency_list_object.rds")

####
# example on how you could run the hoot_call_freq function for a single species:
####

boobook <- hoot_call_freq$sbow
head(boobook)
write.csv(boobook, "output/filtered_data/sbow_southboobook_freq.csv", row.names = FALSE)

        




