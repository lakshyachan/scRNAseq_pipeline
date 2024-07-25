import gzip
import sys
import os
import pandas as pd
import matplotlib.pyplot as plt

def extract_gp(donor_id):
    if not donor_id:
        print("Please provide sample name. Usage: extract_gp('zihe_1')")
        return
    
    path = "/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/gene_exp_analysis/"    
    bin_spec = {"_10kbp_w": "10_kbp_within", "_20kbp_w": "10_20_kbp_within", "_30kbp_w": "20_30_kbp_within", "_40kbp_w": "30_40_kbp_within", "_50kbp_w": "40_50_kbp_within", "_50_100kbp_w": "50_100_kbp_within", "_100_200kbp_w": "100_200_kbp_within", "_200_300kbp_w": "200_300_kbp_within", "_300_400kbp_w": "300_400_kbp_within", "_400_500kbp_w": "400_500_kbp_within"}

    max_gp_values = []
    bin_labels = []
    for bin_dist, bin_folder in bin_spec.items():
        file_name = os.path.join(path, bin_folder, donor_id + bin_dist + ".recode.vcf.gz")
        max_gp_values_bin = []

        with gzip.open(file_name, 'rt') as f:
            for line in f:
                if line.startswith("#"):
                    continue
                parts = line.strip().split('\t')
                gp_field = parts[9].split(":")[2]
                max_gp = max(float(val) for val in gp_field.split(',')[0:3])
                max_gp_values_bin.append(max_gp)

        max_gp_values.append(max_gp_values_bin)
        bin_labels.append(bin_dist)
    
    print("Finished appending GP values for donor")
    
    # Visualization
    plt.figure(figsize=(10, 6))
    plt.violinplot(max_gp_values, showmeans=True)

    plt.xlabel('Binned Distance')
    plt.ylabel('Max GP Value')
    plt.title('Distribution of Max GP Values Across Binned Distances')
    plt.xticks(range(1, len(bin_spec) + 1), bin_labels, rotation=45)
    plt.ylim(0.95,1.01)
    plt.grid(True)
    plt.tight_layout()
    fig_name = os.path.join(donor_id + ".png")
    plt.savefig(fig_name)
    print("Saved figure for donor")
    
extract_gp('zihe_1')
extract_gp('eipl_1')
extract_gp('joxm_1')
