# CEGE Research Project.

Repository for code and data involved in the UCL CEGE MSc Research Project:

"A Machine Learning Approach to Long-term Wildfire Susceptibility Mapping in Portugal."

Supervised by Dr Augustin Guibaud.
By Trisung Dorji.

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

Note that the first 2 stages are only data pre-processing stages. The machine learning aspect of the project is in Stage 3 & 4. If you only want to test the machine learning code only, all the data is already processed and ready to be ingested by the models. 

Since the climate data is too large, it won't be included in this repository. However, the final versions of all the input variables have been included so the the machine learning algorithms should run without issues.

The machine learning code can be found in "python_scripts/ML"
R code can be found in "R_scripts"

### Stage 1: Generating reference polygons, Opening the PFT dataset, conversion of MODIS dataset and selecting wildfire seasons.

1. reference_data.R: create the spatial grid polygon (1km x 1km resolution) reference for our study region.
3. CCI_LC_NC_opener.R: opens the PFT dataset (derived from the CCI-LC dataset) which is in netCDF format.
2. HDF_extractor.py: Pre-processing of the MODIS dataset.
3. main.py: selecting the fire season months.

### Stage 2: Preparing climate data, resampling all of our input features and aligning them.

1. Cmip6_NC_opener.R: Opens the CMIP6 data which is also in netCDF format.
2. Bioclim.R: Derives bioclimatic variables from the CMIP6 dataset.
3. miracle_aligner.py: resamples all of the data to 1 by 1 km resolution using the reference and then aligns these grids so that they can be used for analysis later. 

### Stage 3: Maxent Species Distribution Modelling.

1. MaxEnt.R: Maxent algorithm for species distribution modelling.

### Stage 4: Graph Convolution Network for wildfire risk mapping.

1. GCN-maxent-ROC.ipynb: GCN for the maxent-WSM.
2. GCN-cci-lc-ROC.ipynb: GCN for the PFT-WSM.


## 3. Required libraries for Python scripts.

### File Handling 
| Package | Version | 
| -------- | -------------------------- |
|os| 3.9.12 |

### Geospatial data and data manipulation:

| Package | Version | 
| -------- | -------------------------- |
|fiona| 1.9.4.post1 |
|gc| 3.9.12 |
|geopandas| 0.12.2 |
|json| 3.9.12 |
|math| 3.9.12 |
|numpy| 1.21.5 |
|osgeo (GDAL) | 3.7.0 |
|pandas| 2.0.2 |
|random | 3.9.12 |
|rasterio| 1.3.7 |
|shapely| 2.0.1 |

### Visualisastion

| Package | Version | 
| -------- | -------------------------- |
|matplotlib | 3.5.1 |
|seaborn | 0.11.2 |
|tkinter | 8.6.12 |

### Graph generation and Graph Convolution Network and feature attribution.

| Package | Version | 
| -------- | -------------------------- |
|captum | 0.6.0 |
|networkx | 2.7.1 |
|pysal | 23.1 |
|scikit-learn | 1.0.2 |
|torch | 2.0.0+cu117 |
|torch_geometric | 2.3.1 |


## Required libraries for R-scripts.

### Geospatial data and data manipulation.

| Package | Version | 
| -------- | -------------------------- |
|dplyr| 1.1.2 |
|ncdf4| 1.21 |
|raster| 3.6-23 |
|rgdal| 1.6-7 |
|rgeos| 0.6-4 |
|rstudioapi| 0.15.0 |
|sf| 1.0-14 |
|stringr| 1.5.0 |
|terra| 1.7-39 |


### Visualisation. 
| Package | Version | 
| -------- | -------------------------- |
|ggplot2| 3.4.2 |
|tmap| 3.3-3 |


### Biovariable generation and Species Distribution modelling.

| Package | Version | 
| -------- | -------------------------- |
|dismo| 1.3-14 |


## Relevant Hardware requirements.

Storage: 2 TB SSD (most of which was used up by the raw climate data which is not on this repository).

RAM: 64 GB DDR - 3200 SODIMM.

Processor: AMD Ryzen 9 5900HX with Radeon Graphics, 3301 Mhz, 8 Core(s), 16 Logical Processor(s).

GPU: Nvidia GeForce RTX 3060 (Laptop).














