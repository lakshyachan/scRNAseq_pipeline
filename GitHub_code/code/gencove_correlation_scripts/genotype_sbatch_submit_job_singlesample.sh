#!/bin/bash

#SBATCH --job-name=genotype_corr          # Job name
#SBATCH --output=genotype_corr_%j.log     # Standard output and error log (%j expands to jobId)
#SBATCH --time=01:00:00                   # Time limit hrs:min:sec
#SBATCH --cpus-per-task=20                # Number of CPU cores per task
#SBATCH --mem=70G                         # Total memory limit
#SBATCH --partition=defq                  # Partition to submit to, replace with your partition

#module load bcftools                      # Load bcftools module if needed, adjust as necessary
module load anaconda

# Call the main script with args and parameters
./genotype_correlation_main.sh \
-e sam_bcfenv \
-o /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/scripts \
-b xojn_3_0.1c_autonew \
-g /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/gencove_outputs/xojn_3_0.1c.vcf.gz \
-r /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0414i-xojn_3.wec.gtarray.HumanCoreExome-12_v1_0.20160912.genotypes.vcf.gz
