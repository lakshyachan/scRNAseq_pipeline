#!/bin/bash
  
#SBATCH --job-name=lowconf_analysis
#SBATCH --output=output_lowconf.log        
#SBATCH --time=5:00:00                     
#SBATCH --cpus-per-task=2                  
#SBATCH --mem=5G                           
#SBATCH --partition=shared                 

# Dependencies:
ml anaconda
conda activate sam_bcfenv

# Working directory
cd /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/seqtk_maxDS_gencove_outputs

# Initialise inputs
donors=("zihe_1_0.1c" "eipl_1_0.2c" "joxm_1_maxDS")
thresholds=(0.7 0.75 0.8 0.85 0.95)

for donor in "${donors[@]}"; do
    echo "Processing donor: ${donor}"
    for thres in "${thresholds[@]}"; do
        input_vcf="${donor}.vcf.gz"
        prefix=$(echo $donor | cut -d '_' -f 1-2)
        filtered_vcf="filtered_${prefix}_${thres}.vcf.gz"
        filtered_nolowconf="${prefix}_${thres}_nolowconf.vcf.gz"

        # Filter out SNPs above GP threshold
        bcftools view -i "max(GP[*:0]) > ${thres} || max(GP[*:1]) > ${thres} || max(GP[*:2]) > ${thres}" ${input_vcf} -o ${filtered_vcf}

        # Run python script to edit all LOWCONF values to PASS
        python /home/lchanem1/scratch16-abattle4/lakshmi/code/replace_lowconf.py ${filtered_vcf} ${filtered_nolowconf}
	echo "rm ${filtered_vcf}"
    done
    echo "Finished processing lowconf SNPs for ${donor}"
done
