#!/bin/bash

## This script automates running Monopogen on multiple samples at once.
## Important: This script runs only one sample per job. Thereby generating output files with just one sample.
## Author: Lakshmi Chanemougam
## Usage: bash monopogen_automate.sh

bam_dir="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output"
path="/home/lchanem1/Monopogen"
input_files=$(ls -1 $bam_dir/merged*.bam)
echo "$input_files"
echo The above files are being processed using Monopogen..

for file in $input_files; do
	donor_name=$(basename -s '.bam' "$file" | cut -d'_' -f2-)
        OUT="${bam_dir}/${donor_name}-results"
        mkdir -p ${OUT}
	
	bam_lst="${bam_dir}/${donor_name}.bam.lst"
	echo "${donor_name},${file}" > $bam_lst

        job_script="run_${donor_name}_monopogen.sh"

        echo -e '#!/bin/bash' > $job_script
        echo "#SBATCH --job-name=${donor_name}_monopogen" >> $job_script
        echo "#SBATCH --output=${donor_name}_germline.log" >> $job_script
        echo "#SBATCH --time=48:00:00" >> $job_script
	echo "#SBATCH --cpus-per-task=24" >> $job_script
        echo "#SBATCH --mem=80G" >> $job_script
	echo "#SBATCH --partition=parallel" >> $job_script

	echo "source ~/.bashrc" >> $job_script
	echo "ml mamba" >> $job_script
	echo "mamba activate monopogen_env" >> $job_script
	echo "python ${path}/src/Monopogen.py preProcess -b ${bam_lst} -o ${OUT} -a ${path}/apps -t 22" >> $job_script
	echo "python ${path}/src/Monopogen.py germline -a ${path}/apps -t 15 -r ${bam_dir}/region.lst -p /home/lchanem1/data-abattle4/lakshmi/GRCh37_renamed/ -g /home/lchanem1/data-abattle4/lakshmi/hs37d5_wchr.fa -s all -o ${OUT}" >> $job_script
	sbatch $job_script
done
