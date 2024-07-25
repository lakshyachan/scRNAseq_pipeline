#!/bin/bash

OUT=/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/cram_data/${donor_name}/
cd /home/lchanem1/scratch16-abattle4/lakshmi/code/get_cuomo_data/cram_ftps

for file in *.txt; do
	donor_name=$(echo "$file" | cut -d '_' -f 1-2)
	OUT=/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/cram_data/${donor_name}/
	mkdir -p ${OUT}
        job_script="get_${donor_name}_cram.sh"
	failed_files="failed_${donor_name}.txt"
	echo -e '#!/bin/bash' > $job_script
	echo "#SBATCH --job-name=${donor_name}_download" >> $job_script
	echo "#SBATCH --output=${donor_name}_download.log" >> $job_script
	echo "#SBATCH --time=15:00:00" >> $job_script
	echo "#SBATCH --mem-per-cpu=3G" >> $job_script
	echo "wget -i $file -P ${OUT} --rejected-log=$failed_files" >> $job_script
	sbatch $job_script
done
