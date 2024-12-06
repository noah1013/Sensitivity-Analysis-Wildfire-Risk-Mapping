# R script to generate tiff images for each nc file in 
# the CCI LC data set. 

# Code adapted from Boyer, 2017
# found at: https://rpubs.com/boyerag/297592

#### LOAD PACKAGES ####

library(ncdf4) # package for netcdf manipulation
# library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting
# library(rstudioapi) # automatically get the directory
library(stringr)
library(terra) # package for raster manipulation
library(sf)
library(tmap)
library(raster)

# clear the R environment

rm(list = ls())
gc()


# set the directory:
path <- getwd()

# The current path should be the parent diretory of the project:
#   a/b/c/Sensitivity-Analysis-Wildfire-Risk-Mapping

# if the data is not being loaded, it can be accessed via the 'Data' Folder.
# print(path)
setwd(path)



#### FUNCTIONS ####

# function to crack open NETCDF files and compute monthly averages:
open_cmip6 <- function(timeframe) {
  # iterate over the ssp folder list:
  for (ssp_folder in ssp_list){ # (1)
    ssp_folder = ssp_list[1]

    print(ssp_folder)

    cat(paste0("\nScenario: ", basename(ssp_folder), "\n"))

    # now list the climate variables:
    variable_list <- list.files(ssp_folder,
                                full.names = TRUE)

    # also create a directory to hold the data for each SSP scenario:
    ssp_output_folder <- paste0(output_folder, basename(ssp_folder))
    print(ssp_output_folder)
    # print(output_folder)
    
    dir.create(ssp_output_folder)

    # iterate over the climate variables in each ssp folder
    for (folder in variable_list){
      cat(paste0("\nCMIP6 Variable: ", basename(folder), "\n"))

      # create a folder to hold the processed data for each variable
      new_variable_dir <- paste0(ssp_output_folder, "/", basename(folder))
      # create a folder to hold the meta_data
      metadata_dir <- paste0(new_variable_dir, "/meta_data")

      # if statement to make sure that the folder is not overwritten with each
      # iteration:
      if (!(dir.exists(new_variable_dir))) { # (3)
        # create the metaddata and its parent directory if they haven't already been created
        dir.create(metadata_dir, recursive = TRUE)
      }

        # store the nc files in a list to iterate over:
      variable_dir = list.files(folder,
                                pattern = "\\.nc$",
                                full.names = TRUE)

      # now loop over each nc file within each variable folder:
      for (nc in variable_dir) { # (5)
        cmip6 <- nc_open(nc)

        # I want to save the era which will require splitting the name of the file
          
        # we will split the name by underscores
        # (bare in mind we know the structure of the nc file's naming convention)
        parts <- strsplit(basename(nc), "_")[[1]]

        # extract the years from the last underscore
        year_start <- substr(parts[length(parts)], 1, 4)
        year_end <- substr(parts[length(parts)], 10, 13)

        # combine years
        era <- paste0(year_start, "_", year_end)

        # now we can save the print(nc) dump to a text file with the correct era.
        # this is just to save the meta data and view it for further processing.
        { # (6)
          sink(paste0(paste0(metadata_dir, "/", era, '_metadata.txt')))
          print(cmip6)
          sink()
        } # end of sink (6) 

        # extract the name of the variable - if its pr its 4 else 5:
        # if (basename(folder) == 'pr') {
        #   var_name <- names(cmip6$var)[2]
        # } else {
        #   var_name <- names(cmip6$var)[3]
        # }
        var_name <- names(cmip6$var)[1]


        # extract lat and lon coords and time (in days from 1850-01-01: 00:00)
        lon <- ncvar_get(cmip6, "lon")
        lat <- ncvar_get(cmip6, "lat", verbose = F)
        time <- ncvar_get(cmip6, "time")
        
        
        # fillvalue and missing value is the same according to the meta data
        print(var_name)

        fillvalue <- ncatt_get(cmip6, var_name, "missing_value")
        cat(paste0("\nMissing Value: ", fillvalue[2], "\n"))

        # convert the days into actual dates
        # the format is days since 1850. 
        # also, the ISPL cmip6 model runs on a standard calendar so less processing
        # historical data is days since 1850-01-01
        # future data is days since 2015-01-10 (according to the meta data)
        
        if (timeframe == "historical") {
          dates <- as.Date(time, origin = "1850-01-01")
        } else if (timeframe == "future") {
          dates <- as.Date(time, origin = "2015-01-01")
        }

        # the data has a daily temporal resolution
        # it also has a global spatial extent
        # therefore, to reduce processing time and also be memory efficient,
        # we will go ahead and get the climate data for our region of interest
        # (portugal) only.
        # we will also aggregate the data as monthly averages.
        # lastly we will get historic data that spans only from 1992 - 2021
        # which covers the timeframe for the CCI lC dataset as well as the 
        # modis wildfire dataset.
        
        
        # define the years for aggregation:
        if (timeframe == "historical") {
          # years_of_interest <- lapply(list(1992:2021)[[1]], as.character) # TRISUNG OG CODE
          years_of_interest <- lapply(list(2001:2014)[[1]], as.character)
          # years_of_interest <- lapply(list(2001)[[1]], as.character)
        } else if (timeframe == 'future') {
          # years_of_interest <- lapply(list(2080:2100)[[1]], as.character) # TRISUNG OG CODE
          years_of_interest <- lapply(list(2087:2100)[[1]], as.character) 
        }
        
        # define bounding box - Portugal -10.27,36.52,-5.49,42.61
        lon_min <- -10.27
        lon_max <- -5.49
        lat_min <- 36.52
        lat_max <- 42.61

        # Convert -180 to 180 longitude bounds to 0 to 360 convention
        # as seen on the meta data.
        # basically, the meta data doesn't use negative values for longitude
        # which we can see for the Portugal dataset.
        
        # this is in case a different study region is used.
        
        lon_min_0_360 <- ifelse(lon_min < 0, lon_min + 360, lon_min)
        lon_max_0_360 <- ifelse(lon_max < 0, lon_max + 360, lon_max)
        
        # find indices that fall within the bounding box
        lon_ind <- which(lon >= lon_min_0_360 & lon <= lon_max_0_360)
        lat_ind <- which(lat >= lat_min & lat <= lat_max)

        # now run another for loop to slice the data by year:
        # extract years and months for the entire dates vector
        years <- format(dates, "%Y")
        months <- format(dates, "%m")

        # This section of code can be a bit convoluted but the idea is as follows:
          
        # 1. we keep track of the current year and month, initialised from our
        #    years and months list.
        # 2. we then loop through each time slice in the net cdf file.
        # 3. after that, we check if the current year is in the years of interest
        #    list we defined previously.
        # 4. if it is, then we will check if the current year and current month 
        #    is equal to the year/month in the value from the lists of that iteration.
        # 5. if it isn't, then it means there's been a change in the month or year
        #    and so we will need to process the last month's raster and save it 
        # 6. if it is, however, we perform the netcdf processing (so extracting the 
        #    data and converting it to a raster).
        # 7. we also ensure that when we get to the end of the loop, the raster  
        #    stack is processed and saved so that we can get the last month from the 
        #    year's data.
        
        
        # list of the monthly rasters
        monthly_rasters <- list()
        
        # this is just for the print messages
        first_iteration <- TRUE

        # loop through each time slice in the netCDF file
        for (i in 1:length(dates)) { # (7)
          
          
          # if the current year is not of interest, skip this iteration
          if (!(years[i] %in% years_of_interest)) { # (8)
            next
          } # (8)
          
          
          # if the month or years are not equal to the last iteration, or if
          # it is the first iteration
          if (first_iteration || years[i] != current_year || months[i] != current_month) { # (9)
            
            # Check for the first iteration
            if (first_iteration) {
              current_year <- years[i]
              current_month <- months[i]
              first_iteration <- FALSE
            }
            
            cat("\nCurrent year:", years[i],"\n")
            cat("Current month:", months[i],"\n")
            
            # it means there's been a change in either the month or year.
            # this means we've moved on to the next month, and so the data needs
            # to be processed (remember we are aggregating as monthly avg).
            if (!first_iteration && length(monthly_rasters) > 0) { # (10)
              
              # raster processing procedure: 
              
              # stack the rasters using terra's stacking functionality instead of 
              # raster::stack (incompatible)
              # ref - Matifou (2022)
              # found at - https://stackoverflow.com/questions/71213802/terra-equivalent-for-rasterstack
              monthly_stack <- rast(c(monthly_rasters))
              
              # compute the average across each cell
              # ref - Bollans (2022)
              # found at - https://gis.stackexchange.com/questions/430938/extracting-mean-of-multiple-spatrasters-using-terra
              monthly_avg <- app(monthly_stack, fun = mean)
              
              # create a year directory:
              year_output_dir <- paste0(new_variable_dir, "/", current_year)
              
              # save the monthly average raster
              if (!dir.exists(year_output_dir)) { # (11)
                dir.create(year_output_dir)
              } # (11)
              
              # save the monthly average raster with the appropriate name 
              writeRaster(monthly_avg, 
                          filename = paste0(year_output_dir,
                                            "/",
                                            var_name,
                                            "_",
                                            current_month,
                                            "_",
                                            "mean.tif"),
                          overwrite = TRUE)
              
              # reset for the new month/year
              monthly_rasters <- list()
              
              # update the current month and year
              current_month <- months[i]
              current_year <- years[i]
              
            } # end of if statement which checks if the raster list is 
            # greater than 0 (10)
            
          } # end of if statement to see if month/year is equal to last 
          # iteration (9)
          
          # there are some time days where no data exists.
          # probably due to erroneous results, they were removed during the 
          # post processing step.
          
          # following code ensures that these errors are caught and 
          # handled gracefully along with other further processing:
          tryCatch({
            
            # NETCDF PROCESSING:
            
            # extract the netCDF data for that variable (its stored in index
            # 5 according to the meta data for all except precipitation
            # (which we saved earlier).
            
            
            # if we are dealing with pr (precipitation) then its variable 4
            # if (basename(folder) == 'pr') {
              
            #   # remember we are subsetting data to be memory efficient:
            #   # so we are only extracting the netcdf file for our region of interest
            #   # and of the current daily time slice that corresponds to our 
            #   # month of interest.
              
            #   data <- ncvar_get(cmip6, cmip6$var[[2]], 
            #                     start = c(min(lon_ind), min(lat_ind), i), 
            #                     count = c(length(lon_ind), length(lat_ind), 1))
              
              
            #   # for everything else, its 5
            # } else {
              
            #   data <- ncvar_get(cmip6, cmip6$var[[3]], 
            #                     start = c(min(lon_ind), min(lat_ind), i), 
            #                     count = c(length(lon_ind), length(lat_ind), 1))
            # } # end of if else block
            
            data <- ncvar_get(cmip6, cmip6$var[[1]], 
                              start = c(min(lon_ind), min(lat_ind), i), 
                              count = c(length(lon_ind), length(lat_ind), 1))

            # fill in the missing values
            data[data == fillvalue$value] <- NA
            
            # now, we want to convert the units of the variables to something that 
            # is both easier to interpret for humans and also for use in converting 
            # or average monthly data into yearly bioclimatic variables.
            
            # according to the metadata, these are the units for each of our 
            # variables:
            
            # hurs - daily average relative humidity in percentage
            # pr - daily average precipitation flux in kg m-2 s-1
            # tas - daily average near surface air temperature in K
            # tasmax - daily maximum near surface air temperature in K
            # tasmin - daily minimum near surface air temperature in K
            # wind - daily average near surface wind speed in m s-1
            
            # so looking at all of this, we can see that the only ones that need 
            # to be converted are precipitation and the temperature variables.
            
            if (basename(folder) == 'pr') {
              
              # precipitation flux can be converted to mm easily:
              
              # 1 mm = 1 liter/m^2
              # 1 litre = 1 kg
              # 1 hour = 3600 seconds
              # therefore, 3600 s x 24 hr (1 day) = 86400 s
              
              # Kad, Pratik (2019)
              # https://www.researchgate.net/post/How-do-I-convert-ERA-Interim-precipitation-estimates-from-kg-m2-s-to-mm-day/5d2ed9902ba3a1c650293171/citation/download
              
              data <- data * 86400
              
            } else if (basename(folder) == 'tas' || 
                        basename(folder) == 'tasmax'||
                        basename(folder) == 'tasmin') {
              
              # converting kelvin to temperature just involves subtracting 
              # 273.15
              data <- data - 273.15
              
            } else {
              
              # do nothing for the other variables
              
            }
            
            
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
            
            # the data was read 
            flipped_raster <- terra::flip(nc_raster, direction="vertical")
            
            # reproject the raster:
            daily_raster <- project(flipped_raster,
                                    st_crs(portugal)$proj4string,
                                    method = "near") 
            # we don't want the pixel values to change.
            
            plot(daily_raster, main = paste0(years[i]," ", months[i]))
            
            monthly_rasters <- append(monthly_rasters, list(daily_raster))
            
            
          }, error = function(e) { # error handling
            
            cat("Error encountered for time slice", i, "- Skipping this slice.\n")
          })
        }

        # handle the last month after the loop
        if (length(monthly_rasters) > 0) { # (12)
          # raster aggregation procedure (as defined above):
          monthly_stack <- rast(c(monthly_rasters))
          monthly_avg <- app(monthly_stack, fun = mean)
          
          # recalculate year_output_dir before writing the last month's raster
          year_output_dir <- paste0(new_variable_dir, "/", current_year)
          
          if (!dir.exists(year_output_dir)) { # (13)
            dir.create(year_output_dir)
          } # (13)
          
          writeRaster(monthly_avg, 
                      filename = paste0(year_output_dir,
                                        "/",
                                        var_name,
                                        "_",
                                        current_month,
                                        "_",
                                        "mean.tif"),
                      overwrite = TRUE)
        }
      }
    }
  }
}

# function to average rasters across our study period #

average_climate_data <- function(fire_season, ssp_scenario){
  climate_data_path <- paste0(path, "/Data/Intermediate/climate_data/SSP",
                              as.character(ssp_scenario))
  
  climate_data <- list.files(climate_data_path,
                             full.names = TRUE)

                             
  
  # instantiate a dictionary of empty lists for each variable.
  # these lists will contain the monthly weather variables
  # that correspond to the fire season for each year
  # these will then be averaged.
  variable_list <- list(hurs = list(),
                        pr = list(),
                        tas = list(),
                        tasmax = list(),
                        tasmin = list(),
                        wind = list())

  # loop over each variable in the climate data directory

  # print(climate_data_path)
  for (variable in climate_data) {
    yearly_vars <- list.files(variable, full.names = TRUE)
    # print(variable)
    
    # loop over the key in the fire season dictionary
    for (key in names(fire_season)) {
      
      # now loop through the years in the cmip6 yearly data
      for (data in yearly_vars){
        
        if (basename(data) == key){
          
          # list the files
          monthly_agg_list <- list.files(data, full.names = TRUE)
          
          for (monthly_agg in monthly_agg_list) {


            # split the string of the file name to extract its month
            splitted_file_name <- strsplit(basename(monthly_agg), split = "_")[[1]]
            
            # because its the second value when you split the string
            # example file naming convention: hursAdjust_01_mean.tif
            extracted_month <- splitted_file_name[2] 
            
            # loop over the list which contains the fire months for each year
            # in the dictionary
            for (value in fire_season[[key]]) { 
              
              # now check to see the months in the fire season that we want
              if (extracted_month == value) {
                
                # if the condition is met, then append the value to that list!
                # we will use the variable name to map this precisely to the
                # variable in the list
                variable_list[[basename(variable)]] <- 
                  append(variable_list[[basename(variable)]],
                         monthly_agg)   
              } # end of the if condition
              
            } # end of looping through the list in the current  fire season
            # iteration.
            
            
          } # end of for loop to iterate over the monthly data for each year
          
        } # end of if statement to check if the years in the fire season
        # dictionary are equal to the year in the cmip6 data.
        
      }# end of for loop to iterate over the CMIP6 yearly data
      
      
    } # end of for loop over the keys in the fire_season dictionary
    
  } # end of for loop to iterate over each variable
  
  # at this point, we have a dictionary for each variable which contains all the 
  # monthly climate data that correspond to the fire season for each year. 
  # now all that's left is to go ahead and convert this  into a raster stack
  # with the function as the mean.
  # print(variable_list)
  clim_rast_stack <- lapply(variable_list, raster::stack)
  
  # now we just need to average in 1 shot.
  avg_fire_season_stackington <- lapply(clim_rast_stack, function(stack) {
    calc(stack, fun = mean)
  })
  
  # save the file.  
  if (!dir.exists(cmip6_fire_season_output)) {
    dir.create(cmip6_fire_season_output)
  }
  
  cmip6_ssp <- paste0(cmip6_fire_season_output, "/SSP", as.character(ssp_scenario))
  
  if (!dir.exists(cmip6_ssp)) {
    dir.create(cmip6_ssp)
  }
  
  # access the first and last key in the fire season dictionary to get our era.
  # we do this by accessing the indices of the keys
  start <- names(fire_season)[1]
  end <- names(fire_season)[length(fire_season)]
  
  for (key in names(avg_fire_season_stackington)){
    
    variable_rast <- avg_fire_season_stackington[[key]]
    
    writeRaster(variable_rast,
                filename = paste0(cmip6_ssp, "/", key, "_", start, "-", end, ".tif"),
                overwrite = TRUE)
    
  } # end of for loop to loop through the variables
  
} # end of function

##### Generating the datasets #####

# we will use the Portugal AOI to get the CRS so that we can reproject the 
# raster appropriately.

portugal_path <- paste0(path, "/Data/Intermediate/References/shapefiles/portugal_cells.shp")

portugal <- st_read(portugal_path, layer = "portugal_cells")

# double checking the CRS
st_crs(portugal)

# directory to the cmip6 folder
cmip6_dir <- file.path(path, "Data/Initial/climate_data") 

# there are 6 variables for 2 different (2 and 5) SSP scenarios:

# hurs - near-surface relative humidity
# pr - total precipitation
# tas - near-surface air temperature
# tasmax - daily maximum near-surface air temperature
# tasmin - daily minimum near-surface air temperature
# wind - wind speed

# hold the variable folder name within a list to iterate over:

ssp_list <- list.files(cmip6_dir,
                       full.names = TRUE)

# create a new directory to hold the data.

output_folder <- paste0(path, "/Data/Intermediate/climate_data/")
if (dir.exists(output_folder)) {
  unlink(output_folder, recursive = TRUE, force = TRUE)
} 
dir.create(output_folder, recursive = TRUE)

cmip6_fire_season_output <- paste0(path, "/Data/Intermediate/fs_climate_data")
if (dir.exists(cmip6_fire_season_output)){
  unlink(cmip6_fire_season_output, recursive = TRUE, force = TRUE)
}

topography <- list.files(paste0(path, "/Data/Final/Topography/Topo_processed"), full.names = TRUE)


# now compute monthly averages for each year from the cmip6 dataset.
open_cmip6(timeframe = "historical")
open_cmip6(timeframe = "future")

# Generating the fire season dictionary from the txt file #

# so the fire season seems to fluctuate 
# mostly centered on June, July, August, September
# however, there are a few months outside of these months where there have been 
# significant wildfire activity.
# these have all been saved in a text file after a quick analysis was performed
# on python (75th percentile)
# now we want to export this data and save it to a dictionary



# import the data:
fire_months <- readLines(paste0(path, "/Data/stats/yearly_fire_seasons/fire_seasons.txt"))

print(fire_months)


# we can use the " : " delimiter to separate years from months
splitted <- strsplit(fire_months, " : ")



# now extracting the years and months
years <- sapply(splitted, "[[", 1)
months <- strsplit(sapply(splitted, "[[", 2), ", ")

# Creating a list (similar to dictionary in other languages)
fire_season <- setNames(as.list(months), years)

# now lets convert the months into numbers.
# this is because our cmip6 monthly aggregated data is stored in this format.

month_num <- list(Jan = "01", Feb = "02", Mar = "03", Apr = "04",
                  May = "05", Jun = "06", Jul = "07", Aug = "08",
                  Sep = "09", Oct = "10", Nov = "11", Dec = "12")

fire_season <- lapply(fire_season, function(months) {
  unname(sapply(months, function(month) month_num[[month]]))
})

cat("\nYour computed historical fire-seasons:\n")
print(fire_season)

# define the year for the future fire season
future_fire_season <- list(
                          #  '2080' = c("06", "07","08", "09", "10"),
                          #  '2081' = c("06", "07","08", "09", "10"),
                          #  '2082' = c("06", "07","08", "09", "10"),
                          #  '2083' = c("06", "07","08", "09", "10"),
                          #  '2084' = c("06", "07","08", "09", "10"),
                          #  '2085' = c("06", "07","08", "09", "10"),
                          #  '2086' = c("06", "07","08", "09", "10"),
                           '2087' = c("06", "07","08", "09", "10"),
                           '2088' = c("06", "07","08", "09", "10"),
                           '2089' = c("06", "07","08", "09", "10"),
                           '2090' = c("06", "07","08", "09", "10"),
                           '2091' = c("06", "07","08", "09", "10"),
                           '2092' = c("06", "07","08", "09", "10"),
                           '2093' = c("06", "07","08", "09", "10"),
                           '2094' = c("06", "07","08", "09", "10"),
                           '2095' = c("06", "07","08", "09", "10"),
                           '2096' = c("06", "07","08", "09", "10"),
                           '2097' = c("06", "07","08", "09", "10"),
                           '2098' = c("06", "07","08", "09", "10"),
                           '2099' = c("06", "07","08", "09", "10"),
                           '2100' = c("06", "07","08", "09", "10"))




# run the function
average_climate_data(fire_season, 245)
average_climate_data(future_fire_season, 245)
# average_climate_data(future_fire_season, 585)

