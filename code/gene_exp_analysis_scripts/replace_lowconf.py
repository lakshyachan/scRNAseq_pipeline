import pandas as pd
import gzip
import sys

def replace_filter_value_gzip(input_vcf_gz, output_vcf_gz):
    with gzip.open(input_vcf_gz, 'rt') as file, gzip.open(output_vcf_gz, 'wt') as outfile:
        for line in file:
            if line.startswith('#'):
                outfile.write(line)
            else:
                parts = line.strip().split('\t')
                if parts[6] == 'LOWCONF':
                    parts[6] = 'PASS'
                outfile.write('\t'.join(parts) + '\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python replace_lowconf.py input_file output_file")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    replace_filter_value_gzip(input_file, output_file)
