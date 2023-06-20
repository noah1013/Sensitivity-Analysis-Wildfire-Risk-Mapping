# Just some code that is useful and can be reused in many situations.

import os

def year_lister(directory):

    folders = []

    for folder in os.listdir(directory):
        folder_path = os.path.join(directory, folder)
        if os.path.isdir(folder_path):
            folders.append(folder)

    # Sort the list of folders numerically based on the year.
    sorted_folders = sorted(folders, key=lambda x: int(x))

    # Get the name of the first folder and convert it into an integer.
    first_year = int(sorted_folders[0])

    # Get the name of the last folder and convert it into an integer.
    last_year = int(sorted_folders[-1])

    print("\nFirst year:", str(first_year))
    print("Last year:", str(last_year), "\n")

    return first_year, last_year
