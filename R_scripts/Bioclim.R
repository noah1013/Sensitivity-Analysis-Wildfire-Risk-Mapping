# BIOCLIM tiff generator and clipper.

#### LOAD PACKAGES ####

library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting
library(rstudioapi) # automatically get the directory
library(stringr)
library(dismo)

# Clear the R environment
rm(list = ls())
gc()


# set the directory:
path <- dirname(getActiveDocumentContext()$path)
# If the data is not being loaded, it can be accessed via the 'Data' Folder.
setwd(path)

##### COMPUTATION OF YEARLY BIOCLIMATIC VARIABLES #####


# function to generate yearly biovars 

generate_biovars <- function(ssp_scenario){
  
  # just to separate the scenarios for processing
  if (ssp_scenario == 245){
    
    SSP_dir <- paste0(dirname(path), "/Data/Intermediate/climate_data/SSP245")

    } else if (ssp_scenario == 585) {
    
      SSP_dir <- paste0(dirname(path), "/Data/Intermediate/climate_data/SSP585")

      } # end of else if statement
  
  tmax_dir <- paste0(SSP_dir, "/tasmax")
  tmin_dir <- paste0(SSP_dir, "/tasmin")
  pr_dir <- paste0(SSP_dir, "/pr")
  
  # create an output directory to hold the bioclimate variables:
  bioclim_output_dir <- paste0(dirname(path), 
                               "/Data/Intermediate/BioClim/SSP", 
                               as.character(ssp_scenario))
  
  dir.create(bioclim_output_dir,
             recursive = TRUE)
  
  tmax_year <- list.files(tmax_dir)
  tmin_year <- list.files(tmin_dir)
  pr_year <- list.files(pr_dir)
  
  # check if the lengths of the lists are equal; if not, there might be an issue.
  if (length(tmax_year) != length(tmin_year) || 
      length(tmax_year) != length(pr_year)) {
    
    stop("The directories have a different number of files")
    
  }
  
  # now run a for loop to iterate over the years in these 3 directories.
  for (i in seq_along(tmax_year)){
    
    # check to make sure they are all the same year.
    if (basename(tmax_year[[i]]) != basename(tmin_year[[i]]) || 
        basename(tmax_year[[i]]) != basename(pr_year[[i]])){
      
      cat("\nThere seems to be an issue with the ordering of your files.\n
          Pleae double check to ensure that the average monthly data have been
          generated correctly.")
      
      # exit the loop
      break
      
    } else if (basename(tmax_year[[i]]) == "meta_data"){
      
      next # skip that iteration
      
    } else {
      
      cat(paste0("\nCurrent Year:", tmax_year[[i]]))
      
      # let us quickly create a directory to hold each year's bioclim data.
      yearly_bioclim_output_dir <- paste0(bioclim_output_dir, 
                                          "/", basename(tmax_year[[i]]))
      
      dir.create(yearly_bioclim_output_dir)
      
      # now we store all the monthly data into a list.
      tmax_list <- list.files(paste0(tmax_dir, "/", tmax_year[[i]]), full.names = TRUE)
      tmin_list <- list.files(paste0(tmin_dir, "/", tmin_year[[i]]), full.names = TRUE)
      pr_list <- list.files(paste0(pr_dir, "/", pr_year[[i]]), full.names = TRUE)
      
      # and then we generate a phat raster stack for these three variables.
      
      tmax_stack <- raster::stack(tmax_list)
      tmin_stack <- raster::stack(tmin_list)
      pr_stack <- raster::stack(pr_list)
      
      # generate the bioclimatic variables using dismo biovars.
      bioclim <- biovars(prec = pr_stack,
                         tmin = tmin_stack,
                         tmax = tmax_stack)
      
      cat("\nBiovars computed.")
      
      print(class(bioclim))
      
      # Rename and save each layer
      for (j in 1:nlayers(bioclim)) {
        
        # get the layer for each biovar
        biovar <- bioclim[[j]]
        bio_var_suffix <- paste0(names(biovar), "_", basename(tmax_year[[i]]))
        writeRaster(biovar, 
                    filename = paste0(yearly_bioclim_output_dir, "/", bio_var_suffix, ".tif"), 
                    overwrite=TRUE)
        
      } # end of for loop to save raster file with new name
      
    } # end of else statement to check if we have the correct format
    
  } # end of for loop to iterate over each directory 
  
} # end of generate_biovars function

# function to average biovars for a specific time frame. 
# this is for maxent if we end up choosing it:
average_biovars <- function(start,
                            end, 
                            ssp_scenario){
  
  if (ssp_scenario == 245){
    
    bc_dir <- paste0(dirname(path), "/Data/Intermediate/BioClim/SSP245")
  
    } else if (ssp_scenario == 585){
    
      bc_dir <- paste0(dirname(path), "/Data/Intermediate/BioClim/SSP585")
  
      }
    
  bc_folders <- list.files(bc_dir, full.names = TRUE)
  
  
  # this is a bit of a shit way to do this but currently i can't 
  # think of anything else: 
  
  # there are 19 bio_variables
  
  bioclim_stack <- list(Bio_01 = list(),
                        Bio_02 = list(),
                        Bio_03 = list(),
                        Bio_04 = list(),
                        Bio_05 = list(),
                        Bio_06 = list(),
                        Bio_07 = list(),
                        Bio_08 = list(),
                        Bio_09 = list(),
                        Bio_10 = list(),
                        Bio_11 = list(),
                        Bio_12 = list(),
                        Bio_13 = list(),
                        Bio_14 = list(),
                        Bio_15 = list(),
                        Bio_16 = list(),
                        Bio_17 = list(),
                        Bio_18 = list(),
                        Bio_19 = list())
  
  # for loop to extract the years that correspond to our era
  for(i in start:end) {
    
    # loop over each year in the bioclim directory
    for(folder in bc_folders) {
      
      # check if the year in the bioclim directory is the same as the current 
      # iteration
      if (basename(folder) == as.character(i)){
        
        # list the files
        bioclim_list <- list.files(folder,
                                   full.names = TRUE)

        
        # now iterate over each bioclimatic variable and append them to their 
        # respective key in the list.
        
        for (bioclim in bioclim_list) {
       
          
          # not the prettiest way of doing it but we will put the biovars
          # 1 by 1 into their respective spots in the dictionary. 
          
          if (grepl('bio1_', basename(bioclim))) { 
            
            bioclim_stack$Bio_01 <- c(bioclim_stack$Bio_01, bioclim)
            
          } else if (grepl('bio2_', basename(bioclim))){
            
            bioclim_stack$Bio_02 <- c(bioclim_stack$Bio_02, bioclim)
            
          } else if (grepl('bio3_', basename(bioclim))){
            
            bioclim_stack$Bio_03 <- c(bioclim_stack$Bio_03, bioclim)
            
          } else if (grepl('bio4_', basename(bioclim))){
            
            bioclim_stack$Bio_04 <- c(bioclim_stack$Bio_04, bioclim)
            
          } else if (grepl('bio5_', basename(bioclim))){
            
            bioclim_stack$Bio_05 <- c(bioclim_stack$Bio_05, bioclim)
            
          } else if (grepl('bio6_', basename(bioclim))){
            
            bioclim_stack$Bio_06 <- c(bioclim_stack$Bio_06, bioclim)
            
          } else if (grepl('bio7_', basename(bioclim))){
            
            bioclim_stack$Bio_07 <- c(bioclim_stack$Bio_07, bioclim)
            
          } else if (grepl('bio8_', basename(bioclim))){
            
            bioclim_stack$Bio_08 <- c(bioclim_stack$Bio_08, bioclim)
            
          } else if (grepl('bio9_', basename(bioclim))){
            
            bioclim_stack$Bio_09 <- c(bioclim_stack$Bio_09, bioclim)
            
          } else if (grepl('bio10_', basename(bioclim))){
            
            bioclim_stack$Bio_10 <- c(bioclim_stack$Bio_10, bioclim)
            
          } else if (grepl('bio11_', basename(bioclim))){
            
            bioclim_stack$Bio_11 <- c(bioclim_stack$Bio_11, bioclim)
            
          } else if (grepl('bio12_', basename(bioclim))){
            
            bioclim_stack$Bio_12 <- c(bioclim_stack$Bio_12, bioclim)
            
          } else if (grepl('bio13_', basename(bioclim))){
            
            bioclim_stack$Bio_13 <- c(bioclim_stack$Bio_13, bioclim)
            
          } else if (grepl('bio14_', basename(bioclim))){
            
            bioclim_stack$Bio_14 <- c(bioclim_stack$Bio_14, bioclim)
            
          } else if (grepl('bio15_', basename(bioclim))){
            
            bioclim_stack$Bio_15 <- c(bioclim_stack$Bio_15, bioclim)
            
          } else if (grepl('bio16_', basename(bioclim))){
            
            bioclim_stack$Bio_16 <- c(bioclim_stack$Bio_16, bioclim)
            
          } else if (grepl('bio17_', basename(bioclim))){
            
            bioclim_stack$Bio_17 <- c(bioclim_stack$Bio_17, bioclim)
            
          } else if (grepl('bio18_', basename(bioclim))){
            
            bioclim_stack$Bio_18 <- c(bioclim_stack$Bio_18, bioclim)
            
          } else if (grepl('bio19_', basename(bioclim))){
            
            bioclim_stack$Bio_19 <- c(bioclim_stack$Bio_19, bioclim)
            
            } # end of segregating bioclim data based on biovars
          
          } # end of looping over bioclim in bioclim list
        
        } # end of checking if the name of the folder is in the era
      
      } # end of iterating through each year in the bioclim list
  
    } # end of iterating though the start and end date
  
  # at this point, we should have a dictionary where each biovar is separated
  # by their biovar id instead of by year.
  # we can apply a raster stack function to each value in the 
  # dictionary
  bioclim_rast_stack <- lapply(bioclim_stack, raster::stack)
  
  # now we just need to average it over the years:
  avg_bioclims <- lapply(bioclim_rast_stack, function(stack) {
    calc(stack, fun = mean)
    })
  
  # create a new directory to hold this:
  averaged_output <- paste0(dirname(path), 
                            "/Data/Intermediate/Averaged_data")
  
  if (!dir.exists(averaged_output)){
    dir.create(averaged_output)
  }
  
  print(averaged_output)
  
  avg_bioclim_output <- paste0(averaged_output,
                               "/",
                               "SSP",
                               as.character(ssp_scenario),
                               "/Bioclim_avg")
  
  
  if (!dir.exists(avg_bioclim_output)){
    dir.create(avg_bioclim_output, recursive = TRUE)
  }
  
  print(avg_bioclim_output)
  
  
  # loop over every key in the list and save the raster in the Bioclim average
  # directory:
  
  for (key in names(avg_bioclims)){
    
    cat(paste0("\nSaving ", key , " averaged over years ", start, "-", end, "." ))
    
    # we will have separate directories for years because we will put both the future 
    # and past data in here.
    final_bioclim_output_path <- paste0(avg_bioclim_output, "/", key)
    
    if (!dir.exists(final_bioclim_output_path)){
      dir.create(final_bioclim_output_path)
    }
    
    # extract the raster from that iteration  
    bioclim_avg_raster <- avg_bioclims[[key]]
    
    raster::writeRaster(bioclim_avg_raster,
                        filename = paste0(final_bioclim_output_path, 
                                          "/", 
                                          key,
                                          "_",
                                          start, "-", end,
                                          ".tif"),
                        overwrite = TRUE)
      }
  
  } # end of average_biovars function
 
# lets get the biovars for each year using the custom function:
generate_biovars(245)
generate_biovars(585)

# average the biovars over our study region 

# 1. historical SSP245:
average_biovars(start=2001,
                end = 2021,
                ssp_scenario = 245)

# 2. future SSP245
average_biovars(start=2080,
                end = 2100,
                ssp_scenario = 245)

# 2. future SSP585
average_biovars(start=2080,
                end = 2100,
                ssp_scenario = 585)


