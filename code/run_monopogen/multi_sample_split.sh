#!/bin/bash

#SBATCH --job-name=split_monopogen_op
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --mem=5G
#SBATCH --partition=shared

## This script is used to process Monopogen outputs.
## Use it to concatenate phased vcf outputs across chromosomes/samples
## To remove the 'chr' prefix as true genotype files do not have them
## Rename the sample IDs to match true genotype files
## Compute the concordance matrix using vcftools --gzdiff
## Author: Lakshmi Chanemougam
## Date: 04/17/2024

# Dependencies
ml samtools
ml anaconda
conda activate sam_bcfenv

# Choose directory of output files to modify
dir=/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output/out/germline
temp_concat=$dir/temp_concat.gp

# STEP 1: concatenate all phased vcf outputs across chromosomes for a Monopogen run
file_list=()
for chr_num in {1..22}; do
	chr_file="$dir/chr${chr_num}.gp.vcf.gz"
	bcftools index $chr_file -t
	file_list+=("$chr_file")
done
bcftools concat "${file_list[@]}" -O z -o $temp_concat.vcf.gz
rm $dir/*.tbi
bcftools index $temp_concat.vcf.gz -t
echo "Concatenated all chromosomes"

# STEP 2: Modify the chr prefix in the concatenated file
# Choosing the correct rename txt file will determine whether 'chr' is added or removed. Use add_chr.txt if wish to add and remove_chr.txt if otherwise
# If choosing to remove 'chr' then unedited file MUST be indexed, bcftools cannot annotate otherwise. Previous step does this by default.
echo "Processing file"
echo "Correct usage: bcftools annotate --rename-chrs <format_to_rename.txt> <vcf_input> | bgzip > <vcf_renamed_output>"
bcftools annotate --rename-chrs remove_chr.txt $temp_concat.vcf.gz | bgzip > $temp_concat.renamed.vcf.gz
echo "Finished modifying chrs in file"

# STEP 3: Rename sample as per true genotype and split vcf per sample
sample_names=($(bcftools query -l "$temp_concat.renamed.vcf.gz"))
hipsci_names=("HPSI0115i-zihe_1" "HPSI0114i-iisa_1" "HPSI0614i-uilk_3" "HPSI0414i-xojn_3" "HPSI0914i-qehq_3" "HPSI0314i-sojd_3" "HPSI0114i-eipl_1" "HPSI0514i-letw_1" "HPSI0214i-poih_4")
echo "Following samples were detected and will be split up after being renamed"
for i in "${!sample_names[@]}"; do
    output_file="$dir/${hipsci_names[$i]}.gp.final.vcf.gz"
    echo "${sample_names[$i]}"
    bcftools view -Ov -s "${sample_names[$i]}" "$temp_concat.renamed.vcf.gz" | sed "s/${sample_names[$i]}/${hipsci_names[$i]}/g" > "$output_file"
done
echo "Finished splitting up vcf per sample and renamed sample as per true genotype"
