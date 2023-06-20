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


# function to rename the files.
def Modis_nc(year, current_directory):

    # setting the directory and the selected year.
    name_change = current_directory + "\\Data\\Initial\\MODIS\\Reprojected\\" + str(year)


    for file_name in os.listdir(name_change):

        # first check if it is a ba_qa file.

        if 'ba_qa' in file_name:
            os.remove(name_change+ "\\"+ file_name)

        # otherwise go on to renaming the file.
        else:

            # adding the YEAR to the file name.
            if 'A' + str(year) in file_name:
                new_file_name = str(year) + '_'

            else:
                pass

            intermediate = ''

            # adding the MONTH to the file name.

            if '001.reproj' in file_name:

                intermediate = new_file_name + 'Jan'

            # to avoid conflicts with the value '032'
            elif '032.reproj' in file_name:
                intermediate = new_file_name + 'Feb'

            # to avoid conflicts with the value '060'
            elif '060.reproj' in file_name or '061.reproj' in file_name:
                intermediate = new_file_name + 'Mar'

            # to avoid conflicts with the value '091'
            elif '091.reproj' in file_name or '092.reproj' in file_name:
                intermediate = new_file_name + 'Apr'

            elif '121.reproj' in file_name or '122.reproj' in file_name:
                intermediate = new_file_name + 'May'

            elif '152.reproj' in file_name or '153.reproj' in file_name:
                intermediate = new_file_name + 'Jun'

            elif '182.reproj' in file_name or '183.reproj' in file_name:
                intermediate = new_file_name + 'Jul'

            elif '213.reproj' in file_name or '214.reproj' in file_name:
                intermediate = new_file_name + 'Aug'

            elif '244.reproj' in file_name or '245.reproj' in file_name:
                intermediate = new_file_name + 'Sep'

            elif '274.reproj' in file_name or '275.reproj' in file_name:
                intermediate = new_file_name + 'Oct'

            elif '305.reproj' in file_name or '306.reproj' in file_name:
                intermediate = new_file_name + 'Nov'

            elif '335.reproj' in file_name or '336.reproj' in file_name:
                intermediate = new_file_name + 'Dec'

            # to deal with shapefiles or tifs:
            final = ''

            if file_name.endswith('.tiff'):

                final = intermediate + '.tiff'

            else:

                print("Invalid file format. Program will now close.")

            src = os.path.join(name_change, file_name)
            dst = os.path.join(name_change, final)
            os.rename(src, dst)

    print("\nYour MODIS shapefiles for the year " + str(year) + " have been renamed successfully!")

# function to delete non-fire season

def deleter(year, selected_month_codes, current_directory):

    # Setting the directory and the selected year.
    fire_season = current_directory + "\\Data\\Initial\\MODIS\\Reprojected\\" + str(year)

    for file_name in os.listdir(fire_season):
        found = False

        for month in selected_month_codes:
            if month in file_name:
                found = True
                break

        if not found:
            # Remove the file
            file_path = os.path.join(fire_season, file_name)
            os.remove(file_path)

    print("Fire season months for year "+ str(year)+" successfully selected!\n")

# function to clip the raster images based on a polygon for the selected region of interest

def clipper(year, current_directory):

    # setting the directory and the selected year.
    name_change = current_directory + "\\Data\\Initial\\MODIS\\Reprojected\\" + str(year)
    print("\nYear = " + str(year))

    # make a new directory to hold the clipped data:
    clip_dir = current_directory + "\\Data\\Intermediate\\Modis_clipped\\" + str(year) + "\\"

    # check if the clip_directory already exists.
    if os.path.exists(clip_dir):
        pass

    # if it does not already exist, create it.
    else:
        os.makedirs(clip_dir)
        print("\nNew directory generated:\n"
              "\n"+ clip_dir)

    # loop over each file in the year directory
    for renamed_file in os.listdir(name_change):
        # Let's get the names
        year_month = os.path.basename(renamed_file)
        # Remove the last four characters (because the suffix is '.tiff')
        year_month = year_month[:-5]

        # First lets navigate the directory to locate the shape file.
        # In this case we use portugal.

        shp_file_path = current_directory + "\\Data\\initial\\boundaries\\portugal_20790\\portugal_20790.shp"

        # set the output as the clip dir.
        output_clipped_path = clip_dir + year_month+".tiff"

        with fiona.open(shp_file_path, "r") as clip_shp:
            shapes = [feature["geometry"] for feature in clip_shp]

        with rasterio.open(name_change + "\\" + renamed_file) as rast:

            out_image, out_transform = rasterio.mask.mask(rast, shapes, crop=True)
            out_meta = rast.meta

        out_meta.update({"driver": "GTiff",
                         "height": out_image.shape[1],
                         "width": out_image.shape[2],
                         "transform": out_transform})

        with rasterio.open(output_clipped_path, "w", **out_meta) as dest:
            dest.write(out_image)
