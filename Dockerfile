### copyright 2017-2021 Regents of the University of California and the Broad Institute. All rights reserved.
FROM rocker/r-ver:4.0.4

MAINTAINER Barbara Hill <bhill@broadinstitute.org>

RUN apt update \
    && apt install -y git=1:2.25.1-1ubuntu3.2 \
    && apt install -y zlib1g-dev=1:1.2.11.dfsg-2ubuntu1.2 \
    && apt install -y libcurl4-openssl-dev=7.68.0-1ubuntu2.7 \
    && apt install -y libbz2-dev=1.0.8-2 \
    && apt install -y liblzma-dev=5.2.4-1ubuntu1 \
    && apt install -y libxml2-dev=2.9.10+dfsg-5ubuntu0.20.04.1

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

# docker run --rm -it --user gpuser -v /c/Users/MyUSER/PathTo/TCGA.SampleSelection:/mnt/mydata:rw genepattern/tcga-sampleselection:beta bash