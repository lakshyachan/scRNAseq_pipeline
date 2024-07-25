## Script takes in list of ENSEMBL Gene IDs, finds lengths and co-ordinates
## Author: Lakshmi Chanemougam
.libPaths(c(.libPaths(), "/home/lchanem1/rlibs/4.0.2/gcc/9.3.0"))

library(biomaRt)
genes_list <- readLines("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/gene_ids.txt")
extracted_values <- gsub('\\"(.*?)\\"', '\\1', genes_list)
genes_list <- c(extracted_values)

human <- useMart("ensembl", dataset="hsapiens_gene_ensembl")
gene_coords=getBM(attributes=c("chromosome_name", "hgnc_symbol", "ensembl_gene_id", "start_position", "end_position"), filters="ensembl_gene_id", values=genes_list, mart=human)
gene_coords$size=gene_coords$end_position - gene_coords$start_position
gene_coords

missing_ids <- genes_list[!(genes_list %in% gene_coords$ensembl_gene_id)]
## 139 Gene IDs could not be found on ENSEMBL strangely. May have to omit them out of analysis for now.

# Lower and upper bound for all gene regions
gene_coords$lower_bound <- gene_coords$start_position - 10000
gene_coords$upper_bound <- gene_coords$end_position + 10000

write.csv(gene_coords, "gene_annotations.csv", row.names = FALSE)

## Writing bed files for a series of files in given directory

library(dplyr)
library(Homo.sapiens)
library(magrittr)
library(biomaRt)

setwd("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/id_lists")
files <- Sys.glob("*.txt")
human <- useMart("ensembl", dataset="hsapiens_gene_ensembl")

for (file in files){
  file_prefix <- sub("\\.\\w+$", "", file)
  genelist <- readLines(file)
  input <- genelist[(genelist %in% biomaRt::keys(Homo.sapiens::Homo.sapiens, keytype = "SYMBOL"))]
  output <- biomaRt::select(Homo.sapiens::Homo.sapiens, input, c("TXCHROM","TXSTART","TXEND"), "SYMBOL") %>% 
    filter(nchar(as.character(TXCHROM)) < 6)  %>% group_by(SYMBOL) %>% 
    mutate("start"= min(TXSTART),"end" =max(TXEND), ) %>% ungroup() %>% 
    dplyr::select(TXCHROM, start, end, SYMBOL) %>% distinct()
  
  # Flanking 10 kbp on either direction
  output$start <- output$start - 10000
  output$end <- output$end + 10000
  
  # Removing 'chr' from chromosome names
  output$TXCHROM <- gsub("chr", "", output$TXCHROM)
  
  # Sorting by chromosome number
  output <- output[order(output$TXCHROM, decreasing = FALSE), ]
  
  write.table(output, file = paste0("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/bed_files/", file_prefix, ".bed"), quote = FALSE, sep = " ", row.names = FALSE, col.names = FALSE)
}


## Writing cumulative bed file for all genes present in the count matrix
genes_list <- readLines("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/gene_ids.txt")
extracted_values <- gsub('\\"(.*?)\\"', '\\1', genes_list)
genelist <- c(extracted_values)

input <- genelist[(genelist %in% biomaRt::keys(Homo.sapiens::Homo.sapiens, keytype = "ENSEMBL"))]
output <- biomaRt::select(Homo.sapiens::Homo.sapiens, input, c("TXCHROM","TXSTART","TXEND"), "ENSEMBL") %>% 
  filter(nchar(as.character(TXCHROM)) < 6)  %>% group_by(ENSEMBL) %>% 
  mutate("start"= min(TXSTART),"end" =max(TXEND), ) %>% ungroup() %>% 
  dplyr::select(TXCHROM, start, end, ENSEMBL) %>% distinct()
output$TXCHROM <- gsub("chr", "", output$TXCHROM)
output <- output[order(output$TXCHROM, decreasing = FALSE), ]
# Store bed file for regions covering all genes in the count matrix first
write.table(output, file = paste0("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/all_gene_regions.bed"), quote = FALSE, sep = " ", row.names = FALSE, col.names = FALSE)

# Create .bed file for regions between thresholds and gene region itself
## Run bin_bed.sh 

# NOW REDUNDANT: Gene regions plus distance to be excluded
for (i in seq_along(c(10000, 100000, 500000, 1000000))){
  file_prefixes <- c("10kbp", "100kbp", "500kbp", "1mbp")
  temp_output <- output  
  temp_output$start <- temp_output$start - c(10000, 100000, 500000, 1000000)[i]
  temp_output$end <- temp_output$end + c(10000, 100000, 500000, 1000000)[i]
  write.table(temp_output, file = paste0("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/all_genes_", file_prefixes[i], ".bed"), quote = FALSE, sep = " ", row.names = FALSE, col.names = FALSE)
}