#!/bin/bash

## This script downloads all raw fastqs needed for CUOMO dataset.
## Author: Lakshmi Chanemougam
## Usage: bash get_fastqs.sh
OUT=/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/raw_data/${donor_name}/
cd /home/lchanem1/scratch16-abattle4/lakshmi/code/get_cuomo_data/remaining_fastq_ftps

file_list=$(ls -1 *.txt | head -n 30)
echo "$file_list"
echo "The above samples are being downloaded"

for file in $file_list; do
	donor_name=$(echo "$file" | cut -d '_' -f 1-2)
	OUT=/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/raw_data/${donor_name}/
	mkdir -p ${OUT}
        job_script="get_${donor_name}_fastqs.sh"
	
	echo -e '#!/bin/bash' > $job_script
	echo "#SBATCH --job-name=${donor_name}_download" >> $job_script
	echo "#SBATCH --output=${donor_name}_download.log" >> $job_script
	echo "#SBATCH --time=30:00:00" >> $job_script
	echo "#SBATCH --mem=3G" >> $job_script

	echo "wget -i $file -P ${OUT}" >> $job_script
	sbatch $job_script
done
