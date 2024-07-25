import os
import gzip

def count_reads_fastq_gz(file_path):
    count = 0
    with gzip.open(file_path, 'rt') as f:  # Open the gzipped fastq file
        for line in f:
            if line.startswith('@'):  # Each read starts with '@'
                count += 1
    return count

# Directory containing the fastq.gz files
directory = '/home/lchanem1/data-abattle4/lakshmi/cuomo_2020/pipeline_files/concat_files'

# Print all files in the directory
print("Fastq.gz files in the directory:")

# Counting just R1 files for now
fastq_files = [file for file in os.listdir(directory) if file.endswith('_R1.fastq.gz')]
for file in fastq_files:
    print(file)

# Iterate through each file in the directory and count the reads
read_counts = {}
for filename in os.listdir(directory):
    if filename.endswith('_R1.fastq.gz'):
        file_path = os.path.join(directory, filename)
        read_counts[filename] = count_reads_fastq_gz(file_path)

# Printing the read counts for each file
for file, count in read_counts.items():
    print(f"{file}: {count} reads")
