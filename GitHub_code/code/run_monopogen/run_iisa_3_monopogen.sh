#!/bin/bash
#SBATCH --job-name=iisa_3_monopogen
#SBATCH --output=iisa_3_germline.log
#SBATCH --time=48:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=80G
#SBATCH --partition=parallel
source ~/.bashrc
ml mamba
mamba activate monopogen_env
python /home/lchanem1/Monopogen/src/Monopogen.py preProcess -b /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output/iisa_3.bam.lst -o /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output/iisa_3-results -a /home/lchanem1/Monopogen/apps -t 22
python /home/lchanem1/Monopogen/src/Monopogen.py germline -a /home/lchanem1/Monopogen/apps -t 10 -r /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output/region.lst -p /home/lchanem1/data-abattle4/lakshmi/GRCh37_renamed/ -g /home/lchanem1/data-abattle4/lakshmi/hs37d5_wchr.fa -s all -o /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/monopogen_output/iisa_3-results
