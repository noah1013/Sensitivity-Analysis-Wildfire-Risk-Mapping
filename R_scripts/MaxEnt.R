# Code to run loops over maxent:

# Code adapted from: X. Feng, C. Walker & F. Gebresenbet (2017)
# "A brief tutorial on running Maxent in R"

# found at: https://github.com/shandongfx/workshop_maxent_R/blob/master/code/Appendix1_case_study.md

library(raster)
library(dismo)
library(rgeos)
library(rstudioapi) # automatically get the directory
library(dplyr)
library(sf)
library(tmap)


# clear the R environment
rm(list = ls())
gc()

# set the directory:
path <- dirname(getActiveDocumentContext()$path)
# if the data is not being loaded, it can be accessed via the 'Data' Folder.
setwd(path)

# get the path to the 'java' directory within the 'dismo' package
dest_dir <- system.file("java", package = "dismo")
# check if it worked.
dir.exists(dest_dir) 

# define the source and destination file paths
src_file <- paste0(path, "/maxent/maxent.jar")
dest_file <- file.path(dest_dir, "maxent.jar")


# copy the maxent.jar into the dismo package so that it can be accessed.
file.copy(src_file, dest_file, overwrite = TRUE)


# function to run maxent 
run_maxent <- function (SSP_scenario) {
  
  # import present/historical biclimatic variables.
  historical_bioclim_path <- list.files(paste0(dirname(path), "/Data/Final/Bioclim_avg/SSP",
                                               as.character(245)),
                             full.names = TRUE)
  
  # we will define a seperate path for the future data:
  future_bioclim_path <- list.files(paste0(dirname(path), "/Data/Final/Bioclim_avg/SSP",
                                           as.character(SSP_scenario)),
                             full.names = TRUE)
  
  # instantiate two empty lists to contain the file paths for the 
  # present and future Bioclim variables.
  present_bioclim_list <- list()
  future_bioclim_list <- list()
  
    
  # now we loop thorugh the historical and future directories.
  # the historical data is all based on the ssp245 scenario because that's 
  # bascially our current trajectory
    
  for (folder in historical_bioclim_path){
      
    Bioclim_file_loc <- list.files(folder, full.names = TRUE)
      
    # loop through each folder in the parent directory.
    for (file in Bioclim_file_loc) {
        
      # look for the file which contains present climatic variables.
      # this is represented by the era
      if (grepl("2001-2021", basename(file))) {
          
        # store the file path of this 
        present_bioclim_list <- append(present_bioclim_list, file)
          
          }
        }
      } # end of historical data looper
    
    
  for (folder_future in future_bioclim_path) {

    future_bioclim_file_loc <- list.files(folder_future, 
                                          full.names = TRUE)
    
    # loop through each folder in the parent directory.
    for (file_fut in future_bioclim_file_loc) {
      
      print(file_fut)
      # look for the file which contains the target future climate variables
      # and store that in the futre_bioclim_list
    
      if (grepl("2080-2100", basename(file_fut))) {
          
        future_bioclim_list <- append(future_bioclim_list, file_fut)

        }
      }
    } # end of future list looper
  
  # import topographical variables.
  topography <- list.files(paste0(dirname(path), 
                                  "/Data/Final/Topography/Topo_processed"),
                           full.names = TRUE)
  
  # import the river proximity map:
  rivers <- list.files(paste0(dirname(path), 
                              "/Data/Final/rivers/portugal_proximity_river_map"),
                       full.names = TRUE)
  
  # create a stack of the variables for all the raster data.
  bioclim_stack <- raster::stack(c(present_bioclim_list, topography, rivers))
  
  # remove years from layer names in bioclim_stack (training data)
  # this is so that the model can be used to make predictions on future data.
  names(bioclim_stack) <- sub("_2001.2021", "", names(bioclim_stack))
  
  print(names(bioclim_stack))
  
  # lets get our CRS from our AOI shapefile:
  portugal_path <- paste0(dirname(path), "/Data/Initial/boundaries/portugal_20790/portugal_20790.shp")
  
  portugal <- st_read(portugal_path, layer = "portugal_20790")
  
  # double checking the CRS
  st_crs(portugal)
  
  # GBIF data manipulation:
  data_dir <- paste0(dirname(path), "/Data")
  
  occ_raw <- read.csv(paste0
                      (data_dir, "/Initial/vegetation/GBIF_Raw/NFI_2015.csv"), 
                      header = TRUE)
  
  # generate a list to contain all the tree species.
  tree_species <- list("Quercus suber", "Quercus rotundifolia" ,
                       "Castanea sativa", "Eucalyptus",
                       # "Olea europaea", "Vitis vinifera", "Ceratonia siliqua",
                       "Acacia", "Pinus pinaster", "Pinus pinea")
  
  # create an output directory for the maxent outputs
  output_directory_main <- paste0(dirname(path), "/Data/Final/Vegetation/maxent_outputs")
  
  # create the directory
  if (!dir.exists(output_directory_main)){
    
    dir.create(output_directory_main, recursive = TRUE)
  
  }
  
  output_directory <- paste0(output_directory_main, "/SSP", as.character(SSP_scenario))
  
  if (!dir.exists(output_directory)){
    
    dir.create(output_directory)
    
  }
  
  # now create a for loop to go over each tree species.
  # run the maxent model on each species.
  
  for (tree in tree_species) {
    
    species <- occ_raw %>% filter(verbatimScientificName == tree)
    
    # remove erroneous coordinates, where either the latitude or
    # longitude is missing
    any(is.na(species))
    
    species_clean <- subset(species, 
                            (!is.na(decimalLatitude)) & 
                              (!is.na(decimalLongitude)))
    
    cat(nrow(species) - nrow(species_clean), "records are removed")
    
    # remove duplicated data based on latitude and longitude
    dups <- duplicated(species_clean[c("decimalLatitude", "decimalLongitude")])
    species_unique <- species_clean[!dups, ]
    cat(nrow(species_clean) - nrow(species_unique), "records are removed")
    
    # make occ spatial
    coordinates(species_unique) <- ~decimalLongitude + decimalLatitude
    # give it a crs -> all GBIF data comes in WGS84.
    proj4string(species_unique) <- CRS("+init=epsg:4326")
    
    
    # now, convert SpatialPointsDataFrame to sf object
    species_unique <- st_as_sf(species_unique)
    
    # convert species_unique to the desired crs (in this case, portugal)
    species_unique <- st_transform(species_unique, st_crs(portugal))
    
    # now that the points are in the portugese crs, we put it back as 
    # a spatial point dataframe.
    species_unique <- as(species_unique, "Spatial")
    
    
    # lets check if it worked.
    # lets just use the first raster (bioclim 01) to verify.
    plot(bioclim_stack[[1]]) 
    plot(species_unique, add = TRUE, col = 'blue')
    
    # good, they line up really well!
    
    # thin the data: we only want 1 point per raster cell.
    # this is because having multiple points per raster cell can introduce sampling
    # bias.
    
    # thin occurrence data (keep one occurrence point per cell)
    cells <- cellFromXY(bioclim_stack[[1]], species_unique)
    cell_dup <- duplicated(cells)
    species_final <- species_unique[!cell_dup, ]
    cat(nrow(species_unique) - nrow(species_final), "records are removed")
    
    tmap_mode('view')
    
    test <- st_as_sf(species_final)
    
    tm_shape(test)+
      tm_dots(col= "scientificName")
    
    # no need to create a buffer for the study area because Portugal is quite small.
    
    # create a directory to hold data for further processing.
    int_process_data <- paste0(path,"/int_process_data")
    
    if (dir.exists(int_process_data)){
      # do nothing
    }else{
      # create the directory
      dir.create(int_process_data)
    }
    
    
    # to ensure that the random bg points never coincide with the presence data, 
    # we will generate a raster that takes this into account.
    # this is made possible by giving raster cells where the species is located
    # a value of 'NA' and then making sure that the NA value cells are ignored
    # during the random sampling process when generating the background
    # (pseudo-absence) points.
    
    # we do this because we have 1 species point per pixel, and where a species is
    # present, it cannot also be absent.
    
    # create raster from occurrence points, assign them a unique value, like 1
    species_raster <- rasterize(species_final, bioclim_stack, field=1)
    
    AOI_no_species <- overlay(bioclim_stack, 
                              species_raster, 
                              fun = function(bioclim_stack, species_raster) 
                              {ifelse(is.na(species_raster), bioclim_stack, NA)})
    
    # save the bioclim_stack for processing later in ascii format.
    writeRaster(bioclim_stack,
                # a series of names for output files
                filename=paste0(int_process_data, "/", names(bioclim_stack),".asc"), 
                format="ascii", ## the output format
                bylayer=TRUE, ## this will save a series of layers
                overwrite=T)
    
    # select random background points from the study region.
    # these random points are going to be the 'pseudo-absence' data points:
    
    # set the seed so that its reproducible:
    set.seed(7) 
    
    # lets have the same number of presence data to pseudo absence data.
    # for the purpose of a balanced dataset.
    # sample the pseudo-absence data from the raster image which shows NA
    # where the species is present. 
    
    bg <- sampleRandom(x=AOI_no_species,
                       size= (nrow(species_final) * 2), # 2 *size of pseudo-absence points.
                       na.rm=T, #removes the 'Not Applicable' points  
                       sp=T) # return spatial points
    
    plot(AOI_no_species[[1]])
    # add the background points to the plotted raster
    plot(bg,add=T) 
    # add the occurrence data to the plotted raster
    plot(species_final,add=T,col="red")
    
    ### TRAIN-TEST SPLIT ###
    
    # get the same random sample for training and testing
    set.seed(7)
    
    # we will go for a 70-30 train-test split
    
    # randomly select 70% for training
    selected <- sample(1:nrow(species_final), nrow(species_final) * 0.7)
    
    train <- species_final[selected, ] # data selected for training
    test <- species_final[-selected, ] # the opposite of selected data for testing
    
    # converting the data into a dataframe format for processing in maxent:
    
    # extracting env conditions for training occ from the raster
    # stack: a data frame is returned (i.e multiple columns)
    p_train <- extract(bioclim_stack, train)
    # env conditions for testing occ
    p_test <- extract(bioclim_stack, test)
    # extracting env conditions for background points.
    a <- extract(bioclim_stack, bg)
    
    # now we are going to assign the value '1' to species occurrence (presence) points
    # and '0' to the background (pseudo-absence) points.
    
    # generating a new vector where 1 = presence and 0 = pseudo-absence.
    pa <- c(rep(1, nrow(p_train)), rep(0, nrow(a)))
    
    pder <- as.data.frame(rbind(p_train, a))
    
    # training MaxEnt.
    
    # create a directory to hold the outputs.
    # Name the directory after the tree species inside the maxent_output
    mxent_output <- paste0(output_directory, "/", tree) 
    
    if (dir.exists(mxent_output)){
      # do nothing
    }else{
      # create the directory
      dir.create(mxent_output )
    }
    
    mod <- maxent(x=pder, ## env conditions
                  p=pa,   ## 1:presence or 0:absence
                  path=mxent_output, ## folder for maxent output;
                  args=c("responsecurves") ## parameter specification
    )
    
    mod
    
    # view results:
    
    # view detailed results
    results <- mod@results
    
    # print the results onto a text file in the output folder.
    
    {
      sink(paste0(mxent_output, '/results.txt'))
      print(results)
      sink()
      
    }
    
    # example 1, project to study area [raster]
    pred <- predict(mod, bioclim_stack)
    plot(pred, main = paste0("prediction probabilities (present) - ", tree))  # plot the continuous prediction
    
    # lets save the raster output just in case:
    writeRaster(pred,
                filename = paste0(mxent_output, "/present_PP_", tree, ".tif"),
                format="GTIFF")
    
    
    # project with training occurrences [dataframes]
    pred2 <- predict(mod, p_train)
    
    # histogram of the prediction.
    hist(pred2, main = paste0("Histogram -  ", tree))
    
    # model evaluation on training data:
    
    mod_eval_train <- dismo::evaluate(p = p_train, a = a, model = mod)
    print(mod_eval_train)
    
    # model_evaulation on testing data:
    
    mod_eval_test <- dismo::evaluate(p = p_test, a = a, model = mod)
    print(mod_eval_test)
    
    # print the evaualtion onto a text file in the output folder.
    
    {
      sink(paste0(mxent_output, '/evaluations.txt'))
      cat(paste0("Model Evaluation for train set\n\nTree Species = ", tree, "\n\n"))
      print(mod_eval_train)
      cat("\n\nModel Evaluation for test set\n\n")
      print(mod_eval_test)
      sink()
    }
    
    
    # Now we convert our probabilities into binary values based on a treshold:
    
    # calculate thresholds of models
    
    # The tresholds are all calculated using the training data 
    # They are then applied to the testing data.
    
    
    # 0% omission rate 
    thd1 <- threshold(mod_eval_train, "no_omission")  
    
    # highest TSS
    thd2 <- threshold(mod_eval_train, "spec_sens")
    
    # 50 percent omission:
    thd3 <- threshold(mod_eval_train, stat="sensitivity", sensitivity = 0.5)
    
    
    # plotting points that are above the previously calculated
    # thresholded value
    species_dist <- pred >= thd2
    
    plot(species_dist, main = paste0("Binary prediction (present) - ", tree))
    
    writeRaster(species_dist,
                filename = paste0(mxent_output, "/present_TSS_", tree, ".tif"),
                format="GTIFF")
    
    # lets try predicting for the future dataset:
    
    # create a stack of the bioclim variables on the future data
    
    future_clim_stack <- raster::stack(c(future_bioclim_list, topography, rivers))
    
    # remove years from layer names in future_clim_stack (future data)
    names(future_clim_stack) <- sub("_2080.2100", "", names(future_clim_stack))
    
    # project to study area [raster]
    pred2 <- predict(mod, future_clim_stack)
    plot(pred2, main = paste0("Prediction Probabilities (future) - ", tree))  # plot the continuous prediction
    
    writeRaster(pred2,
                filename = paste0(mxent_output, "/future_PP_", tree, ".tif"),
                format="GTIFF")
    
    future_species_dist <- pred2 >= thd2
    plot(future_species_dist, main = paste0("Binarized (future) - ", tree))
    
    writeRaster(future_species_dist,
                filename = paste0(mxent_output, "/future_TSS_", tree, ".tif"),
                format="GTIFF")
  
    }

  } # end of the run_maxent function.



run_maxent(245)
run_maxent(585)



# GBIF data plotting:
data_dir <- paste0(dirname(path), "/Data")

occ_raw <- read.csv(paste0
                    (data_dir, "/Initial/vegetation/GBIF_Raw/NFI_2015.csv"), 
                    header = TRUE)

# generate a list to contain all the tree species.
tree_species <- list("Quercus suber", "Quercus rotundifolia" ,
                     "Castanea sativa", "Eucalyptus",
                     # "Olea europaea", "Vitis vinifera", "Ceratonia siliqua",
                     "Acacia", "Pinus pinaster", "Pinus pinea")


species <- occ_raw %>% filter(verbatimScientificName == tree_species)

#### plotting ##### 

# Calculate the count and percentage for each species
agg_df <- species %>%
  group_by(verbatimScientificName) %>%
  summarise(count = n()) %>%
  mutate(percentage = count / sum(count) * 100)

# Create the pie chart
ggplot(agg_df, aes(x = "", y = count, fill = paste0(verbatimScientificName, " (", round(percentage, 2), "%)"))) +
  geom_bar(stat = "identity", width = 1, color = "black") +
  coord_polar(theta = "y") +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.text = element_text(size = 14),  # Adjust the size here
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title.x=element_blank(),
    axis.title.y=element_blank()
  ) +
  labs(fill = "Species", title = "Pie Chart of verbatimScientificName")


