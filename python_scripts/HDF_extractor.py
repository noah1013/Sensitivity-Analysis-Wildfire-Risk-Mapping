# python script to extract the data from the HDF file.
# Created using Python 3.10 and uses osgeo
# Updated using Python 3.12

import os
import shutil

from osgeo import gdal, ogr
from Utilities import year_lister

current_directory = os.getcwd()

print("\nProject directory: "
      "\n"
      + current_directory)


HDF_path = current_directory + "\\Data\\Initial\\MODIS\\HDF"

# first lets create a new directory to contain the extracted sub-data in TIFF format:
new_dir = current_directory + "\\Data\\Initial\\MODIS\\TIFF"

if os.path.exists(new_dir):
    try:
        shutil.rmtree(new_dir)
    except Exception as e:
        print(f"Error removing directory: {e}")

os.makedirs(new_dir)

# iterate through the folders inside the HDF file.
# for portugal the study region is divided into two windows.

# create an empty list to store the paths of the new TIFF files.
window_path_list = []

for window in os.listdir(HDF_path):
    window_path = HDF_path + "\\" + window

    # save the name
    window_code = os.path.basename(window)

    # create a sub-directory in the tiff folder corresponding to the window.
    tiff_window_dir = new_dir + "\\" + window_code
    os.makedirs(tiff_window_dir)

    # store this path in the list
    window_path_list.append(tiff_window_dir)


    print("\nNow extracting Sub-Data for MODIS product with code: " + window_code +
          "\n")

    # now extract the sub-data
    # code adapted from chryss, 2013
    # found at: https://gis.stackexchange.com/questions/72178/how-to-extract-subdataset-from-hdf-raster
    for hdf_file in os.listdir(window_path):

        hdf_path = window_path + "\\" + hdf_file
        dataset = gdal.Open(hdf_path, gdal.GA_ReadOnly)

        # save the name of the file (we want to remove that .hdf at the end)
        hdf_file_name = os.path.basename(hdf_file)
        hdf_file_name = hdf_file_name[:-4]

        subdatasets = dataset.GetSubDatasets()

        subdataset_index = 0
        selected_subdataset = gdal.Open(subdatasets[subdataset_index][0], gdal.GA_ReadOnly)

        output_file = tiff_window_dir + "\\" + hdf_file_name + ".tif"

        gdal.Translate(output_file, selected_subdataset)

        selected_subdataset = None
        dataset = None

    print("\nSub-Data for MODIS product " + window_code + " successfully extracted.\n")
    


if len(os.listdir(HDF_path)) > 1:
    print("\nYour study region falls on " + str(len(os.listdir(HDF_path))) + " MODIS windows.\n")

    print("These products will now be stitched together.")

    # Create a new directory to hold the merged data.

    merged_directory = current_directory + "\\Data\\Initial\\MODIS\\merged"
    if os.path.exists(merged_directory):
        try:
            shutil.rmtree(merged_directory)
        except Exception as e:
            print(f"Error removing directory: {e}")

    os.makedirs(merged_directory)

    for raster1, raster2 in zip(os.listdir(window_path_list[0]), os.listdir(window_path_list[1])):

        raster1_name = os.path.basename(raster1)
        raster2_name = os.path.basename(raster2)

        # extracting the year and nominal date substring.
        # to check if they fall on the same year and nominal date.
        # the format of a file name should be something like: "MCD64A1.A2001001.merged"
        raster1_nom = raster1_name[9:16]
        raster2_nom = raster2_name[9:16]

        # double-checking that the files to be merged have both the same year and nominal date.
        if raster1_nom == raster2_nom:

            # this is so that the files are split up in folders based on year.
            folder_name = raster1_name[9:13]

            # create a new directory specific to the year:
            # make a new directory to hold the data:
            merge_year_dir = current_directory + "\\Data\\Initial\\MODIS\\merged\\" + folder_name

            # this should iterate 12 times. (12 months in a year)
            # we only really want one folder for each year.
            os.makedirs(merge_year_dir, exist_ok = True)

            # get the paths for both the rasters and open it using gdal.
            MODIS_1 = gdal.Open(window_path_list[0] + "\\" + raster1)
            MODIS_2 = gdal.Open(window_path_list[1] + "\\" + raster2)

            # code adapted from Jose, 2022
            # found at: https://gis.stackexchange.com/questions/361213/merging-rasters-with-gdal-merge-py
            mosaic = [MODIS_1, MODIS_2]

            # split the filename by the full stops
            parts = raster1.split('.')
            # keep only the first two parts
            merged = '.'.join(parts[:2])

            output_path = merge_year_dir + "\\" + merged + ".merged.tif"

            # options = {"compressionOptions": "COMPRESS=LZW",
            #            "TILED" : "YES"}
            
            # merge the rasters using gdal.Warp()
            options = gdal.WarpOptions(creationOptions = ["COMPRESS=LZW", "TILED=YES"])
            
            g = gdal.Warp(output_path,
                          mosaic,
                          format = "GTiff",
                          options = options
                          )
            
            # close the file and flush to disk
            g = None

        # if the two raster images are not for the same year and nominal date,
        # inform the user so that they can check where it went wrong and to download the necessary files.
        else:

            print("\nThe nominal dates for the MODIS products:\n"
                  "\n"
                  + raster1_name +
                  "\n"
                  + raster2_name +
                  "\n"
                  "\ndo not line up. Please ensure that they are for the correct year and nominal date.\n")

            print ("\nAlso ensure that the following directories are removed before restaring the program:\n"
                   "\n"
                   + new_dir +
                   "\n"
                   + merged_directory)


            break

    print("\nMerge complete")
    


    # reprojecting
    print("\nReprojecting raster to the CRS of the Area of Interest.\n")

    # let's get the first and last year in our file:

    first_year, last_year = year_lister(merged_directory)

    reproj_dir = current_directory + "\\Data\\Initial\\MODIS\\Reprojected"
    if os.path.exists(reproj_dir):
        try:
            shutil.rmtree(reproj_dir)
        except Exception as e:
            print(f"Error removing directory: {e}")

    
    for i in range(first_year, (last_year + 1)):
        to_reproj_dir = merged_directory + "\\" + str(i)
        for to_reproj in os.listdir(to_reproj_dir):

            # get the name of the file:
            merged_name = os.path.basename(to_reproj)
            reproj_name = merged_name[:-10]

            # create a new directory specific to the year:
            # make a new directory to hold the data:
            reproj_dir = current_directory + "\\Data\\Initial\\MODIS\\Reprojected\\" + str(i)
                
            os.makedirs(reproj_dir, exist_ok = True)          

            # open the shapefile for the AOI
            AOI_path = current_directory + "\\Data\\initial\\boundaries\\portugal_20790\\portugal_20790.shp"
            AOI = ogr.Open(AOI_path)

            # get the first layer of the shapefile
            layer = AOI.GetLayer()

            # get the CRS information
            target_crs = layer.GetSpatialRef()

            # Open the MODIS merged raster image
            merged_rast = gdal.Open(to_reproj_dir + "\\" + to_reproj)
            # reproject the raster to the target CRS
            reprojected_dataset = gdal.Warp(reproj_dir + "\\" + reproj_name + "reproj.tiff",
                                            merged_rast,
                                            dstSRS=target_crs)

            # close the datasets to flush disk
            reprojected_dataset = None
            merged_rast = None
            shapefile = None

    print ("Reprojection complete.")



elif len(os.listdir(HDF_path)) > 2:
    print("\nYour study region falls on " + str(len(os.listdir(HDF_path))) + "MODIS windows.\n")

    print("\n This code is not designed to deal with more than 2 rasters.\n"
          "Please make alterations on line 61.")
else:
    pass

