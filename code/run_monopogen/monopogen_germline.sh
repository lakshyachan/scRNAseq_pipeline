#!/bin/bash

## This script runs the Germline script in the Monopogen tool. 
## This step follows the pre-processing step provided in the Monopogen documentation here: https://github.com/KChen-lab/Monopogen/tree/main
## The required files are as follows:
## bam.lst file
## region.lst file with chr prefix
## Preprocessed bam output folder
## External reference panel
## Reference assembly (.fa) file with chr prefix
## Author: Lakshmi Chanemougam

#SBATCH --j=germline_variants
#SBATCH --output=germline.log
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=80G
#SBATCH --partition=parallel

# Load dependencies
source ~/.bashrc
ml mamba
mamba activate monopogen_env

# Set paths
path="/home/lchanem1/Monopogen"
prep_output="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output"

# Run preprocess function to process bam file outputs
python ${path}/src/Monopogen.py preProcess -b ${prep_output}/bam.lst -o ${prep_output}/joxm_1_results -a ${path}/apps -t 22

# Run germline function to call variants and generate .gl, .gp and .phased.vcf files
# -p is the flag for imputation panel; alter Monopogen.py if method of constructing external panel files is diff
python ${path}/src/Monopogen.py germline \
	-a ${path}/apps -t 10 -r ${prep_output}/region.lst \
	-p /home/lchanem1/data-abattle4/lakshmi/GRCh37_renamed/ \
	-g /home/lchanem1/data-abattle4/lakshmi/hs37d5_wchr.fa -s all -o ${prep_output}/joxm_1_results
