# scRNAseq_pipeline
Code for benchmarking single cell RNAseq variant callers and imputation tools. Includes custom end-to-end pipeline implementing GATK best practices (https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels) for germline variant calling and built-in Beagle and Glimpse imputation methods. 

Research part of my master's thesis at Johns Hopkins BME, under Dr Alexis Battle and collaborated with Ashton Omdahl and Surya Chhetri. 

# Overall project goal

To leverage publicly available scRNA-seq datasets without associated genotypes for eQTL calling purpose. Traditionally, eQTL calling requires ground truth genotypes per sample along with transcriptome. Our motivation is to circumvent this need by imputing genotypes from RNA-seq reliably and of sufficient quality for eQTL calling. 

This project evaluates typical bulk RNA-seq variant callers on single cell, in terms of Pearson and Spearman correlations between known genotypes and imputed genotypes, and over several metrics-such as coding vs non coding regions, intergeneic regions, and high/low expressed gene regions and varying depths. 

Codes used for evaluating metrics and generating figures also included.

# Contents
1. [Automated Correlation Scripts](code/gencove_correlation_scripts/README)
