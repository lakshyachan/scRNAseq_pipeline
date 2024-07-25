#!/bin/bash

cd data
cd cram_ftps/
for i in `find . -type f`; do md5sum $i >> cram_md5s.txt; done
cut -d ' ' -f 1 downloaded_cram_md5.txt
rm cram_md5s.txt
diff downloaded_cram_md5.txt all_crams_md5.txt
