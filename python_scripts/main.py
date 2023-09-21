# Program for data Handling
# written in Python 3.8

# importing potential libraries

import os
import rasterio
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

# Importing my own functions

from Fire_season import generate_UI
from Modis_handler import Modis_nc, deleter, clipper, fire_season_identifier, identify_fire_months
from Utilities import year_lister

# Start of the program

print("Wild fire susceptibility mapping data cleaner version 1.0")

current_directory = os.path.dirname(os.getcwd())

print("\nProject directory: "
      "\n"
      + current_directory)


# first lets get the first and last years in our MODIS file.
# Get the folder names in the MODIS directory
MODIS_directory = current_directory + "\\Data\\Initial\\MODIS\\Reprojected"

first_year, last_year = year_lister(MODIS_directory)


# Step 1: Rename the MODIS files to make it easier to understand.
print("\nRenaming MODIS files\n"
      "\n")

for i in range(first_year, (last_year + 1)):
    Modis_nc(i, current_directory)
    

# Step 2: Clip the raster images by your study area.
print("\nClipping your MODIS files\n"
      "\n")

for i in range(first_year, (last_year + 1)):
    clipper(i, current_directory)


# let's just quickly get the 75th percentile of the fire season to determine the fire months:
percentile_75 = identify_fire_months(first_year, last_year, current_directory)
print("\nComputing 75th percentile of fire activity to determine significant fire months.")

# instantiate an empty dictionary which contains the selected month codes for each year in our study area:
yearly_fire_season = {}

for i in range(first_year, (last_year + 1)):


    fig = fire_season_identifier(i, current_directory, percentile_75)

    print("\nPlease look for the window to select your fire season months.")


    # open the button window and retrieve the selected month codes for the fire season months.
    window, selected_month_codes = generate_UI(fig=fig)
    # Start the main event loop
    window.mainloop()

    # force close the plot
    plt.close(fig)

    # now save the year (which is the key) and the fire season months (which is the value) into the dictionary:
    yearly_fire_season[i] = selected_month_codes

    # Step 3: Select raster images of the months corresponding to the fire season in your study area.
    deleter(i, selected_month_codes, current_directory)

print(yearly_fire_season)

# we will save the fire season months for each year because we will need it later for when we select our
# climate variables (they have to correspond to the same months).

fire_season_txt = current_directory + "\\Data\\stats\\yearly_fire_seasons\\"

os.makedirs(fire_season_txt)

with open(fire_season_txt + "fire_seasons.txt", 'w') as file:
    for key, value in yearly_fire_season.items():
        file.write(f"{key} : {', '.join(map(str, value))}\n")

