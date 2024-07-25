#!/bin/bash

#Load conda env for bcftools as module does not work
ml anaconda
conda activate sam_bcfenv

#Output is a filtered by PASS vcf of Gencove output of donor
bcftools view -f "PASS" -m2 -M2 --types snps --output-type z --output /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1m_gencove_snps_PASS.vcf.gz /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe_1_murp.vcf.gz

#Extracting the bi-allelic SNPs with score cutoff of 0.15
#Input would be reference genotype from HipSci and output would be created in the genotypes/ directory for filtered reference vcf
bcftools view -m2 -M2 --types snps -i 'GC>0.15' --output-type z --output /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered.vcf.gz /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/HPSI0115i-zihe_1.wec.gtarray.HumanCoreExome-12_v1_0.20160912.genotypes.vcf.gz

#Extract SNP ids and reference allele from reference filtered with BAF >= 0.01
#Input would be ref filtered vcf and output would be a tsv in the genotypes/ directory
bcftools query -f '%ID\t%REF\n'  -i'BAF>=0.01' /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered.vcf.gz > /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered_alleles.tsv

#Load plink older version or new version
ml plink/1.90b6.4 #Older version is poor at handling longer indels and larger files in general
ml plink/2.00a2.3 #New version needs to be called using plink2 instead of just plink

#Make bed files for filtered gencove snps using ref alleles tsv
plink2 --vcf /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1m_gencove_snps_PASS.vcf.gz --ref-allele /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered_alleles.tsv --make-bed --out /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_gencove_HARMONIZED #--memory 3000

#Extract just the snps that match based on SNP IDs and that are common to both
#Input would be the ref alleles tsv and output would be just the RSID column of that tsv into a new tsv in the same directory
cut -f 1 /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered_alleles.tsv > /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_hipsci_reference_RSIDS.tsv

#Extract the matching SNP IDs
plink2 --bed  /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_gencove_HARMONIZED --extract /home/lchanem1/data-abattle4/lakshmi/cuo/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_hipsci_reference_RSIDS.tsv --out /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_gencove_harmonized_subsetted.vcf --recode vcf

#Extract the positions of SNPs from reference with first filter
bcftools query -f '%CHROM\t%POS\n' --output /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered_positions.tsv  /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered.vcf.gz

#QC
#Indexing the gencove SNPs PASS filter output for the next QC step
bcftools index /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1m_gencove_snps_PASS.vcf.gz
bcftools query --regions-file /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered_positions.tsv -i 'BAF>=0.01' -f '%CHROM\tPOS\t%INFO\t%FILTER[\t%DS]\n' /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1m_gencove_snps_PASS.vcf.gz > sanity.check
grep "LOWCONF" sanity.check #should be empty

#Extract dosages from both final vcf files of Gencove and HipSci
bcftools query -f '%CHROM\t%POS[\t%GT]\n' /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered.vcf.gz > /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered.csv
bcftools query -f '%CHROM\t%POS[\t%DS]\n' /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_gencove_harmonized_subsetted.vcf > /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_gencove_harmonized_subsetted.csv

### Python Script from here
#Final correlation would be computed between /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_gencove_harmonized_subsetted.vcf and /home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered.vcf.gz

import pandas as pd
from scipy.stats import pearsonr

#Ref_genotypes are the "Reference GT", imputed_dosages are from "Gencove dosages"
ref_genotypes = pd.read_csv("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/genotypes/zihe1_ref_filtered.csv", sep="\t", header=None, names=["chromosome", "position", "GT"])
imputed_dosages = pd.read_csv("/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/zihe_1_murp_cat/zihe1_gencove_harmonized_subsetted.csv", sep="\t", header=None, names=["chromosome", "position", "dosage"])
merged = pd.merge(ref_genotypes, imputed_dosages, on=["chromosome", "position"])

# Assuming all are bi-allelic variants, we need to convert reference genotype calls of 0/0, 0/1, 1/1 etc into a comparable numeric value. For this, we quantify it as follows:
# 0/0 -> 0;
# 0/1 and 1/0 -> 1;
# 1/1 -> 2

#Assign the above values to the GT column
dosages = merged["GT"].str.count('1|2')
r, p = pearsonr(dosages, merged["dosage"])
print("Pearson correlation: ", r)
print("p-value: ", p)