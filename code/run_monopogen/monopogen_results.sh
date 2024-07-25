#!/bin/bash

#SBATCH --job-name=monopogen_results_process
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --mem=5G
#SBATCH --output=results.log
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
dir=/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output/joxm_1_results/germline

# STEP 1: concatenate all phased vcf outputs across chromosomes for a Monopogen run
file_list=()
for chr_num in {1..22}; do
	chr_file="$dir/chr${chr_num}.gp.vcf.gz"
	bcftools index $chr_file -t
	file_list+=("$chr_file")
done
bcftools concat "${file_list[@]}" -O z -o $dir/joxm_1.gp.vcf.gz
rm $dir/*.tbi
bcftools index $dir/joxm_1.gp.vcf.gz -t
echo "Concatenated all chromosomes"

# STEP 2: Modify the chr prefix in the concatenated file
# Choosing the correct rename txt file will determine whether 'chr' is added or removed. Use add_chr.txt if wish to add and remove_chr.txt if otherwise
# If choosing to remove 'chr' then unedited file MUST be indexed, bcftools cannot annotate otherwise. Previous step does this by default.
echo "Processing file"
echo "Correct usage: bcftools annotate --rename-chrs <format_to_rename.txt> <vcf_input> | bgzip > <vcf_renamed_output>"
bcftools annotate --rename-chrs remove_chr.txt $dir/joxm_1.gp.vcf.gz | bgzip > $dir/joxm_1.gp.renamed.vcf.gz
echo "Finished modifying chrs in file"

# STEP 3: Rename the sample IDs to match HIPSCI True GT
hipsci_id="HPSI0114i-joxm_1"
zcat $dir/joxm_1.gp.renamed.vcf.gz | sed "s/merged_joxm_1/HPSI0114i-joxm_1/g" | gzip > $dir/joxm_1.gp.final.vcf.gz

# STEP 4: Monopogen results
ml vcftools
true_gt_file="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0114i-joxm_1.wec.gtarray.HumanCoreExome-12_v1_0.20141111.genotypes.vcf.gz"
# Remove homozygous variants (only 0/0)
zless $dir/joxm_1.gp.final.vcf.gz | grep -v "0/0" | bgzip > $dir/joxm_1.gp.final.het.vcf.gz
# Generate concordance matrix
# Note: specify -chr if only for a chromosome
vcftools --gzvcf $dir/joxm_1.gp.final.het.vcf.gz --gzdiff $true_gt_file --diff-discordance-matrix --out $dir/joxm_1_chr10_22 --chr 10 --chr 11 --chr 12 --chr 13 --chr 14 --chr 15 --chr 16 --chr 17 --chr 18 --chr 19 --chr 20 --chr 21 --chr 22
vcftools --gzvcf $dir/joxm_1.gp.final.het.vcf.gz --gzdiff $true_gt_file --diff-discordance-matrix --out $dir/joxm_1_chr1_9 --chr 1 --chr 2 --chr 3 --chr 4 --chr 5 --chr 6 --chr 7 --chr 8 --chr 9
echo "Completed Monopogen output processing"
echo "Merging output files"
awk 'NR==FNR {if (NR>1) {for (i=2; i<=NF; i++) row[FNR,i]=$i}; next} {if (FNR>1) {for (i=2; i<=NF; i++) $i += row[FNR,i]}} 1' $dir/joxm_1_*_*.diff.discordance_matrix > $dir/joxm_1_allchr.diff.discordance_matrix
