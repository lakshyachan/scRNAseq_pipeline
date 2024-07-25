#!/bin/bash

#SBATCH --job-name=lowconf_plots
#SBATCH --output=temp.log
#SBATCH --time=05:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=5G
#SBATCH --partition=parallel

ml anaconda
conda activate my-env

python lowconfidence_plots.py



