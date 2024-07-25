#!/bin/bash

## Author: Lakshmi Chanemougam
## Date: 02/23/24
## This script writes bed files to exclude all gene regions present in the raw count matrix. In addition, this file also writes regions close to the gene region and bins them based on specified bin amounts.
## Outputs of this script can be modified in bin_sizes and output_files.
## Use vcftools script to --include only these regions from each Gencove VCF before computing correlation.

bed_file="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/all_gene_regions.bed"

# Define array of bin sizes and corresponding output file names
bin_sizes=(50000 100000 200000 300000 400000 500000)
output_files=("50_100kbp_within.bed" "100_200kbp_within.bed" "200_300kbp_within.bed" "300_400kbp_within.bed" "400_500kbp_within.bed")

# Iterate over each bin size and corresponding output file name
for ((i = 0; i < ${#bin_sizes[@]}; i++)); do
    bin_size=${bin_sizes[i]}
    output_file="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/${output_files[i]}"

    awk -v binSize="$bin_size" '
    BEGIN {
        OFS="\t";
    }
    {
        chr = $1;
        start = $2;
        stop = $3;
        gene_name = $4;

        if (binSize == 50000) {
	    # If flank is 50kbp then the only bin is between 50 to 100kbp from start/end of gene region
            print chr, start - 100000, start - 50000, gene_name;
            print chr, stop + 50000, stop + 100000, gene_name;
        } else {
	    # For flanks equal to or greater than 100kbp, bin them into 100kbp bins to see exact effect of that bin on coverage
            print chr, start - binSize - 100000, start - binSize, gene_name;
            print chr, stop + binSize, stop + binSize + 100000, gene_name;
        }
    }' "$bed_file" > "$output_file"
done

