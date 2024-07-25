#!/usr/bin/env python

# Python script for final correlation computation
import pandas as pd
from os.path import join
from scipy.stats import pearsonr, spearmanr
import matplotlib.pyplot as plt
import sys

# output_dir="/data/abattle4/surya/datasets/for_lakshmi"
# base_output_file="zihe_1"

# ref_file = join("{}".format(output_dir), "{}_ref_filtered.csv".format(base_output_file))
# imputed_file = join("{}".format(output_dir), "{}_gencove_harmonized_subsetted.csv".format(base_output_file))

# Receive file paths as command-line arguments
ref_file = sys.argv[1]
imputed_file = sys.argv[2]
outfile_prefix = sys.argv[3]

print("Reading reference file ...")
ref_genotypes = pd.read_csv(ref_file, sep="\t", header=None, names=["chromosome", "position", "GT"])

print("Reading imputed file ...")
imputed_genotypes = pd.read_csv(imputed_file, sep="\t", header=None, names=["chromosome", "position", "GT"])

print("Merging of reference and imputed file ...")
merged_df = pd.merge(ref_genotypes, imputed_genotypes, on=["chromosome", "position"])

# Assuming bi-allelic variants : convert reference genotype calls of 0/0, 0/1, 1/1 etc 
# into a comparable numeric value. For example:
# 0/0 -> 0;
# 0/1 and 1/0 -> 1;
# 1/1 -> 2

# Rename columns
merged_df.rename(columns={'GT_x': 'GT_ref', 'GT_y': 'GT_imputed'}, inplace=True)

# Function to convert genotype to numeric value
def genotype_to_numeric(genotype):
    if genotype == '0/0':
        return 0
    elif genotype in ['0/1', '1/0']:
        return 1
    elif genotype == '1/1':
        return 2
    else:
        return None  # Handle unexpected values

# Apply the conversion
merged_df['GT_ref_numeric'] = merged_df['GT_ref'].apply(genotype_to_numeric)
merged_df['GT_imputed_numeric'] = merged_df['GT_imputed'].apply(genotype_to_numeric)

# Compute Pearson and Spearman correlations
print("Computing correlation ...")
pearson_corr, _ = pearsonr(merged_df['GT_ref_numeric'], merged_df['GT_imputed_numeric'])
spearman_corr, _ = spearmanr(merged_df['GT_ref_numeric'], merged_df['GT_imputed_numeric'])

print(f"\nPearson Correlation: {pearson_corr:.2f}")
print(f"Spearman Correlation: {spearman_corr:.2f}\n")

# Plotting
print("Plotting correlation plot ...")
plt.figure(figsize=(10, 6))
plt.scatter(merged_df['GT_ref_numeric'], merged_df['GT_imputed_numeric'], alpha=0.6)
plt.xlabel('GT_ref_numeric')
plt.ylabel('GT_imputed_numeric')
plt.title(f'Genotype Comparison\nPearson Correlation: {pearson_corr:.2f}, Spearman Correlation: {spearman_corr:.2f}')
plt.grid(True)

# Save the plot
plt.savefig(outfile_prefix + '_genotype_comparison_plot.pdf')



