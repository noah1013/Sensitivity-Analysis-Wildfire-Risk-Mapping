# standard imports

import os
import rasterio
from Fire_season import generate_UI
import fiona
from rasterio.mask import mask
from rasterio import plot as rplot
from shapely.geometry import shape
from shapely.geometry import Point, Polygon, LineString, MultiPolygon, mapping
import matplotlib.pyplot as plt
import geopandas as gpd
import json
import math
import numpy as np
import rasterio.mask


# function to convert the fire raster pixels into polygons.

def Poly_fire(year, current_directory):

    # setting the directory and the selected year.
    name_change = current_directory + "\\Data\\Intermediate\\Modis_clipped\\" + str(year)
    print("\nYear = "+ str(year))

    file_counter = 1

    for renamed_file in os.listdir(name_change):

        # since each raster file has now been renamed to Year_month, we can extract the
        # file name to use as an attribute in the polygons.

        year_month = os.path.basename(renamed_file)
        # Remove the last four characters (because the suffix is '.tiff')
        year_month = year_month[:-5]

        # make a new directory to hold the data:
        new_dir = current_directory + "\\Data\\Intermediate\\modis_poly\\" + str(year) + "\\"

        if os.path.exists(new_dir):
            # do nothing
            pass

        else:
            os.makedirs(new_dir)

        with rasterio.open(name_change + "\\" + renamed_file) as rast:
            # reading band 1
            arr = rast.read(1)
            transform = rast.transform

            # converting to numpy array
            rast_arr = np.array(arr)

            # 0 = unburnt land
            # -1 = unmapped due to insufficient data.
            # -2 = water.
            # anything above 0 (1-366) is the ordinal day of burn.

            # Therefore, we need to create a binary mask for pixels with values > 0

            # Identify pixels with values > 1 and create polygons

            # list to hold the polygons, nominal burn dates and year/month for each Polygon.
            polygons = []
            burn_dates = []
            yy_mms = []

            for index, burn_date in np.ndenumerate(rast_arr):

                if burn_date > 1:
                    i, j = index
                    # Create polygon from the cell indices
                    # Calculate the center coordinates of the raster cell
                    x_center, y_center = rasterio.transform.xy(transform, i, j)

                    # Create polygon centered on the cell
                    polygon = Polygon([(x_center - 0.5 * transform.a, y_center - 0.5 * transform.e),
                                       (x_center + 0.5 * transform.a, y_center - 0.5 * transform.e),
                                       (x_center + 0.5 * transform.a, y_center + 0.5 * transform.e),
                                       (x_center - 0.5 * transform.a, y_center + 0.5 * transform.e)])
                    polygons.append(polygon)

                    burn_dates.append(burn_date)  # Assign the burn_date into the polygon.
                    yy_mms.append(year_month)  # Assign the year/month to each polygon.

            # Create a GeoDataFrame from polygons and attribute values
            features = {'geometry': polygons, 'burn_date': burn_dates, 'yymm': yy_mms}

            gdf = gpd.GeoDataFrame(features, crs=rast.crs)

            # Export the GeoDataFrame to a file
            output_path = new_dir + year_month +".shp"

            gdf.to_file(output_path)

            print(str(file_counter)+" out of " + str(len(os.listdir(name_change)))+" raster files have been polygonised")

            file_counter += 1

    print("\nPolygonisation of MODIS files for the year " + str(year) + " has successfully been completed!"
          "\nYou can find your polygon files in "+ new_dir)
