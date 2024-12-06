# CEGE Research Project.

Repository for code and data involved in the UCL CEGE MSc Research Project:

"A Machine Learning Approach to Long-term Wildfire Susceptibility Mapping in Portugal."

Supervised by Dr Augustin Guibaud.
Originally by Trisung Dorji.

## Contents.

1. Deployment.
2. Order of the scripts.
3. Required libraries for python scripts.
4. Required libraries for R scripts.
5. Relevant hardward requirements.

## 1. Deployment.

Two programming languages, Python and R, were used to clean and process the data as there were only some specific packages available to R that python did not have. 

* Python: 3.12.6
* R: 4.4.1
 
Important Note: 
The programs here are very specific to the area of interest and the temporal period of study.
If the programs were to be adapted to study another region or time-frame,  the code will need to be tweaked. 

Further, there may be bugs and  errors that arise during the data processing steps due when deployed on another machine. However, the machine learning section should work fine assuming that the correct libraries are installed and the same input data is used. 

## 2. The order of the scripts.

The stages below show the individual R-scripts and python scripts that were used to perform various tasks.

They must be run in the order listed below.

Note that the first 3 stages are only data pre-processing stages. The machine learning aspect of the project is in Stage 4. If you only want to test the machine learning code only, all the data is already processed and ready to be ingested by the models. A copy of this data is provided as many of the processed data will be overwritten during the first 3 stages. 

Since the climate data is too large, it won't be included in this repository. However, the final versions of all the input variables have been included so the the machine learning algorithms should run without issues.

The machine learning code can be found in "python_scripts/ML"
R code can be found in "R_scripts"

### Stage 1: Generating Cmip6 data directory structure, Combining Cmip6 daily data to yearly data 
1. Cmip6_Directory_Creator.py: Generate the directory structure for the Cmip6 climate data. 
2. Cmip6_Data_Merger.py: Combines daily Cmip6 yearly data into yearly .nc data files. 

### Stage 2: Generating reference polygons, Opening the PFT dataset, conversion of MODIS dataset and selecting wildfire seasons.

1. reference_data.R: create the spatial grid polygon (1km x 1km resolution) reference for our study region.
2. HDF_extractor.py: Pre-processing of the MODIS dataset.
3. FireSeasonSelector.py: selecting the fire season months.

### Stage 3: Preparing climate data, resampling all of our input features and aligning them.

1. Cmip6_NC_opener.R: Opens the CMIP6 data which is also in netCDF format.
2. Bioclim.R: Derives bioclimatic variables from the CMIP6 dataset.

### Stage 4: Maxent Species Distribution Modelling.

1. MaxEnt.R: Maxent algorithm for species distribution modelling.


## 3. Required libraries for Python scripts.

### File Handling 
| Package | Version | 
| -------- | -------------------------- |
|os| 3.9.12 |
|xarray| 2024.10.0 |

### Geospatial data and data manipulation:

| Package | Version | 
| -------- | -------------------------- |
|fiona| 1.10.1 |
|gc| 3.9.12 |
|geopandas| 1.0.1 |
|json| 3.9.12 |
|math| 3.9.12 |
|numpy| 1.26.4 |
|osgeo (GDAL) | 3.9.2 |
|pandas| 2.2.3 |
|random | 3.9.12 |
|rasterio| 1.4.2 |
|shapely| 2.0.6 |


NOTE: If there are issues using the provided requirements.txt to install the osgeo package, a python wheel for the osgeo package is included from https://github.com/cgohlke/geospatial-wheels/releases/tag/v2024.9.22.  

### Visualisastion

| Package | Version | 
| -------- | -------------------------- |
|matplotlib | 3.9.2 |
|seaborn | 0.13.2 |
|tkinter | 8.6.12 |

### Graph generation and Graph Convolution Network and feature attribution.

| Package | Version | 
| -------- | -------------------------- |
|captum | 0.7.0 |
|networkx | 3.3 |
|pysal | 24.7 |
|scikit-learn | 1.5.2 |
|torch | 2.4.1 |
|torch_geometric | 2.6.1 |


## Required libraries for R-scripts.

### Geospatial data and data manipulation.

| Package | Version | 
| -------- | -------------------------- |
|dplyr| 1.1.4 |
|ncdf4| 1.23 |
|raster| 3.6-30 |
|sf| 1.0-18 |
|stringr| 1.5.1 |
|terra| 1.7-83 |


### Visualisation. 
| Package | Version | 
| -------- | -------------------------- |
|ggplot2| 3.5.1 |
|tmap| 3.3.4 |


### Biovariable generation and Species Distribution modelling.

| Package | Version | 
| -------- | -------------------------- |
|dismo| 1.3.14 |


## 4. Data Sources:
1. Cmip6 Climate Data: https://nex-gddp-cmip6.s3.us-west-2.amazonaws.com/index.html#NEX-GDDP-CMIP6/
2. 2015 Vegetation Data: https://www.gbif.org/dataset/0fe87daf-ed3c-4544-9d41-e187c408ee71


## Relevant Hardware requirements.

Storage: 2 TB SSD (most of which was used up by the raw climate data which is not on this repository).

RAM: 64 GB DDR - 3200 SODIMM.

Processor: AMD Ryzen 9 5900HX with Radeon Graphics, 3301 Mhz, 8 Core(s), 16 Logical Processor(s).

GPU: Nvidia GeForce RTX 3060 (Laptop).














