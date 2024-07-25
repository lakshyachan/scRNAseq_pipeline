import gzip

def count_reads_fastq_gz(file_path):
    count = 0
    with gzip.open(file_path, 'rt') as f:
        for line in f:
            if line.startswith('@'):  # Each read starts with '@'
                count += 1
    return count

file_path = 'uilk_3_R1.fastq.gz'
read_count = count_reads_fastq_gz(file_path)
print(f"Number of reads: {read_count}")

