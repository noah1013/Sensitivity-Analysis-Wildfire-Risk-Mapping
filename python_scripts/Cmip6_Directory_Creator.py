import os

def generate_paths(path : str, scenario : str | int) -> None:
    '''
    Generate pathing structure for the CMIP6 data. Since git does not allow empty directories, they must be created when running the project code.
    
    Note: If the directories already exist (i.e. data is already downloaded and within the folders) The data and directories will not be deleted.
    ''' 

    if isinstance(scenario, int):
        scenario = str(scenario)
    
    ssp_path = os.path.join(path, f"Data/Initial/climate_data/SSP{scenario}")

    for path in {"hurs", "pr", "tas", "tasmax", "tasmin", "wind"}: 
        os.makedirs(os.path.join(ssp_path, path), exist_ok = True)

def main():
    path = os.getcwd()
    generate_paths(path, 245)
    

if __name__ == "__main__":
    main()