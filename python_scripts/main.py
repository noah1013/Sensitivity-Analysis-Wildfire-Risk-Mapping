import subprocess
import os

# Define the path to your R script
r_cleaner_path = "C:\\Users\\Noagly\\Desktop\\Schools\\nyu\\Projects\\ML_Wildfire_Prevention\\Code\\Sensitivity-Analysis-Wildfire-Risk-Mapping\\R_scripts\\R_Cleaner.R"
r_script_path = "C:\\Users\\Noagly\\Desktop\\Schools\\nyu\\Projects\\ML_Wildfire_Prevention\\Code\\Sensitivity-Analysis-Wildfire-Risk-Mapping\\R_scripts\\reference_data.R"

# Run the R script
result = subprocess.run(["Rscript", "--vanilla", r_cleaner_path])
result = subprocess.run(["Rscript", "--vanilla", r_script_path])

# # Check if the script ran successfully
# if result.returncode == 0:
#     print("R script executed successfully")
# else:
#     print(f"R script failed with return code {result.returncode}")