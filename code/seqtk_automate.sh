#!/bin/bash
  
# SLURM Script for SeqTK Automation
# This script submits a job to the SLURM queue to automate seqtk operations on specified input files.

#SBATCH --job-name=seqtk_automate          # Job name
#SBATCH --output=seqtk_automate.log        # Standard output and error log (with job ID)
#SBATCH --time=10:00:00                    # Time limit hrs:min:sec
#SBATCH --cpus-per-task=2                  # Number of CPU cores per task
#SBATCH --mem=10G                          # Total memory limit
#SBATCH --partition=shared                 # Partition to submit to, replace with your partition

# Execute the seqtk automation script
# Seqtk Automation Script
# This script performs seqtk sampling on specified donor fastq files and compresses the output.
# Usage: ./seqtk_automate.sh

# Directories for input and output
input="/data/abattle4/lakshmi/cuomo_2020/pipeline_files/concat_files"
output="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/seqtk_outputs"
#mkdir -p $output

# Array of donors
donors=("xojn_3" "letw_1" "sojd_3" "poih_4" "joxm_1")

# Loop through each donor to generate seqtk outputs
for donor in "${donors[@]}"; do
    echo "Processing donor: ${donor}"

    # Define input files for R1 and R2
    input_r1="${input}/${donor}_R1.fastq.gz"
    input_r2="${input}/${donor}_R2.fastq.gz"

    # Check if input files exist
    if [[ ! -f "$input_r1" ]] || [[ ! -f "$input_r2" ]]; then
        echo "Input files for ${donor} not found. Skipping."
        continue
    fi

    # Seqtk sub-sample command
    echo "Running seqtk on ${donor}"
    seqtk sample -s 42 "$input_r1" 70000000 > "${output}/${donor}_R1_finalc.fastq"
    seqtk sample -s 42 "$input_r2" 70000000 > "${output}/${donor}_R2_finalc.fastq"
done

# Gzip all created files
echo "Compressing output files..."
for fastq in ${output}/*.fastq; do
    echo "Processing fastq: $fastq"
    gzip -f "$fastq"
done

echo "Seqtk processing completed."
