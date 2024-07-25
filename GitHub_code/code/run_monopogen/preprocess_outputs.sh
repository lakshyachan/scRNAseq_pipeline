#!/bin/bash

#SBATCH --job-name=monopogen_results_preprocess
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --mem=5G
#SBATCH --output=preprocess_results.log
#SBATCH --partition=shared

## This script is used to process Monopogen outputs.
## Use it to concatenate phased vcf outputs across chromosomes/samples
## To remove the 'chr' prefix as true genotype files do not have them
## Rename the sample IDs to match true genotype files
## Finally, adjust genotype calls to match true GT format. eg: 1/1 and not 1|1
## Compute the concordance matrix using vcftools --gzdiff
## Author: Lakshmi Chanemougam
## Date: 04/19/2024

# Dependencies
ml samtools
ml anaconda
ml vcftools
conda activate sam_bcfenv

# Input directory with all results
results_dir="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output"
samples=("zihe_1" "iisa_3" "uilk_3" "xojn_3" "qehq_3" "sojd_3" "eipl_1" "letw_1" "poih_4" "joxm_1")
hipsci_names=("HPSI0115i-zihe_1" "HPSI0114i-iisa_3" "HPSI0614i-uilk_3" "HPSI0414i-xojn_3" "HPSI0914i-qehq_3" "HPSI0314i-sojd_3" "HPSI0114i-eipl_1" "HPSI0514i-letw_1" "HPSI0214i-poih_4" "HPSI0114i-joxm_1")

# Preparing Monopogen outputs prior to computing results
for i in ${!samples[@]}; do
	# Concatenate results per sample but across chromosomes
	file_list=()
	temp_concat=$results_dir/${samples[$i]}-results/germline/temp_concat.phased
	for chr_num in {1..22}; do
        	chr_file="$results_dir/${samples[$i]}-results/germline/chr${chr_num}.phased.vcf.gz"
        	bcftools index $chr_file -t
        	file_list+=("$chr_file")
	done
	bcftools concat "${file_list[@]}" -O z -o $temp_concat.vcf.gz
	rm $results_dir/${samples[$i]}-results/germline/*.tbi
	bcftools index $temp_concat.vcf.gz -t
	echo -e "\nConcatenated all chromosomes"

	# Modify the chr prefix in the concatenated file
	# Choosing the correct rename txt file will determine whether 'chr' is added or removed. 
	# Use add_chr.txt if wish to add and remove_chr.txt if otherwise
	# If choosing to remove 'chr' then unedited file MUST be indexed, bcf
	echo -e "\nProcessing file $temp_concat.vcf.gz for ${samples[$i]}"
	bcftools annotate --rename-chrs remove_chr.txt $temp_concat.vcf.gz | bgzip > $temp_concat.renamed.vcf.gz
	echo -e "\nFinished modifying chrs in file"

	# Rename sample name as per true genotype
	# Change | to / in all phased files.
        # This step is not needed if .gp files are used.
	final_output=$results_dir/final_results/${samples[$i]}.phased.final.vcf.gz
	zcat $temp_concat.renamed.vcf.gz | sed "s/merged_${samples[$i]}/${hipsci_names[$i]}/g" | awk -F'\t' 'BEGIN {OFS="\t"} {gsub(/\|/, "/", $10); print}'| gzip > $final_output
	echo -e "\nModified sample names to match HIPSCI and removed | in phased files"
	echo -e "\n****END OF ${samples[$i]} PROCESSING...ready for results***"
	echo -e "\n"
	rm $temp_concat.vcf.gz $temp_concat.vcf.gz.tbi $temp_concat.renamed.vcf.gz
done
