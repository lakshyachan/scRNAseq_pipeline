#!/bin/bash
#SBATCH --job-name=genotypes          	# Job name
#SBATCH --output=downloads.log     	# Standard output and error log (with job ID)
#SBATCH --time=36:00:00                 # Time limit hrs:min:sec
#SBATCH --cpus-per-task=1               # Number of CPU cores per task
#SBATCH --mem=5G                        # Total memory limit
#SBATCH --partition=shared              # Partition to submit to, replace with your partition

# Download remaining genotype files for Cuomo 2020
cd /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/remaining_genotypes
wget -i /home/lchanem1/scratch16-abattle4/lakshmi/code/get_cuomo_data/remaining_genotypes_ftp.txt
