Goal: Run protocols through digi (1 and 2 of protocols) with finally
working code - fixed loop error in interleave-reads.py portion
and added orphaned reads.

Next: prepare for streaming into trimmomatic

Code: 

resource allocation:

sudo chmod a+rwxt /mnt
sudo apt-get -y install git-core

cd /home/ubuntu
rm -fr literate-resting khmer-protocols
git clone https://github.com/dib-lab/literate-resting.git
git clone https://github.com/dib-lab/khmer-protocols.git -b jem-streaming

cd khmer-protocols/mrnaseq

## vim 1-quality.rst # change version number on line 49 to match the release to test

for i in [1-2]-*.rst
do
   /home/ubuntu/literate-resting/scan.py $i || break
done

### START MONITORING (in another SSH session)


for i in [1-2]-*.rst.sh
do
   bash $i |& tee ${i%%.rst.sh}.out || break
done


## SAR monitoring commands ##

# to run
   sudo apt-get install sysstat -y
   sar -u -r -d -o times.dat 1

# to extract

 sar -d -p -f times.dat > disk.txt
   sar -u -f times.dat > cpu.txt
   sar -r -f times.dat > ram.txt
   gzip *.txt


############ Github code - trimmomatic onwards

rm -f orphans.fq.gz

for filename in *_R1_*.fastq.gz
do
     # first, make the base by removing fastq.gz
     base=$(basename $filename .fastq.gz)
     echo $base

     # now, construct the R2 filename by replacing R1 with R2
     baseR2=${base/_R1_/_R2_}
     echo $baseR2

     # finally, run Trimmomatic
     TrimmomaticPE ${base}.fastq.gz ${baseR2}.fastq.gz \
        ${base}.qc.fq.gz s1_se \
        ${baseR2}.qc.fq.gz s2_se \
        ILLUMINACLIP:TruSeq3-PE.fa:2:40:15 \
        LEADING:2 TRAILING:2 \
        SLIDINGWINDOW:4:2 \
        MINLEN:25

     # save the orphans
     gzip -9c s1_se s2_se >> orphans.fq.gz
     rm -f s1_se s2_se
done

(for filename in *_R1_*.qc.fq.gz
do
   base=$(basename $filename .qc.fq.gz)
   baseR2=${base/_R1_/_R2_}
   output=${base/_R1_/}.pe.qc.fq.gz

   interleave-reads.py ${base}.qc.fq.gz ${baseR2}.qc.fq.gz

done && zcat orphans.fq.gz) | \

   trim-low-abund.py -V -k 20 -Z 20 -C 3 - -o - -M 4e9 --diginorm | \
   extract-paired-reads.py --gzip  -p paired.gz -s single.gz
