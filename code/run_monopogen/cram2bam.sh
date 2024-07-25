#!/bin/bash

#SBATCH --j=cram2bam_convert
#SBATCH --output=cram2bam.log
#SBATCH --time=36:00:00
#SBATCH --mem=10G
#SBATCH --nodes=1
#SBATCH --partition=shared

## Author: Lakshmi Chanemougam
## This script is meant to find all corresponding .cram files in a folder, convert them to their bam file formats using providing input ref.fa file
## This script will also concatenate all the resulting bam files in a folder. 
## Usage: sbatch cram2bam.sh
## Date: March 19th, 2024

cd /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/cram_data/joxm_1

# Load dependencies
ml anaconda
conda activate sam_bcfenv

for cram_file in *.cram; do
	base_name=$(basename "$cram_file" .cram)
	echo "Processing $base_name"
	samtools view -b -T /home/lchanem1/data-abattle4/lakshmi/hs37d5.fa -o "$base_name.bam" "$base_name.cram"
	echo "Converted .cram to .bam for $base_name"
done

# Merge all output bam files into a single file
samtools merge merged_joxm_1.bam *.bam

# Create index for merged_bam file
samtools index merged_joxm_1.bam

# Move output files into Monopogen input folders
#mv merged* ../../monopogen_output/
