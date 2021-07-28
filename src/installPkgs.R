suppressMessages(suppressWarnings(install.packages("/TCGA_SS/getopt_1.20.3.tar.gz")))
suppressMessages(suppressWarnings(install.packages("/TCGA_SS/optparse_1.6.6.tar.gz")))
suppressMessages(suppressWarnings(install.packages("/TCGA_SS/generics_0.1.0.tar.gz")))
suppressMessages(suppressWarnings(install.packages("/TCGA_SS/tidyselect_1.1.1.tar.gz")))
suppressMessages(suppressWarnings(install.packages("/TCGA_SS/pillar_1.6.1.tar.gz")))
suppressMessages(suppressWarnings(install.packages("/TCGA_SS/dplyr_1.0.7.tar.gz")))

suppressMessages(suppressWarnings(BiocManager::install("cBioPortalData", version = "3.12", ask = FALSE, quiet = TRUE)))
# 2.2.11, from Bioconductor v3.12
suppressMessages(suppressWarnings(BiocManager::install("AnVIL", version = "3.12", ask = FALSE, quiet = TRUE)))
# 1.2.0, from Bioconductor v3.12
