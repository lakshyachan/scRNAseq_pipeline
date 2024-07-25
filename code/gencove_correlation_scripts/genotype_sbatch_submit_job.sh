#!/bin/bash

#SBATCH --job-name=genotype_corr_array     # Job name for the array
#SBATCH --output=genotype_corr_array_%A_%a.log   # Standard output and error log with array ID (%A expands to job ID, %a expands to task ID)
#SBATCH --time=1:00:00                   # Time limit hrs:min:sec
#SBATCH --cpus-per-task=20                # Number of CPU cores per task
#SBATCH --mem=70G                         # Total memory limit
#SBATCH --partition=defq                  # Partition to submit to, replace with your partition
#SBATCH --array=1-5                       # Number of tasks in the array (number of donors)

#module load bcftools                      # Load bcftools module if needed, adjust as necessary
module load anaconda

# Array of values for -g, -r, and -b parameters, one for each donor
declare -a b_values=(
#"qehq_3_0.1c_auto"
    "eipl_1_0.1c_autofinal"
    "letw_1_0.1c_autofinal"
    "sojd_3_0.1c_autofinal"
    "poih_4_0.1c_autofinal"
    "joxm_1_0.1c_autofinal"
)

declare -a g_values=(
#"/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/gencove_outputs/qehq_3_0.1cfinal.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/gencove_outputs/eipl_1_0.1cfinal.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/gencove_outputs/letw_1_0.1cfinal.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/gencove_outputs/sojd_3_0.1cfinal.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/gencove_outputs/poih_4_0.1cfinal.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/gencove_outputs/joxm_1_0.1cfinal.vcf.gz"
)

declare -a r_values=(
#"/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0914i-qehq_3.wec.gtarray.HumanCoreExome-12_v1_0.20160912.genotypes.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0114i-eipl_1.wec.gtarray.HumanCoreExome-12_v1_0.20141111.genotypes.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0514i-letw_1.wec.gtarray.HumanCoreExome-12_v1_0.20160912.genotypes.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0314i-sojd_3.wec.gtarray.HumanCoreExome-12_v1_0.20141111.genotypes.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0214i-poih_4.wec.gtarray.HumanCoreExome-12_v1_0.20160912.genotypes.vcf.gz"
    "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0114i-joxm_1.wec.gtarray.HumanCoreExome-12_v1_0.20141111.genotypes.vcf.gz"
)

# Task ID starts from 1
task_id=${SLURM_ARRAY_TASK_ID}

# Call the main script with args and parameters for the corresponding donor
./genotype_correlation_main.sh \
-e sam_bcfenv \
-o /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/scripts \
-b ${b_values[$((task_id-1))]} \
-g ${g_values[$((task_id-1))]} \
-r ${r_values[$((task_id-1))]}
