zcat /mnt/work/*.pe.qc.fq.gz | \
        normalize-by-median.py -k 20 -C 20 -M 1e8 - -o - | \
        trim-low-abund.py -k 20 -Z 20 -C 3 - -o - -M 1e8 | \
	extract-paired-reads.py --gzip  -p paired.gz -s single.gz
