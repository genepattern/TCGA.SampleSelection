# remember to update the tag version here and in your manifest
docker build --rm https://github.com/genepattern/TCGA.SampleSelection.git#develop -f Dockerfile -t genepattern/tcga-sampleselection:<tag>