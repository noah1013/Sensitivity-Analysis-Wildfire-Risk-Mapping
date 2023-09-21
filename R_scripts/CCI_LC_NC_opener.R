# R script to generate tiff images for each nc file in 
# the CCI LC data set. 

# Code adapted from Boyer, 2017
# found at: https://rpubs.com/boyerag/297592

#### LOAD PACKAGES ####

library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting
library(rstudioapi) # automatically get the directory
library(stringr)
library(terra)
library(sf)
library(tmap)

# Clear the R environment

rm(list = ls())
gc()


# set the directory:

path <- dirname(getActiveDocumentContext()$path)

# If the data is not being loaded, it can be accessed via the 'Data' Folder.

setwd(path)

#### CRACKING OPEN NETCDF FILES ####

CCI_LC_dir <- file.path(dirname(path), "Data/Initial/Vegetation/CCI_LC") 


# get the names of only the .nc files in the directory.

file_list <- list.files(CCI_LC_dir, 
                        pattern = "\\.nc$", 
                        full.names = TRUE)



# create a new directory to hold the data.

output_folder <- paste0(dirname(path), "/Data/Intermediate/Vegetation/CCI_LC")
dir.create(output_folder, recursive = TRUE)


# we will use the Portugal AOI to get the CRS so that we can reproject the 
# raster appropriately.

portugal_path <- paste0(dirname(path), "/Data/Intermediate/References/shapefiles/portugal_cells.shp")

portugal <- st_read(portugal_path, layer = "portugal_cells")

# double checking the CRS
st_crs(portugal)


# for loop to loop through each nc file and process the images into tiffs.

for (file in file_list){
  
  # extracting the name for each year from the file name
  # - the files all have the same structure.
  
  year <- substr(basename(file), 31, 34)
  cat(paste0("\nYear: ", year, "\n"))
  
  # create a directory for each year:
  
  nc_year_dir <- paste0(output_folder, "/", year)
  dir.create(nc_year_dir)
  
  # open the nc file
 
   CCI <- nc_open(file)
  
  # save the print(nc) dump to a text file with the correct name.
  # this is just to save the meta data and view it for further processing
  
  {
    sink(paste0(nc_year_dir, '/metadata.txt'))
    print(CCI)
    sink()
    
  }
  
  # Looking at the metadata, we are only really interested in the following 
  # variables with the following indices:
  
  var_interest <- c(1, 2, 3, 4, 5, 6, 7, 8,
                    9, 11, 12, 13, 14, 15)
  
  
  
  # extract lat and lon coords.
  # time is not needed because the files are already seperated by time.
  
  lon <- ncvar_get(CCI, "lon")
  lat <- ncvar_get(CCI, "lat", verbose = F)
  
  cat (paste0("\nNetCDF variables: ", "\n", "\n"))
  
  # now we run another loop to extract each variable:

  for (i in var_interest) {
    
    # get the name of the variable corresponding to that index.
    var_name <- names(CCI$var)[i]
    print(var_name)
    
    # now we define a bounding box
    # this is because the file is damn large it doesn't fit into my memory.
    # we will only extract values that are within the bounding box.
    
    # define bounding box - portugal
    lon_min <- -9.72
    lon_max <- -6.02
    lat_min <- 36.88
    lat_max <- 42.28
    
    # find indices that fall within the bounding box
    
    lon_ind <- which(lon >= lon_min & lon <= lon_max)
    lat_ind <- which(lat >= lat_min & lat <= lat_max)
    
    # extract the netCDF data for that variable.
    data <- ncvar_get(CCI, CCI$var[[i]], 
                      start = c(min(lon_ind), min(lat_ind), 1), 
                      count = c(length(lon_ind), length(lat_ind), -1))
    
    
    # create a raster from this data
    # remember, the max longitude and latitude needs to be the bounding box
    # and not the entire netcdf
    
    # define the extent
    extent <- c(min(lon[lon_ind]), 
                max(lon[lon_ind]), 
                min(lat[lat_ind]), 
                max(lat[lat_ind]))
    
    nc_raster <- terra::rast(t(data),
                             ext = extent,
                             crs = terra::crs("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0")
    )
    
    
    # reproject the raster:
    nc_raster <- terra::project(nc_raster,  
                         st_crs(portugal)$proj4string, 
                         method = "near") # we don't want the pixel values to change. 
    
  
    # create a file name using the date for this time slice
    
    filename <- paste0(nc_year_dir, "/",  var_name, 
                       "_", year[1], ".tif", sep='')
    
    # save the raster to this file
    writeRaster(nc_raster, filename, overwrite=TRUE)
  
      }
  
  } # end of main loop
  

# function to check integrety of the data:
check_integrity <- function(start, 
                            end) {
  
  input_dir <- paste0(dirname(path), "/Data/Final/Vegetation/CCI_LC")
  
  cci_lc_data <- list.files(input_dir,
                            full.names = TRUE)
  
  for (current_year in start:end) {
    
    
    
    for (yearly_data in cci_lc_data) {
      
      
      
      if (basename(yearly_data) == current_year) {
        
        land_cover_dataset <- list.files(yearly_data,
                                         full.names = TRUE)
      
        raster_path_list <- list()
        
        for (land_cover in land_cover_dataset) {
          
          
          raster_path_list <- append(raster_path_list, land_cover)
          
          
        } # end of running the loop over each land cover variable.
        
        #print(raster_path_list)
        raster_stack <- raster::stack(raster_path_list)
        sum_var <- calc(raster_stack, fun = sum)
        plot(sum_var, main = basename(yearly_data))
        
        visualise_output <- paste0(dirname(path), 
                                   "/Data/trash/cci_lc_avg/cci_avg",
                                   basename(yearly_data), 
                                   ".tif")
        
        writeRaster(sum_var,
                    filename = visualise_output,
                    overwrite = TRUE)
        
      } # end of if statment checking to make sure we are in the current year
    
    
      } # end of looping thorough the start-end years
  
    } # end of looping thourgh the years
  
  } # end of check_integrity function

check_integrity(start=2000, end=2020)

# function to average the CCI_LC data into 20 year averages. 

average_CCI_lC_data<- function(start,
                               end){
  
  input_dir <- paste0(dirname(path), "/Data/Final/Vegetation/CCI_LC")
  
  cci_lc_data <- list.files(input_dir,
                             full.names = TRUE)
  
  # instantiate a dictionary of empty lists for each land cover type
  # these lists will contain the file paths for each land cover type 
  # which will then be converted into a raster and averaged
  variable_list <- list("BARE" = list(),
                        "BUILT" = list(),
                        "GRASS-MAN" = list(),
                        "GRASS-NAT" = list(),
                        "SHRUBS-BD" = list(),
                        "SHRUBS-BE" = list(),
                        "SHRUBS-ND" = list(),
                        "SHRUBS-NE" = list(),
                        "SNOWICE" = list(),
                        "TREES-BD" = list(),
                        "TREES-BE" = list(),
                        "TREES-ND" = list(),
                        "TREES-NE" = list(),
                        "WATER" = list())
  
  # loop over each variable in the climate data directory
  for (yearly_data in cci_lc_data) {
    
    land_cover_dataset <- list.files(yearly_data,
                                     full.names = TRUE)
    
    # iterate from start to end years .
    for (current_year in start:end) {

      if (basename(yearly_data) == current_year){
        
        # run a for loop to loop over each land_cover dataset.
        for (land_cover in land_cover_dataset) {

          # split the name of the dataset. 
          # each file follows a naming convention.
          # e.g. BARE_1992.tif
          # we just want to extract the land cover type
          # so split it by '_' and then extract the first string.
          splitted_file_name <- strsplit(basename(land_cover), split = "_")[[1]]
          extracted_name <- splitted_file_name[1] 
          
          # now all we gotta do is append the file path to dictionary based on 
          # the matching of key names.
          
          variable_list[[basename(extracted_name)]] <- 
            append(variable_list[[basename(extracted_name)]],land_cover)
          
          } # end of for loop to loop over the land cover
        
        } # end of if statement to check for year
      
      } # end of looping over the years from start to endS
    
    } # end of looping over the main directory.
  
  # now that we got the variable list,we can go ahead and conver that list into 
  # raster stacks and compute the mean.
  cci_lc_rast_stack <- lapply(variable_list, raster::stack)
  
  # now we just need to average in 1 shot.
  avg_cci_lc<- lapply(cci_lc_rast_stack, function(stack) {
    calc(stack, fun = function(x) { mean(x, na.rm = TRUE) })
  })
  
  return (avg_cci_lc)
  
  } # end of function

# run that function
avg_cci_lc_present <- average_CCI_lC_data (start=2001, end=2020)

# lets just check the integrity of the code.
# if everything worked well, we should get a raster where each cell is = ~100.

# convert the list to RasterStack.
present_stack <- stack(avg_cci_lc_present)

# sum across our stack
present_sum_raster <- calc(present_stack, fun=sum)

plot(present_sum_raster) # satisfactory


# lets visualize each variable and save it.
# actually, after running the code below we can see that:
# SHRUBS-BE, 
# SHRUBS-ND,
# SNOWICE,
# TREES-BE.
# have no occurence in our study area.
# therefore, when we write the rasters we will just ignore these (because they
# provide no information).
# in addition, we will ignore water because we already have that rivers dataset
# in our model.


export <- function(stackington, 
                   timeframe,
                   ssp_scenario) {
  
  # define a final output for the data:
  final_avg_output <- paste0(dirname(path), "/Data/Final/Vegetation/avg_cci_lc")
  
  if (!dir.exists(final_avg_output)){
    dir.create(final_avg_output)
  
  }
  
  ssp_output <- (paste0(final_avg_output, "/SSP", as.character(ssp_scenario)))
  
  if (!dir.exists(ssp_output)){
    dir.create(ssp_output)
  }
  
  
  for (i in names(stackington)) {
    print (i)
    raster <- stackington[[i]]
    plot(raster, main = i)
    
    if ( i == "SHRUBS-BE" || i == "SHRUBS-ND" ||
         i == "SNOWICE" || i == "TREES-BE" || i == "WATER") {
      
      # do nothing
      
    } else {
      
      # save that shit to disc with the appropriate name.
      writeRaster(raster,
                  filename = paste0(ssp_output, "/", timeframe, "_",
                                    i, "_avg.tif"),
                  overwrite = TRUE)
      
    
      } # end of if else statement

    } # end of for loop.

  } # end of function

export(avg_cci_lc_present, timeframe = "present", 
       ssp_scenario = 245) # because historical we don't really need to add this. 



