#!/bin/bash

# Usage information
usage() {
    echo "Usage: $0 -o <output_directory> -s <'sample1 sample2 ...'> [--jumpToCram]"
    echo ""
    echo "Options:"
    echo "  -o, --output-directory <dir>  Specify the output directory where the processed files"
    echo "                               will be stored. This directory will contain the final"
    echo "                               output files of the genomic pipeline."
    echo ""
    echo "  -s, --samples <'sample1 sample2 ...'>"
    echo "                               Provide a space-separated list of sample names."
    echo "                               Each sample name should correspond to a CRAM file or a pair"
    echo "                               of FastQ files, depending on the processing mode."
    echo ""
    echo "  --jumpToCram                 If specified, the script will process CRAM files directly,"
    echo "                               skipping the alignment from FastQ files. Use this flag if"
    echo "                               you already have CRAM files as input instead of FastQ files."
    echo ""
    echo "  --jumpToBam                  If specified, the script will process bam files directly,"
    echo "                               skipping the alignment from FastQ files. Use this flag if"
    echo "                               you already have bamfiles as input instead of FastQ/CRAM files."
    echo ""
    echo "Notes:"
    echo "  - Ensure that the sample names match exactly the names of the FastQ or CRAM files."
    echo "    For FastQ, the files should be named as <sample_name>_R1.fastq.gz and"
    echo "    <sample_name>_R2.fastq.gz. For CRAM, the file should be named as <sample_name>.cram."
    echo ""
    echo "  - This script assumes that all necessary genomic analysis tools (like BWA, SAMtools, GATK) are"
    echo "    installed and properly configured in the execution environment."
    echo ""
    echo "  - The script supports processing multiple samples in a batch. Each sample is processed"
    echo "    individually, and in case of multiple samples, a combined analysis is performed."
    exit 1
}


# Default values for flags
jumpToCram=false
jumpToBam=false


# Parse command line options
while :; do
    if [ $# -le 0 ]; then
        break
    fi

    case $1 in
        -o|--output-directory)
            if [ -n "$2" ]; then
                output_dir=$2
                shift
            else
                echo "Error: -o requires a non-empty option argument."
                usage
            fi
            ;;
        -s|--samples)
            if [ -n "$2" ]; then
                samples=($2)
                shift
            else
                echo "Error: -s requires a non-empty option argument."
                usage
            fi
            ;;
        --jumpToCram)
            jumpToCram=true
            ;;
        --jumpToBam)
            jumpToBam=true
            ;;
        -?*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            break
    esac

    shift
done


# Check if output directory is set
if [ -z "${output_dir}" ]; then
    echo "Error: Output directory not specified."
    usage
fi

# Check if samples are provided
if [ ${#samples[@]} -eq 0 ]; then
    echo "Error: No samples provided."
    usage
fi


# Create necessary directories
create_dir_if_not_exists() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    else
        echo "Directory already exists: $dir"
    fi
}

create_dir_if_not_exists "${output_dir}/data"
create_dir_if_not_exists "${output_dir}/output"


# Environment setup
# Define the input directory
FASTQ_DIR="/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/concat_files"

# Define the paths for tools
BWA="/path_to_bwa"
SAMTOOLS="/path_to_samtools"
PICARD="/path_to_picard"
GATK="/path_to_gatk"

# If conda environment is activated. Or given the
# module load (ml) of bwa,samtools, picard, gatk
BWA="bwa"
SAMTOOLS="samtools"
PICARD="picard"
GATK="gatk"

# Define reference files
REFERENCE_GENOME="/home/lchanem1/data-abattle4/lakshmi/hs37d5.fa"
DBSNP="/home/lchanem1/data-abattle4/lakshmi/dbsnp132_20101103.vcf.gz"


# Time and execute a command
execute_and_time() {
    local step=$1
    local description=$2
    local command=$3
    local start_time=$(date +%s)

    echo "Starting $step: $description"
    eval $command
    local status=$?

    local end_time=$(date +%s)
    if [ $status -ne 0 ]; then
        echo "Error in $step. Exiting."
        exit $status
    else
        echo "$step completed successfully in $((end_time - start_time)) seconds."
    fi
}


# Function to index reference genome
index_reference_genome() {
    local ref_genome=$1
    execute_and_time "Index Reference Genome" "Indexes the reference genome using BWA." "
        $BWA index ${ref_genome}"
}


# Function for aligning genome with BWA
align_genome() {
    local sample=$1
    local fastq1=$2
    local fastq2=$3
    local bam_output="${output_dir}/output/${sample}.bam"
    execute_and_time "Align Genome" "Aligns raw sequencing data to the human genome using BWA." "
        $BWA mem -M -t 2 \
        ${REFERENCE_GENOME} \
        ${fastq1} \
        ${fastq2} | \
        $SAMTOOLS view -b -h -o ${bam_output} -"
    echo "${bam_output}"
}


# Function for sorting BAM file with Picard
sort_bam() {
    local sample=$1
    local bam_input=$2
    local sorted_bam="${output_dir}/output/${sample}.sort.bam"
    execute_and_time "Sort BAM" "Sorts the BAM file using Picard." "
        $PICARD SortSam \
        I=${bam_input} \
        O=${sorted_bam} \
        SORT_ORDER=coordinate \
        CREATE_INDEX=True"
    echo "${sorted_bam}"
}


# Function for processing CRAM files: convert to BAM, sort, and index
process_cram() {
    local sample=$1
    local cram_file="${output_dir}/data/${sample}.cram"
    local sorted_bam="${output_dir}/output/${sample}_sorted.bam"

    execute_and_time "Process CRAM" "Converts CRAM to BAM, sorts, and indexes the BAM file." "
        $SAMTOOLS view -T $REFERENCE_GENOME -b ${cram_file} | \
        $SAMTOOLS sort -o ${sorted_bam} - &&
        $SAMTOOLS index ${sorted_bam}"
    echo "${sorted_bam}"
}


# Function for marking duplicate reads with Picard
mark_duplicates() {
    local sample=$1
    local sorted_bam=$2
    local dedup_bam="${output_dir}/output/${sample}.sort.dup.bam"
    execute_and_time "Mark Duplicates" "Marks duplicate reads in the BAM file using Picard." "
        $PICARD MarkDuplicates \
        I=${sorted_bam} \
        O=${dedup_bam} \
        M=${output_dir}/output/${sample}_dup_metrics.txt"
    echo "${dedup_bam}"
}


# Function for Base Quality Recalibration with GATK
base_quality_recalibration() {
    local sample=$1
    local dedup_bam=$2
    local recal_bam="${output_dir}/output/${sample}.sort.dup.bqsr.bam"
    execute_and_time "Base Quality Recalibration" "Performs base quality score recalibration with GATK." "
        ${GATK} BaseRecalibrator \
        -I ${dedup_bam} \
        -R ${REFERENCE_GENOME} \
        --known-sites ${DBSNP} \
        -O ${output_dir}/output/${sample}_recal_data.table && \
        ${GATK} ApplyBQSR \
        -I ${dedup_bam} \
        -R ${REFERENCE_GENOME} \
        --bqsr-recal-file ${output_dir}/output/${sample}_recal_data.table \
        -O ${recal_bam}"
    echo "${recal_bam}"
}


# Function for Variant Calling with GATK HaplotypeCaller
variant_calling() {
    local sample=$1
    local recal_bam=$2
    local gvcf="${output_dir}/output/${sample}.g.vcf.gz"
    execute_and_time "Variant Calling" "Calls variants using GATK HaplotypeCaller." "
        ${GATK} HaplotypeCaller \
        -I ${recal_bam} \
        -R ${REFERENCE_GENOME} \
        -ERC GVCF \
        -O ${gvcf}"
    echo "${gvcf}"
}


# Function to combine GVCFs
combine_gvcfs() {
    local gvcf_list=("$@") # Array of GVCF paths
    local combined_gvcf="${output_dir}/output/cohort.g.vcf.gz"
    local gvcf_args=""
    for gvcf in "${gvcf_list[@]}"; do
        gvcf_args+=" -V $gvcf"
    done

    execute_and_time "Combine GVCFs" "Combines multiple GVCF files into a single GVCF with GATK CombineGVCFs." "
        ${GATK} CombineGVCFs \
        -R ${REFERENCE_GENOME} \
        ${gvcf_args} \
        -O ${combined_gvcf}"
    echo "${combined_gvcf}"
}


# Function to perform genotyping
genotyping() {
    local combined_gvcf=$1
    local vcf_output="${output_dir}/output/cohort.vcf.gz"

    execute_and_time "Genotyping" "Performs genotyping on the combined GVCF file with GATK GenotypeGVCFs." "
        ${GATK} GenotypeGVCFs \
        -R ${REFERENCE_GENOME} \
        -V ${combined_gvcf} \
        -O ${vcf_output}"
    echo "${vcf_output}"
}


# Function for Variant Quality Score Recalibration (VQSR) for SNPs
variant_quality_score_recalibration() {
    local vcf_input=$1
    local recal_vcf="${output_dir}/output/cohort_filtered.vcf.gz"

    execute_and_time "Variant Quality Score Recalibration" "Applies VQSR for SNP filtering using GATK." "
        ${GATK} VariantRecalibrator \
        -V ${vcf_input} \
        # Lakshmi edit: commenting this as we do not have it.
	#--resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${REFERENCE_GENOME}/hapmap_3.3.hg38.vcf.gz \
        #--resource:omni,known=false,training=true,truth=true,prior=12.0 ${REFERENCE_GENOME}/1000G_omni2.5.hg38.vcf.gz \
        --resource:1000G,known=false,training=true,truth=false,prior=10.0 /home/lchanem1/data-abattle4/lakshmi/GRCh37_renamed/ALL.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz \
        --resource:dbsnp,known=true,training=false,truth=false,prior=7.0 ${DBSNP} \
        -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR \
        -mode SNP \
        -O ${output_dir}/output/cohort_snps.recal \
        --tranches-file ${output_dir}/output/cohort_snps.tranches && \
        ${GATK} ApplyVQSR \
        -R ${REFERENCE_GENOME} \
        -V ${vcf_input} \
        --recal-file ${output_dir}/output/cohort_snps.recal \
        --tranches-file ${output_dir}/output/cohort_snps.tranches \
        -mode SNP \
        -O ${recal_vcf}"
    echo "${recal_vcf}"
}


# Function to count variants
count_variants() {
    local vcf_input=$1

    execute_and_time "Count Variants" "Counts the number of variants using GATK." "
        ${GATK} CountVariants \
        -V ${vcf_input}"
}


# Function for additional variant filtering
variant_filtering() {
    local vcf_input=$1
    local filtered_vcf="${output_dir}/output/cohort_filtered_final.vcf.gz"

    execute_and_time "Additional Variant Filtering" "Applies additional variant filters to the VCF file." "
        ${GATK} VariantFiltration \
        -R ${REFERENCE_GENOME} \
        -V ${vcf_input} \
        -O ${filtered_vcf} \
        --filter-name \"DPFilter\" --filter-expression \"DP < 10\""
    echo "${filtered_vcf}"
}


# Function to extract PASS variants
extract_pass_variants() {
    local vcf_input=$1
    local pass_vcf="${output_dir}/output/cohort_final_pass.vcf.gz"

    execute_and_time "Extract PASS Variants" "Extracts variants that passed all filters to create the final VCF file." "
        bcftools view \
        -f PASS \
        ${vcf_input} \
        -Oz -o ${pass_vcf} && \
        tabix -p vcf ${pass_vcf}"
    echo "${pass_vcf}"
}


# Function to convert VCF to TSV for easy viewing
convert_vcf_to_tsv() {
    local vcf_input=$1
    local tsv_output="${output_dir}/output/$(basename "$vcf_input" .vcf.gz)_table.tsv"

    execute_and_time "Convert VCF to TSV" "Converts VCF to TSV format using GATK VariantsToTable for easier data viewing." "
        ${GATK} VariantsToTable \
        -V ${vcf_input} \
        -F CHROM -F POS -F REF -F ALT -F QUAL -GF GT \
        -O ${tsv_output}"
    echo "${tsv_output}"
}


# Function to generate an interactive HTML report
generate_html_report() {
    local sample=$1
    local vcf_input=$2
    local bam_input=$3 # Assuming BAM input is required for the report
    local report_output="${output_dir}/output/${sample}_report.html"

    execute_and_time "Generate HTML Report" "Generates an interactive HTML report for variant visualization." "
        jigv --sample ${sample} \
        --sites ${vcf_input} \
        --fasta ${REFERENCE_GENOME} \
        ${bam_input} > ${report_output}"
    echo "${report_output}"
}

# Function to generate QC reports
generate_qc_reports() {
    local sample=$1
    local fastq1=$2
    local fastq2=$3
    local qc_output_dir="${output_dir}/output/QC_reports/${sample}"

    create_dir_if_not_exists "$qc_output_dir"
    execute_and_time "Generate QC Reports" "Generates QC reports for raw fastq data using FastQC and aggregates them using MultiQC." "
        fastqc -o ${qc_output_dir} ${fastq1} ${fastq2} &&
        multiqc -o ${qc_output_dir} ${qc_output_dir}"
}

# Function to archive and compress results
archive_results() {
    local sample=$1
    local archive_file="${output_dir}/output/${sample}_pipeline_results.tar.gz"

    execute_and_time "Archive and Compress Results" "Archives and compresses the output files for easy storage and transfer." "
        tar -czvf ${archive_file} -C ${output_dir}/output ."
    echo "${archive_file}"
}


# Index the reference genome
index_reference_genome "${REFERENCE_GENOME}"

# Pipeline Execution
for sample_name in "${samples[@]}"; do
    echo "Processing sample: $sample_name"

    # Define paths to input FastQ, CRAM, and BAM files
    fastq_file_1="${FASTQ_DIR}/${sample_name}_R1.fastq.gz"
    fastq_file_2="${FASTQ_DIR}/${sample_name}_R2.fastq.gz"
    cram_file="${CRAM_DIR}/${sample_name}.cram"
    bam_file="${BAM_DIR}/${sample_name}.bam"

    if [[ "$jumpToBam" == true ]]; then

        # Check if BAM file exists
        if [ ! -f "$bam_file" ]; then
            echo "BAM file for sample $sample_name not found. Skipping."
            continue

        fi

        # Skipping directly to the sorting of BAM file
        sorted_bam=$(sort_bam "$sample_name" "$bam_file")

    elif [[ "$jumpToCram" == true ]]; then

        # Check if CRAM file exists
        if [ ! -f "$cram_file" ]; then
            echo "CRAM file for sample $sample_name not found. Skipping."
            continue
        fi

        # Process the CRAM file
        sorted_bam=$(process_cram "$sample_name")

    else

        # Check if FastQ files exist
        if [ ! -f "$fastq_file_1" ] || [ ! -f "$fastq_file_2" ]; then
            echo "Fastq files for sample $sample_name not found. Skipping."
            continue
        fi

        # Align the genome from FastQ files
        bam_output=$(align_genome "$sample_name" "$fastq_file_1" "$fastq_file_2")

        # Sort BAM file
        sorted_bam=$(sort_bam "$sample_name" "$bam_output")

    fi

    # Mark duplicates
    dedup_bam=$(mark_duplicates "$sample_name" "$sorted_bam")

    # Base quality recalibration
    recal_bam=$(base_quality_recalibration "$sample_name" "$dedup_bam")

    # Variant calling
    gvcf=$(variant_calling "$sample_name" "$recal_bam")

    # Variant counts before additional filters
    count_variants "${gvcf}"
done


# Cohort-wide processing
# Find all GVCF files in the output directory
cohort_gvcfs=($(find "${output_dir}/output" -name "*.g.vcf.gz"))

# Check if there are multiple GVCF files for cohort-wide analysis
if [ ${#cohort_gvcfs[@]} -gt 1 ]; then

    # Combine GVCFs
    combined_gvcf=$(combine_gvcfs "${cohort_gvcfs[@]}")

    # Genotyping
    vcf_output=$(genotyping "$combined_gvcf")

    # Variant Quality Score Recalibration (VQSR)
    filtered_vcf=$(variant_quality_score_recalibration "$vcf_output")

    # Variant counts
    count_variants "${filtered_vcf}"

    # Additional Variant filtering
    final_vcf=$(variant_filtering "$filtered_vcf")

    # Extract PASS Variants
    pass_vcf=$(extract_pass_variants "$final_vcf")

    # Convert VCF to TSV for easier viewing
    tsv_output=$(convert_vcf_to_tsv "$pass_vcf")

    # Generate HTML report
    report_output=$(generate_html_report "$sample_name" "$pass_vcf" "$recal_bam")

elif [ ${#cohort_gvcfs[@]} -eq 1 ]; then

    echo "Single GVCF file found. Proceeding with single-sample analysis."
    # Continue with single-sample analysis steps ...

else

    echo "No GVCF files found in the output directory. Skipping cohort-wide steps."

fi


# Generate QC reports and archive results for each sample
for sample_name in "${samples[@]}"; do

    # Define paths to input FastQ files
    fastq_file_1="${FASTQ_DIR}/${sample_name}_R1.fastq.gz"
    fastq_file_2="${FASTQ_DIR}/${sample_name}_R2.fastq.gz"

    # Generate QC reports
    generate_qc_reports "$sample_name" "$fastq_file_1" "$fastq_file_2"
    archive_file=$(archive_results "$sample_name")

done

echo "Pipeline completed for all samples."


