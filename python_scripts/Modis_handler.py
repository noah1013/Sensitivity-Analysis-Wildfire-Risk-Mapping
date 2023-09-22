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
    fire_season = current_directory + "\\Data\\Intermediate\\Modis_clipped\\" + str(year)

    for file_name in os.listdir(fire_season):

        # initialise a boolean flag to false
        found = False

        # check the codes against the file names:
        for month in selected_month_codes:

            if month in file_name:
                found = True
                break

        if not found:
            # remove the file
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
        # let's get the names
        year_month = os.path.basename(renamed_file)
        # remove the last four characters (because the suffix is '.tiff')
        year_month = year_month[:-5]

        # first lets navigate the directory to locate the shape file.
        # in this case we use portugal.

        shp_file_path = current_directory + "\\Data\\initial\\boundaries\\portugal_20790\\portugal_20790.shp"

        # set the output as the clip dir.
        output_clipped_path = clip_dir + year_month+".tiff"

        with fiona.open(shp_file_path, "r") as clip_shp:
            shapes = [feature["geometry"] for feature in clip_shp]

        with rasterio.open(name_change + "\\" + renamed_file) as rast:


            out_image, out_transform = rasterio.mask.mask(rast, shapes, crop=True)

            # convert raster to numpy array to apply a binary transformation
            array = out_image[0]


            # here we apply binary transformation:
            # anything below 0 is considered 'no fire'
            # anything above 0 is the nominal day of burn
            # therefore we just use anything greater 0 to indicate a fire.
            array = np.where(array > 0, 1, 0)

            out_image[0] = array  # using the binary transformed array

            out_meta = rast.meta

        out_meta.update({"driver": "GTiff",
                         "height": out_image.shape[1],
                         "width": out_image.shape[2],
                         "transform": out_transform})

        with rasterio.open(output_clipped_path, "w", **out_meta) as dest:
            dest.write(out_image)


# function to calculate the 75th percentile of fire seasons:

def identify_fire_months (first_year, last_year, current_directory):

    # code is a repeat of the one above, but we just save all the values in a long list and calculate the 75th
    # percentile:
    # instantiate an empty list to hold all that data
    burn_data = []

    for i in range(first_year, (last_year + 1)):

        clip_dir = current_directory + "\\Data\\Intermediate\\Modis_clipped\\" + str(i)

        for month in os.listdir(clip_dir):
            monthly_burn_raster_path = clip_dir + "\\" + month

            with rasterio.open(monthly_burn_raster_path) as rast:
                modis_monthly = rast.read(1)
                burn_pixel_count = np.int64(modis_monthly > 0).sum()
                total_pixels = modis_monthly.size
                percentage_burn = (burn_pixel_count / total_pixels) * 100

                # append the percentage to the list
                burn_data.append(percentage_burn)

    # calculate the 75th percentile across all the years:
    percentile_75 = np.percentile(burn_data, 75)

    return (percentile_75)


# function to loop through each year, count the number of pixel per month and plot it:

def fire_season_identifier(year, current_directory, percentile_75):

    # get the directory for the clipped data
    clip_dir = current_directory + "\\Data\\Intermediate\\Modis_clipped\\" + str(year)

    burnt_area_graph_dir = current_directory + "\\Data\\stats\\Fire_season_plots\\burnt_area\\"
    percentage_ba_dir = current_directory + "\\Data\\stats\\Fire_season_plots\\burnt_area_perc\\"

    # check if the burnt_area_directory already exists.
    if os.path.exists(burnt_area_graph_dir):
        pass

    # if it does not already exist, create it.
    else:
        os.makedirs(burnt_area_graph_dir)
        print("\nNew directory generated:\n"
              "\n" + burnt_area_graph_dir)

    # check if the percentage directory already exists.
    if os.path.exists(percentage_ba_dir):
        pass

        # if it does not already exist, create it.
    else:
        os.makedirs(percentage_ba_dir)
        print("\nNew directory generated:\n"
              "\n" + percentage_ba_dir)

    # initialise an empty month list:
    months = []
    burnt_area = []
    percentage_burnt_area = []

    # loop through each of the months in each year:
    for month in os.listdir(clip_dir):

        # extract the name of the month
        month_name = month[5:8]

        monthly_burn_raster_path = clip_dir + "\\" + month

        with rasterio.open(monthly_burn_raster_path) as rast:

            # read the raster data as a numpy array
            modis_monthly = rast.read(1)

            # count any pixel values that are above 0 (as this represents the nominal day of burn)
            # convert to int64 data type to prevent overflow
            burn_pixel_count = np.int64(modis_monthly > 0).sum()

            # now we know that the resolution is about 500 by 500 meters for the modis burnt area products
            # so, we will calculate the total burnt area in km2 (1000 metres by 1000 metres)
            total_burnt_area = (burn_pixel_count * (500*500)) / (1000 * 1000)

            # get the total number of pixels
            total_pixels = modis_monthly.size

            # now lets get the percentage of burnt pixels for the graph (so that it is comparable between years)
            percentage_burn = (burn_pixel_count / total_pixels) * 100

            # append the month, burnt area and percentage of burnt pixels to the list:
            months.append(month_name)
            burnt_area.append(total_burnt_area)
            percentage_burnt_area.append(percentage_burn)



    # now plot the bar graph for the burnt_area
    fig, ax = plt.subplots(figsize=(6, 3))
    ax.bar(months, burnt_area, color='yellow', edgecolor='black')

    # Add a title and labels
    ax.set_title(f'Burnt area by Month for the year {year}')
    ax.set_xlabel('Month')
    ax.set_ylabel('Burnt area (km2)')
    ax.grid(axis='y', linestyle='--', linewidth=0.5)

    # Layout adjustments (similar to plt.tight_layout())
    fig.tight_layout()

    # Save the plot to the directory
    output_path = os.path.join(burnt_area_graph_dir, f'Burnt_area_{year}.png')
    fig.savefig(output_path, dpi=500)

    # if anything is over the 75th percentile, it will be plotted in red
    colors = ['red' if x > percentile_75 else 'orange' for x in percentage_burnt_area]

    # now plot the bar graph for the percentage of burnt pixels
    fig2, ax2 = plt.subplots(figsize=(6, 3))
    ax2.bar(months, percentage_burnt_area, color=colors, edgecolor='black')

    # Add a title and labels
    ax2.set_title(f'Percentage of Portugal burnt by Month for the year {year}')
    ax2.text(0.05, 0.95, "75th percentile: " + str(float(format(percentile_75, '.2g'))), transform=ax2.transAxes,
             verticalalignment='top', horizontalalignment='left', fontsize=10, color='red')
    ax2.set_xlabel('Month')
    ax2.set_ylabel('Percentage of Portugal burnt')
    ax2.grid(axis='y', linestyle='--', linewidth=0.5)

    # Layout adjustments (similar to plt.tight_layout())
    fig2.tight_layout()

    # Save the plot to the directory
    output_path2 = os.path.join(percentage_ba_dir, f'Percentage_burn_{year}.png')
    fig2.savefig(output_path2, dpi=500)

    # return the percentage figure so that it can be opened up in Tkinter
    return fig2




