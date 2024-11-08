import xarray as xr
import os
import sys

def merge_data(path : str, year_start : int, year_end : int, scenario : str, var : str) -> None:
    print(f"Merging data for:\nYears: {year_start} to {year_end}\nVariable: {var}\nScenario: {scenario}")
    
    files = os.listdir(path) 
    years = {file[-7:-3] for file in files}

    input_files = list()
    for year in range(year_start, year_end+1):
        if str(year) not in years:
            sys.exit(1)
            
        for file in files:
            if str(year) in file:
                input_files.append(os.path.join(path, file)) 
            
    # Define input and output filenames
    output_filename = os.path.join(os.getcwd(), f"Data/Initial/climate_data/SSP{scenario}", var, f"{files[0][:-7]}{year_start}_{year_end}.nc")
    
    # Open the input files
    ds_list = []
    for file in input_files:
        ds = xr.open_dataset(file)
        ds_list.append(ds)

    # Concatenate the datasets along the time dimension
    merged_ds = xr.concat(ds_list, dim='time')

    # Save the concatenated dataset
    merged_ds.to_netcdf(output_filename)

    print(f"Merged dataset saved as {output_filename}\n")


def main():
    for var in {"hurs", "pr", "tas", "tasmax", "tasmin", "wind"}: 
        path = os.path.join(os.getcwd(), "Data/Initial/nc_files/", var)
        
        merge_data(path, 1994, 2014, "245", var)
        # merge_data(path, 2080, 2100, "245", var)

if __name__ == "__main__":
    main()