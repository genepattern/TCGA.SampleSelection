### copyright 2017-2021 Regents of the University of California and the Broad Institute. All rights reserved.
FROM bioconductor/bioconductor_docker:RELEASE_3_12

RUN mkdir /TCGA_SS \
    && chown rstudio /TCGA_SS

USER rstudio
COPY src/*.R /TCGA_SS/
COPY lib/*.tar.gz /TCGA_SS/

RUN Rscript /TCGA_SS/installPkgs.R

# docker build --rm https://github.com/genepattern/TCGA.SampleSelection.git#develop -f Dockerfile -t genepattern/tcga-sampleselection:beta
# make sure this matches the manifest

# docker run --rm -it --user rstudio -v /c/Users/MyUSER/PathTo/TCGA.SampleSelection:/mnt/mydata:rw genepattern/tcga-sampleselection:beta bash