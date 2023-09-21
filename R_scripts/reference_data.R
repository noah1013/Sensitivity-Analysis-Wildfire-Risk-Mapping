# Reference rasters and polygons for analysis:

library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting
library(rstudioapi) # automatically get the directory
library(stringr)
library(terra)
library(sf)
library(tmap)

# clear the R environment
rm(list = ls())
gc()


# set the directory:
path <- dirname(getActiveDocumentContext()$path)
# If the data is not being loaded, it can be accessed via the 'Data' Folder.
setwd(path)

# we will create an empty raster to use as a reference for 
# resampling, aligning and creating the cell polygons for the analysis.

# lets get our CRS from our AOI shapefile:
portugal_path <- paste0(dirname(path), "/Data/Initial/boundaries/portugal_20790/portugal_20790.shp")

portugal <- st_read(portugal_path, layer = "portugal_20790")

#### GENERATING REFERENCE RASTERS AND POLYGOS ####


rast_grid <- raster(portugal, resolution = 1000, vals = 1)
grid_centres <- as(rast_grid, "SpatialPoints") # set the raster as grid center 

# clip it to follow the shape of portugal
portugal_empty_rast <- mask(rast_grid, portugal) 
plot (portugal_empty_rast) # confirmation

output_ref = paste0(dirname(path), "/Data/Intermediate/References")
dir.create(output_ref)

output_ref_raster = paste0(output_ref, "/Rasters")
dir.create(output_ref_raster)

writeRaster(portugal_empty_rast,
            filename = paste0(output_ref_raster, "/Portugal_ref_raster.tif"))

# now lets polygonise it for the DL 'instances'.
cell_poly <- rasterToPolygons(portugal_empty_rast, 
                              fun = function(x) {x > 0}, 
                              na.rm = TRUE, 
                              dissolve = FALSE) # because we want to preserve the cells.
tm_shape(cell_poly)+
  tm_polygons() # quick confirmation

output_ref_poly = paste0(output_ref, "/shapefiles")
dir.create(output_ref_poly)

# write it to desired location:
writeOGR(cell_poly, 
         output_ref_poly , 
         "Portugal_cells",
         driver = "ESRI Shapefile")  # replace with your path











