# Clear the environment
rm(list = ls())

# Clear the console
cat("\014")

# Set the working directory to the current script location
setwd(dirname(rfile::getRelativePath()))

# Close all graphics devices
dev.off()

# Reset R options
options(restart = TRUE)