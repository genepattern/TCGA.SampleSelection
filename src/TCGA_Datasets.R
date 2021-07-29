suppressMessages(suppressWarnings(library("getopt")))
suppressMessages(suppressWarnings(library("optparse")))
suppressMessages(suppressWarnings(library("cBioPortalData")))
suppressMessages(suppressWarnings(library("AnVIL")))
#suppressMessages(suppressWarnings(library("dplyr")))

sink(stdout(), type = "message")

arguments = commandArgs(trailingOnly = TRUE)

option_list <- list(make_option("--id", dest = "id"), make_option("--symbol", dest = "symbol"), 
 make_option("--high", dest = "high", type = "numeric"), make_option("--low", 
  dest = "low", type = "numeric"), make_option("--type", dest = "type"), make_option("--msigdb", 
  dest = "msigdb", default = "latest"))

opt <- parse_args(OptionParser(option_list = option_list), positional_arguments = TRUE, 
 args = arguments)$options

tcgasamples = as.character(opt$id)
symbol_query = as.character(opt$symbol)
threshold_pos = as.numeric(opt$high)
threshold_neg = (-1) * abs(as.numeric(opt$low))
data.type = as.character(opt$type)
msigdbversion = as.character(opt$msigdb)
assay = "RNA_Seq_v2_mRNA_median_all_sample_Zscores"  #linear_CNA could also work
set.seed(147)

cbiosamples <- paste0(tolower(tcgasamples), "_tcga")

# Getting TCGA Dataset
dataset = paste0("http://gdac.broadinstitute.org/runs/stddata__2016_01_28/data/", 
 tcgasamples, "/20160128/gdac.broadinstitute.org_", tcgasamples, ".Merge_rnaseqv2__illuminahiseq_rnaseqv2__unc_edu__Level_3__RSEM_genes__data.Level_3.2016012800.0.0.tar.gz")
output <- paste0(c("TCGA", tcgasamples, symbol_query, "HIGH_stdev_greater_than", 
 threshold_pos, "vs", "LOW_stdev_less_than_neg", abs(threshold_neg)), collapse = "_")

if (msigdbversion == "latest") {
 versionquery <- readLines("http://msigdb.org")
 versionquery <- strsplit(versionquery[grep(pattern = "<h1 class=\"msigdbhome\">", 
  versionquery)], " |<|>")
 versionquery <- versionquery[[1]][grep(pattern = "v[0-9]\\.[0-9]", versionquery[[1]])]
 msigdbversion <- gsub("v", "", versionquery)
}

if (as.numeric(msigdbversion) >= 7.2) {
 symbolchip <- read.table(url(paste0("https://data.broadinstitute.org/gsea-msigdb/msigdb/annotations_versioned/Human_Gene_Symbol_with_Remapping_MSigDB.v", 
  msigdbversion, ".chip")), header = TRUE, stringsAsFactors = FALSE, sep = "\t", 
  quote = "", fill = TRUE, na = "")
} else if (as.numeric(msigdbversion) == 7.1) {
 symbolchip <- read.table(url(paste0("https://data.broadinstitute.org/gsea-msigdb/msigdb/annotations_versioned/Human_Symbol_with_Remapping_MSigDB.v", 
  msigdbversion, ".chip")), header = TRUE, stringsAsFactors = FALSE, sep = "\t", 
  quote = "", fill = TRUE, na = "")
} else if (as.numeric(msigdbversion) < 7.1) {
 stop(paste0("MSigDB Version ", msigdbversion, " is not supported. Please try a newer version."))
}
symbolchip <- symbolchip[, -c(3)]

symbol_mapped <- symbolchip[symbolchip$Probe.Set.ID == symbol_query, ][, c(2)]
if (length(symbol_mapped) > 1) {
 message("Error: More than one possible mapping was detected for selected gene in the TCGA Dataset")
 print(symbol_mapped)
 stop()
}

if (length(symbol_mapped) == 0) {
stop(paste0("The symbol \"", opt$symbol, "\" was not recognised as a valid gene."))
} else if (length(symbol_mapped) == 1) {
print(paste0("The symbol \"", opt$symbol, "\" was recognised as a valid gene: ", symbol_mapped))
} else {
stop(paste0("An error was encountered with the mapping of \"", opt$symbol, "\" to valid gene symbols: ", symbol_mapped))
}

temp <- tempfile()
suppressMessages(suppressWarnings(download.file(dataset, temp)))
fname_zipped = basename(dataset)
fnames = as.character(untar(temp, list = TRUE))
untar(temp)
unlink(fnames[basename(fnames) == "MANIFEST.txt"])
fnames = fnames[basename(fnames) != "MANIFEST.txt"]
lst = vector("list", length(fnames))
for (i in seq_along(fnames)) {
 lst[[i]] = read.table(fnames[i], stringsAsFactors = FALSE, sep = "\t")
}
unlink(fnames)
unlink(temp)

data <- lst[[1]]
names <- do.call("rbind", strsplit(data[, c(1)], "|", fixed = TRUE))

if (data.type == "scaled_estimate") {
 data <- cbind(as.data.frame(names[, c(2)], stringsAsFactors = FALSE), data[, 
  data[c(2), ] == "scaled_estimate"])
} else if (data.type == "raw_count") {
 data <- cbind(as.data.frame(names[, c(2)], stringsAsFactors = FALSE), data[, 
  data[c(2), ] == "raw_count"])
}


names(data) = data[c(1), ]
data <- data[-c(1, 2), ]

if (as.numeric(msigdbversion) == 7.1 || as.numeric(msigdbversion) == 7.2) {
 chip <- read.table(url(paste0("https://data.broadinstitute.org/gsea-msigdb/msigdb/annotations_versioned/Human_NCBI_Entrez_Gene_ID_MSigDB.v", 
  msigdbversion, ".chip")), header = TRUE, stringsAsFactors = FALSE, sep = "\t", 
  quote = "", fill = TRUE, na = "")
} else {
 chip <- read.table(url(paste0("https://data.broadinstitute.org/gsea-msigdb/msigdb/annotations_versioned/Human_NCBI_Gene_ID_MSigDB.v", 
  msigdbversion, ".chip")), header = TRUE, stringsAsFactors = FALSE, sep = "\t", 
  quote = "", fill = TRUE, na = "")
}

chip <- chip[, -c(3)]
mappeddata <- merge(x = chip, y = data, by.x = 1, by.y = 1, all = FALSE, no.dups = FALSE)
# ezid_lookup <- mappeddata[mappeddata$Gene.Symbol==symbol_mapped,][,c(1)]
# if(length(ezid_lookup) > 1) { message('More than one possible EntrezGeneID
# mapping was detected for selected gene in the TCGA Dataset') stop() }
mappeddata <- mappeddata[, -c(1)]

mappeddata[, c(2:ncol(mappeddata))] <- sapply(mappeddata[, c(2:ncol(mappeddata))], 
 as.numeric)
mappeddata[is.na(mappeddata)] <- 0

mappeddata <- mappeddata %>% group_by(.data$Gene.Symbol) %>% summarise_all(sum) %>% 
 data.frame()

print(paste0("Unfiltered dataset contains ", ncol(mappeddata)-1, " samples."))

# Retrieve Sample Expression Thresholding Information from cBioPortal

cbiodata <- suppressMessages(suppressWarnings(cBioDataPack(cbiosamples, ask = FALSE)))
assays <- assays(cbiodata)
cbioassay <- assays[[assay]]
cbioassay <- as.data.frame(cbind(rownames(cbioassay), cbioassay), stringsAsFactors = FALSE)
mappedcbioassay <- merge(x = chip, y = cbioassay, by.x = 1, by.y = 1, all = FALSE, 
 no.dups = FALSE)
mappedcbioassay <- mappedcbioassay[, -c(1)]
mappedcbioassay[, c(2:ncol(mappedcbioassay))] <- sapply(mappedcbioassay[, c(2:ncol(mappedcbioassay))], 
 as.numeric)
mappedcbioassay[is.na(mappedcbioassay)] <- 0
mappedcbioassay <- mappedcbioassay %>% group_by(.data$Gene.Symbol) %>% summarise_all(max) %>% 
 data.frame()
allnames <- names(mappeddata)

sample_pos <- names(mappedcbioassay)[mappedcbioassay[mappedcbioassay$Gene.Symbol == 
 symbol_mapped, ] >= as.numeric(threshold_pos)]
sample_pos <- sample_pos[sample_pos != "Gene.Symbol"]
sample_neg <- names(mappedcbioassay)[mappedcbioassay[mappedcbioassay$Gene.Symbol == 
 symbol_mapped, ] <= as.numeric(threshold_neg)]
sample_neg <- sample_neg[sample_neg != "Gene.Symbol"]

if (length(sample_pos) == 0) {
 if (length(sample_neg) == 0) {
  stop(paste0("No samples were selected for either condition."))
 }
 stop(paste0("No samples were selected for the positive condition."))
}
if (length(sample_neg) == 0) {
 stop(paste0("No samples were selected for the negative condition."))
}

print(paste0("Samples selected for the positive condition: ", length(sample_pos)))
print(paste0("Samples selected for the negative condition: ", length(sample_neg)))
print(paste0("Total samples selected: ", length(sample_pos)+length(sample_neg)))

matches_pos <- unique(grep(paste(sample_pos, collapse = "|"), allnames, value = TRUE))
matches_neg <- unique(grep(paste(sample_neg, collapse = "|"), allnames, value = TRUE))
fullnames <- c(matches_pos, matches_neg)
restricted <- mappeddata[, fullnames]

clslabels <- c(replicate(length(matches_pos), "HIGH"), replicate(length(matches_neg), 
 "LOW"))

write.table(paste(c(dim(restricted)[2], 2, "1"), collapse = " "), paste0(output, 
 ".cls"), sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE)
write.table(paste("#", paste0(symbol_query, "_HIGH"), paste0(symbol_query, "_LOW"), 
 collapse = " "), paste0(output, ".cls"), sep = "\t", row.names = FALSE, col.names = FALSE, 
 quote = FALSE, append = TRUE)
write.table(paste(clslabels, collapse = " "), paste0(output, ".cls"), sep = "\t", 
 row.names = FALSE, col.names = FALSE, quote = FALSE, append = TRUE)

matrix <- as.data.frame(cbind(NAME = mappeddata[, c(1)], Description = mappeddata[, 
 c(1)], restricted), stringsAsFactors = FALSE)

if (data.type == "scaled_estimate") {
 write.table("#1.2", paste0(output, ".TPM.gct"), row.names = FALSE, col.names = FALSE, 
  quote = FALSE)
 write.table(t(as.data.frame(dim(restricted))), paste0(output, ".TPM.gct"), sep = "\t", 
  row.names = FALSE, col.names = FALSE, quote = FALSE, append = TRUE)
 suppressWarnings(write.table(matrix, paste0(output, ".TPM.gct"), sep = "\t", 
  row.names = FALSE, col.names = TRUE, quote = FALSE, append = TRUE))
} else if (data.type == "raw_count") {
 write.table("#1.2", paste0(output, ".counts.gct"), row.names = FALSE, col.names = FALSE, 
  quote = FALSE)
 write.table(t(as.data.frame(dim(restricted))), paste0(output, ".counts.gct"), 
  sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE, append = TRUE)
 suppressWarnings(write.table(matrix, paste0(output, ".counts.gct"), sep = "\t", 
  row.names = FALSE, col.names = TRUE, quote = FALSE, append = TRUE))
}
