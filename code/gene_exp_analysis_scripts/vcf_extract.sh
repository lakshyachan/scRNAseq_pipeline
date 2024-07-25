#!/bin/bash

#SBATCH --job-name=subset_vcf
#SBATCH --output=temp.log
#SBATCH --time=05:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=5G
#SBATCH --partition=shared

ml vcftools

# NOTE: Before running verify bed_file, output_dir and output_prefix. Rest can remain as is. 

vcf_dir="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/seqtk_maxDS_gencove_outputs"
bed_file="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/50_100_kbp_within/50_100kbp_within.bed"
output_dir="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/50_100_kbp_within"

for vcf_file in "$vcf_dir"/*_*.vcf.gz; do
    base_name=$(basename "$vcf_file" .vcf.gz)
    prefix=$(echo "$base_name" | rev | cut -d "_" -f 2- | rev)
    #In case of multiple bed files per sample: bed_file="$bed_dir/${prefix}_.bed"
    output_prefix="$output_dir/${prefix}_50_100kbp_w"
    
    echo "Processing VCF file: $vcf_file"
    echo "BED file: $bed_file"
    echo "Output prefix: $output_prefix"
    # To exclude regions
    #vcftools --gzvcf "$vcf_file" --exclude-bed "$bed_file" --out "$output_prefix" --recode --keep-INFO-all
    # To include regions
    vcftools --gzvcf "$vcf_file" --bed "$bed_file" --out "$output_prefix" --recode --keep-INFO-all
    gzip "$output_prefix.recode.vcf"
done

