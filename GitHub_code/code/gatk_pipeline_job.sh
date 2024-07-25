#!/bin/bash

## This script runs the GATK v2 pipeline 
## The required files are as follows:
## Output Directory
## ref.fa: same as one used for aligning cram/bam files if they exist already
## 1000G external reference haplotype panel (reference assembly must be consistent)
## dbsnp vcf (reference assembly must be consistent)
## Load all necessary modules
## Set input directory within script to folder containing all samples' fastq/CRAM/BAM in the SPECIFIED format
## Author: Lakshmi Chanemougam

#SBATCH --j=gatk_variant_call
#SBATCH --output=gatk_variant_call.log
#SBATCH --time=10:00:00
#SBATCH --cpus-per-task=15
#SBATCH --mem=56G
#SBATCH --partition=shared

# Load dependencies
ml gcc/9.3.0
ml bwa
ml samtools
ml picard/2.20.8
ml gatk
ml fastqc
ml tabix

# Dependencies needed for multiqc
#ml GCC/11.3.0
#ml foss/2023a
#ml MultiQC/1.14-foss-2022b

bash gatk_pipeline_v2.sh -o /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gatk_output -s zihe_1 iisa_3
