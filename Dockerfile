### copyright 2017-2021 Regents of the University of California and the Broad Institute. All rights reserved.
FROM rocker/r-ver:4.0.4

MAINTAINER Barbara Hill <bhill@broadinstitute.org>

RUN useradd -ms /bin/bash gpuser
USER gpuser
WORKDIR /home/gpuser

USER root
RUN mkdir /TCGA_SS \
    && chown gpuser /TCGA_SS

USER gpuser
COPY src/*.R /TCGA_SS/
COPY lib/*.tar.gz /TCGA_SS/

USER root
RUN Rscript /TCGA_SS/installPkgs.R

USER gpuser

# docker build --rm https://github.com/genepattern/TCGA.SampleSelection.git#develop -f Dockerfile -t genepattern/tcga-sampleselection:<tag>
# make sure this matches the manifest

# docker run --rm -it --user rstudio -v /c/Users/MyUSER/PathTo/TCGA.SampleSelection:/mnt/mydata:rw genepattern/tcga-sampleselection:beta bash