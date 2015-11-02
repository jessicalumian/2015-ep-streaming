10-10-15
Problem with code - interleave-reads.py needs to be inside the loop because the base changes with each iteration

# same code at 10-08-15, but all copy pasted here in case of 
# problem with .rst

sudo chmod a+rwxt /mnt
sudo apt-get -y install git-core

cd /home/ubuntu
rm -fr literate-resting khmer-protocols
git clone https://github.com/dib-lab/literate-resting.git
git clone https://github.com/dib-lab/khmer-protocols.git -b jem-streaming

cd khmer-protocols/mrnaseq

## vim 1-quality.rst # change version number on line 49 to match the release to test

for i in [1]-*.rst
do
   /home/ubuntu/literate-resting/scan.py $i || break
done

### START MONITORING (in another SSH session)


for i in [1]-*.rst.sh
do
   bash $i |& tee ${i%%.rst.sh}.out || break
done

for filename in *_R1_*.qc.fq.gz
do
     # first, make the base by removing .extract.fastq.gz
     (base=$(basename $filename .qc.fq.gz)

     # now, construct the R2 filename by replacing R1 with R2
     baseR2=${base/_R1_/_R2_}

     # construct the output filename
     output=${base/_R1_/}.pe.qc.fq.gz)

done | \

     interleave-reads.py ${base}.qc.fq.gz ${baseR2}.qc.fq.gz | \
     normalize-by-median.py -k 20 -C 20 -M 4e9 - -o - | \
     trim-low-abund.py -V -k 20 -Z 20 -C 3 - -o - -M 4e9 | \
     extract-paired-reads.py --gzip  -p paired.gz -s single.gz


## SAR monitoring commands ##

# to run
   sudo apt-get install sysstat -y
   sar -u -r -d -o times.dat 1

# to extract

 sar -d -p -f times.dat > disk.txt
   sar -u -f times.dat > cpu.txt
   sar -r -f times.dat > ram.txt
   gzip *.txt
