#!/bin/bash

#SBATCH --job-name=compute_matrices
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --mem=5G
#SBATCH --output=matrices.log
#SBATCH --partition=shared

## This script computes concordance, FPR and other metrics for Monopogen outputs.
## Run this after pre-processing Monopogen outputs.
## Author: Lakshmi Chanemougam
## Date: 04/19/2024

ml vcftools
final_results="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output/final_results"
samples=("zihe_1" "iisa_3" "uilk_3" "xojn_3" "qehq_3" "sojd_3" "eipl_1" "letw_1" "poih_4" "joxm_1")
hipsci_names=("HPSI0115i-zihe_1" "HPSI0114i-iisa_3" "HPSI0614i-uilk_3" "HPSI0414i-xojn_3" "HPSI0914i-qehq_3" "HPSI0314i-sojd_3" "HPSI0114i-eipl_1" "HPSI0514i-letw_1" "HPSI0214i-poih_4" "HPSI0114i-joxm_1")
gt_dir="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes"

for i in ${!samples[@]}; do
	echo -e \nComputing results for ${samples[$i]}
	true_gt_file=$(ls $gt_dir/${hipsci_names[$i]}*.vcf.gz)
	echo -e \nGenotype file used for this sample is $true_gt_file

	# If wish to remove homozygous variants, then do this:
	#zless $final_results/${samples[$i]}.phased.final.vcf.gz | grep -v "0/0" | gzip > $final_results/${samples[$i]}.phased.final.het.vcf.gz

	# Generate concordance matrix
	# First for chromosome 10 to 22
	echo vcftools --gzvcf $final_results/${samples[$i]}.phased.final.het.vcf.gz --gzdiff $true_gt_file --diff-discordance-matrix --out $final_results/${samples[$i]}_chr10_22 --chr 10 --chr 11 --chr 12 --chr 13 --chr 14 --chr 15 --chr 16 --chr 17 --chr 18 --chr 19 --chr 20 --chr 21 --chr 22
	# Then for chromosome 1 to 9
	echo vcftools --gzvcf $final_results/${samples[$i]}.phased.final.het.vcf.gz --gzdiff $true_gt_file --diff-discordance-matrix --out $final_results/${samples[$i]}_chr1_9 --chr 1 --chr 2 --chr 3 --chr 4 --chr 5 --chr 6 --chr 7 --chr 8 --chr 9
	
	# Merge concordance matrices across chromosomes
	echo -e \nMerging output files
	awk 'BEGIN {FS="\t"} NR==FNR {if (NR==1 && FNR==1) {header_printed=1; print} else if (NR>1) {for (i=2; i<=NF; i++) row[FNR,i]=$i}; next} {if (!header_printed) {print; header_printed=1} else if (FNR>1) {printf "%s\t", $1; for (i=2; i<=NF; i++) {printf "%d\t", $i + row[FNR,i]}; printf "\n"}}' $final_results/${samples[$i]}_chr*_*.diff.discordance_matrix > $final_results/${samples[$i]}_all.diff.discordance_matrix

	# Calculate metrics from concordance matrices
	# Number of variants detected, FPR, concordance, overall genotyping accuracy
done

