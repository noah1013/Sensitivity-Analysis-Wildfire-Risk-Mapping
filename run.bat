@echo off

echo Starting Preprocessing...

echo Running reference_data.R
Rscript ./R_scripts/reference_data.R
echo reference_data.R compplete.

echo Running HDF_extractor.py
python ./python_scripts/HDF_extractor.py
echo HDF_extractor.py complete.

echo Running FireSeasonSelector.py (was main.py)
python ./python_scripts/FireSeasonSelector.py
echo FireSeasonSelector.py complete.

echo Running Cmip6_NC_opener.R
Rscript ./R_scripts/Cmip6_NC_opener.R
echo Cmip6_NC_opener.R complete.

echo Running Bioclim.R
Rscript ./R_scripts/Bioclim.R
echo Bioclim.R complete.