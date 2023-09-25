# R code to prepare the data for machine learning algorithm.

library(raster)
library(sf)
library(terra)
library(rstudioapi)

# Clear the R environment
rm(list = ls())
gc()

# set the directory:
path <- dirname(getActiveDocumentContext()$path)

# If the data is not being loaded, it can be accessed via the 'Data' Folder.
setwd(path)

#### functions ####

# function to loop through the raster data and assign cell pixel values to 
# the polygons for our area of interest

data_fusion <- function(data_path, 
                        AOI, 
                        status,
                        ssp_scenario){
  
    cat("\nCurrent Dataset: ", basename(data_path), "\n")
  
  
  
  # list all the files in the respective directory:
  # this is just there to handle the climate data because we will have many 
  # different scenarios.
  if (ssp_scenario == 245){
    
    data_dir <- list.files(data_path, 
                           full.names = TRUE,
                           pattern = paste0("SSP", ssp_scenario))
    
  } 
  
  else if (ssp_scenario == 585) {
    
    data_dir <- list.files(data_path, 
                           full.names = TRUE,
                           pattern = paste0("SSP", ssp_scenario))
    
  } else {
    
    data_dir <- list.files(data_path, 
                           full.names = TRUE)
    
  
    }
  
  # instantiating an empty list so that we can stack them later.
  raster_stack_list <- list()
  
  # also instantiate an empty list to hold the names for each attribute table.
  field_names <- list()
  
  # loop over the re-sampled data directories.
  # we've made it so that they have similar directory structures
  # therefore, this makes the code reusable for most of our data.
  
  for (folder in data_dir){
    
    # now loop over files that have the .tif or .tiff extension in that 
    # directory.
    folder_list <- list.files(folder,
                              full.names = TRUE,
                              pattern = "\\.(tif|tiff)$")
    
    
    for (file in folder_list){

      raster_stack_list<- append(raster_stack_list, file)
      
      # get the name of the folder into a list because that's going to go in the 
      # name of the attribute tables.
      # not the entire path, just the base name.
      
      field_names <- append(field_names, basename(file))
      
      } # end of for loop that loops over each file for each year.
    
    } # end of for loop gets a list of each stack.
  
  # clean up the field names we are dealing with the topography data.
  field_names <- sub("East_Mediterranean_", "", field_names)
  field_names <- sub("\\.tiff?$", "", field_names)
  
  # if we encounter a '_PP_', it means that we are dealing with prediction
  # probabilities in the maxent output. 
  # we won't be using this information, so discard it from the list.
  maxent_rmv_rast <- grepl("_PP_", raster_stack_list)
  maxent_rmv_list <- grepl("_PP_", field_names)
  
  raster_stack_list <- raster_stack_list[!maxent_rmv_rast]
  field_names <- field_names[!maxent_rmv_list]

    
  # here we will define whether we want historical or future climate data
  # in the stack.
  # for the climate data, this is given in numbers
  # for the vegetation data, this is indicated by 'present' or 'future'
    
  if (status == 'historical') {
    
    # CLIMATE DATA:  
    
    # identify values in the list that is not related to historical data
    discard_raster <- grepl("_2080-2100.tif$", raster_stack_list)
    discard_field_names <- grepl("_2080-2100$", field_names)
      
    # then remove it using the ! operator
    raster_stack_list <- raster_stack_list[!discard_raster]
    field_names <- field_names[!discard_field_names]
      
    
    # MAXENT OUTPUTS:
    # anything that starts with future will be discarded.
    discard_maxent_future_rast <- grepl("future", raster_stack_list)
    discard_maxent_field_names <- grepl("future", field_names)
    
    # filter it out.
    raster_stack_list <- raster_stack_list[!discard_maxent_future_rast]
    field_names <- field_names[!discard_maxent_field_names]
    
    # clean up the field name list of the years attached to the end
    field_names <- sub("_2001-2021", "", field_names)
    field_names <- sub("present_", "", field_names)
    field_names <- sub("TSS_", "", field_names)
    
  } else if (status == 'future'){
      
    # same procedure as before, except we identify time-frames that is not
    # related to future dataset.
    
    # CLIMATE DATA:
    
    discard_raster <- grepl("_2001-2021.tif$", raster_stack_list)
    discard_field_names <- grepl("_2001-2021$", field_names)
      
    # then remove it using the ! operator
      
    raster_stack_list <- raster_stack_list[!discard_raster]
    field_names <- field_names[!discard_field_names]
      
    
    # MAXENT OUTPUTS:
    # anything that starts with future will be discarded.
    discard_maxent_present_rast <- grepl("present", raster_stack_list)
    discard_maxent_present_names <- grepl("present", field_names)
    
    # filter it out.
    raster_stack_list <- raster_stack_list[!discard_maxent_present_rast]
    field_names <- field_names[!discard_maxent_present_names]
    
    # clean up field names
    field_names <- sub("_2080-2100", "", field_names)
    field_names <- sub("future_", "", field_names)
    field_names <- sub("TSS_", "", field_names)
    
    } # end of if/else block to check for historical/future data.
  
  # create a raster stack:
  raster_stack <- raster::stack(raster_stack_list)

  
  # now we want to do it a bit differently for the modis data compared to the 
  # climate and topography data.
  # therefore, we will seperate the code by having an if/ else block.
  
  if (grepl("Modis", basename(data_path))){
    
    # we want to basically aggregate the modis rasters into 1 raster.
    # this will speed up the processing significantly
    # (as opposed than iterating through each raster and mapping the values onto
    # the polygons). 
    
    # what does the 'aggregation' ential?
    # its just finding areas that have burnt at least once over our time period.
    # because its a binary dataset (0 = burnt, 1 = unburnt), 
    # the simplest way to do this is just to find the max value.
    
    print(raster_stack)
    
    aggregated_wf <- calc(raster_stack, fun = max)
    
    
    # now lets extract the values onto the polygons:
      
    # polygonise it (we will convert it to points).
    aggregated_wf_poly <- rasterToPoints(aggregated_wf)
    
    # convert it to a dataframe (because you can't directly convert this 
    # to an sf object).
    aggregated_wf_poly <- data.frame(aggregated_wf_poly)
    
    # changing the attribute names
    names(aggregated_wf_poly) <- c("Lon", "Lat", "modis_wf")
    
    # extract the crs from the polygon reference file.
    ref_crs <- st_crs(AOI)
      
    aggregated_wf_poly <- st_as_sf(aggregated_wf_poly, 
                                   coords = c("Lon", "Lat"), 
                                   crs = ref_crs)
    
    # Perform the spatial join
      
    AOI <- st_join(AOI, aggregated_wf_poly, join = st_intersects)
  
    
    } # end of if block for the modis data.
    
  else {
    
    # for everything else, we will just use the raw raster data and input it 
    # into the fields of the attribute table in our AOI
    # loop through the rasters and perform a similar operation as the 
    # modis data, except we don't need any aggregation
    
    raster_stack_index <- nlayers(raster_stack)
    
    for (i in 1:raster_stack_index) {
      
      # get the current layer in raster stack by the index of the for loop:
      current_layer <- raster_stack[[i]]
      
      # convert to polygon then convert to dataframe.
    
      data_poly <- rasterToPoints(current_layer)
      data_poly <- data.frame(data_poly)
      
      # changing the attribute names - the field name will be the first value
      # in the list
      
      names(data_poly) <- c("Lon", "Lat", field_names[i])
      
      # extract the crs from the polygon reference file.
      
      ref_crs <- st_crs(AOI)
      
      data_poly <- st_as_sf(data_poly,
                            coords = c("Lon", "Lat"),
                            crs = ref_crs)
      
      # perform the spatial join
      
      AOI <- st_join(AOI, data_poly, join = st_intersects)
      
      }
     
    
    } # end of else block for the other raster data.
  
  
  return(AOI) # return the AOI polygon dataset with updated fields.

  
  } # end of data_prep function.


#### DATA PREPARATION FOR SPATIAL MODEL ####

# essentially, we just want a grid of polygons where we half each column 
# represents the features and the wild fire column represents the targets.

# output directory for the input data for the spatial models
output_dir <- paste0(dirname(path), "/Data/Final/ML_input")

if (!dir.exists(output_dir)){
  
  dir.create(output_dir)
  
}

# path to polygon data:
AOI_path <- paste0(dirname(path), "/Data/Intermediate/References/shapefiles/Portugal_cells.shp")

# path to raster data

clim_path <- paste0(dirname(path), "/Data/Final/climate_data")
topography_path <-  paste0(dirname(path), "/Data/Final/Topography")
modis_path <- paste0(dirname(path), "/Data/Final/Modis")
rivers_path <- paste0(dirname(path), "/Data/Final/rivers")

# we will train 1 model on maxent  and the other the cci_lc dataset.
historical_maxent_path <- paste0(dirname(path), "/Data/Final/Vegetation/maxent_outputs/SSP245")
cci_lc_path <- paste0(dirname(path), "/Data/Final/vegetation/avg_cci_lc")

# this is for maxent (historical)
AOI <- st_read (AOI_path, layer = "Portugal_cells")
AOI <- data_fusion(clim_path, AOI, "historical", ssp_scenario = 245)
AOI <- data_fusion(topography_path, AOI, "historical", ssp_scenario = 0)
AOI <- data_fusion(rivers_path, AOI, "historical", ssp_scenario = 0)
AOI <- data_fusion(historical_maxent_path, AOI, "historical", ssp_scenario = 0)

AOI<- data_fusion(modis_path, AOI, "historical", ssp_scenario = 0)

st_write(AOI, paste0(output_dir, "/present_maxent.shp"))

# this is for the cci_lc dataset (historical)
AOI2 <- st_read (AOI_path, layer = "Portugal_cells")
AOI2 <- data_fusion(clim_path, AOI2, "historical", ssp_scenario = 245)
AOI2 <- data_fusion(topography_path, AOI2, "historical", ssp_scenario = 0)
AOI2 <- data_fusion(rivers_path, AOI2, "historical", ssp_scenario = 0)

AOI2 <- data_fusion(cci_lc_path, AOI2, "historical", ssp_scenario = 245)

AOI2<- data_fusion(modis_path, AOI2, "historical", ssp_scenario = 0)

st_write(AOI2, paste0(output_dir, "/present_cci_lc.shp"))


# future datasets (maxent model only)
# this is for maxent (ssp245)


future_maxent_path_245 <- paste0(dirname(path), "/Data/Final/Vegetation/maxent_outputs/SSP245")

AOI3 <- st_read (AOI_path, layer = "Portugal_cells")
AOI3 <- data_fusion(clim_path, AOI3, "future", ssp_scenario = 245)
AOI3 <- data_fusion(topography_path, AOI3, "historical", ssp_scenario = 0)
AOI3 <- data_fusion(rivers_path, AOI3, "historical", ssp_scenario = 0)
AOI3 <- data_fusion(future_maxent_path_245, AOI3, status = "future", ssp_scenario = 0)

st_write(AOI3, paste0(output_dir, "/maxent_future_245.shp"))

# we will train 1 model on maxent  and the other the cci_lc dataset.
future_maxent_path_585 <- paste0(dirname(path), "/Data/Final/Vegetation/maxent_outputs/SSP585")
AOI4 <- st_read (AOI_path, layer = "Portugal_cells")
AOI4 <- data_fusion(clim_path, AOI4, "future", ssp_scenario = 585)
AOI4 <- data_fusion(topography_path, AOI4, "historical", ssp_scenario = 0)
AOI4 <- data_fusion(rivers_path, AOI4, "historical", ssp_scenario = 0)
AOI4 <- data_fusion(future_maxent_path_585, AOI4, status = "future", ssp_scenario = 0)

st_write(AOI4, paste0(output_dir, "/maxent_future_585.shp"))


